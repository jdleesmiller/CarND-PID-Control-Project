# CarND-Controls-PID
Self-Driving Car Engineer Nanodegree Program

---

## Implementation

The PID implementation is as described in lecture, but I added two extensions.

### Steering Smoothing

If the output of the PID controller is applied directly to the steering angle, the car can instantaneously sweep through a 50 degree steering angle, which does not seem very realistic.

There should be a maximum rate of change in the steering angle. Based on [this paper](https://www.nhtsa.gov/DOT/NHTSA/NRD/Multimedia/PDFs/VRTC/ca/capubs/NHTSA_forkenbrock_driversteeringcapabilityrpt.pdf) steering wheel controllers can typically steer at about 1000 steering wheel degrees / second. According to [wikipedia]( https://en.wikipedia.org/wiki/Steering_ratio), the steering ratio is not usually larger than 12:1 (360 wheel degrees : 30 steering degrees). This gives a peak rate of change of ~33 degrees per second. The simulator timestep is roughly 0.05s, so we should not be changing the steering angle by no more than about 1.67 degrees per timestep. In control units, with 25 degrees per control unit, that is 0.0667.

Without this smoothing on the steering angle, the tuning algorithm described below found that it could actually go pretty fast with full throttle and very high P gain, which caused the car to "shimmy" along the centerline by switching the control output between -1 and 1 in each control timestep. The mechanical engineers would not be pleased.

### Throttle Control

After initially tuning with a fixed throttle, I added a throttle controller. The idea is that when we start turning, we should slow down, and when we are returning to a zero steering angle, we should speed up. That is, you should brake when entering a turn and then accelerate out of the turn.

The problem is that controller has no idea whether it's about to turn or not, because it's not localizing the vehicle on the map. It can, however, tell whether the car is turning more than it has been recently. It keeps an exponential moving average of the steering angle, and if the absolute steering angle in the current timestep, which comes from the PID controller, is sufficiently greater than the absolute moving average steering angle, then it brakes. Otherwise, it accelerates.

For example, if we'd turned 0.3 degrees per timestep on average over the last 0.5 seconds, and this timestep we turned 0.6 degrees, we seem to be turning more steeply than we were before, so we may be entering a turn, and we should brake. When we start to straighten out again, the moving average will be larger than the turning angle, and we accelerate.

This gives four additional tunable parameters:

1. The maximum acceleration throttle
1. The minimum acceleration (that is, maximum braking) throttle
1. The time constant for the exponential moving average
1. The absolute steering angle threshold beyond which to brake

For tuning, I fixed the maximum acceleration throttle at 0.6 and the minimum acceleration throttle at -0.6 and then tuned the time constant and threshold simultaneously with the steering controller PID gains, so there were only two parameters actually tuned.

## Reflection

### Describe how the final hyperparameters were chosen

I tried two tuning algorithms. The overall framework was:

- Run the simulator with a fixed set of parameters.
- Stop if the vehicle crashes (as measured by speed dropping below 5mph or cross track error exceeding 4.5 (I am still not entirely sure of the units)), or if a fixed time elapses, typically 60s-120s.
- Measure the distance travelled, which we'd like to be large, and the integral of absolute cross track error, which we'd like to be small.
- When the run finishes, send the simulator a `reset` command and start again with a new set of parameters.

The two algorithms were twiddle and the cross entropy method.

#### Twiddle

As in the lecture. It worked pretty well when there were only three parameters, but when I added the throttle parameters, it started to take a long time, and it often got stuck in local minima. It also did not seem to cope very well with randomness in the objective function: it would 'get lucky' on one run with a very large distance score, and then it would never be able to beat it, so the deltas would gradually decrease, even if the solution was not very good on average.

The randomness in the objective function is probably due in large part to my computer being quite slow: the simulator sometimes freezes for a few timesteps, and then the controller has to compensate for a large error. If it freezes at the wrong time, the car can easily crash.

#### The Cross Entropy Method

The [Cross Entropy Method](https://en.wikipedia.org/wiki/Cross-entropy_method). The CEM is similar in spirit to a genetic algorithm, but instead of working with 'genes', it works with a probability distribution over the parameters. You start with a prior distribution, and then CEM

1. generates samples based on that distribution,
1. scores them according to the objective function, and
1. uses the lowest-scoring samples (if we want to minimize the objective function, in this case negative distance) to update the parameters of the probability distribution.

This process repeats for each 'generation'. It is relatively resistant to randomness in the objective function, because it averages over a (configurable) number of samples in each generation. I used an implementation of the CEM that I wrote a few years ago: https://github.com/jdleesmiller/cross_entropy

The CEM seemed to be more resistant to getting stuck in local minima than Twiddle, but it did take a lot of objective function evaluations. My final tuning run, `tune_staged_cem_16.csv`, ran 2476 simulations over almost 46h.

It also exhibited some "risk seeking" behavior: if a set of parameters often resulted in fast laps (that is, long distances) but sometimes crashed spectacularly, that set of parameters would often make it into the 'elite' samples that seeded the next generation. It therefore tended to select for dangerous driving.

To counteract this, I averaged four separate simulation runs for each score evaluation to obtain a better estimate of the expected objective function. This was much more (four times more) expensive, but it did seem to help penalize risky parameters.

The final tuning run went through six generations (100 samples per generation, best 10 selected as elite samples, 4 simulation runs per sample). I used independent 1D Gaussians for the parameter sampling distribution. The first three numbers are the logarithms of the `kp`, `ki`, and `kd` constants, respectively, to ensure that we picked positive gains. The average steering angle time constant and threshold are obtained by running the latter two numbers through a sigmoid function to get them into (0, 1). Minimum and maximum throttle were fixed at -0.6 and 0.6, respectively. The initial (prior) gain parameter means were obtained from a previous CEM run (the code is ruby):

```ruby
ks = NMath.log(NArray[0.09, 0.002, 0.04])
ks_stddev = NArray[0.2, 0.2, 0.2]
initial_params = NArray[*(ks.to_a + [-2, -2])]
initial_stddev = NArray[*(ks_stddev.to_a + [0.5, 0.5])]
```

The parameter means (first row) and standard deviations (second row) for each of the six generations were as follows.

```
NArray.float(5):
[ -2.35271, -6.17514, -3.24699, -1.85503, -2.52219 ]
NArray.float(5):
[ 0.109397, 0.130636, 0.16729, 0.40633, 0.38891 ]

NArray.float(5):
[ -2.47032, -6.14921, -3.14663, -2.03556, -2.38271 ]
NArray.float(5):
[ 0.0775456, 0.160393, 0.0440492, 0.360371, 0.24856 ]

NArray.float(5):
[ -2.48072, -6.15422, -3.13396, -2.04168, -2.35476 ]
NArray.float(5):
[ 0.0837192, 0.129711, 0.0519652, 0.390124, 0.210871 ]

NArray.float(5):
[ -2.48303, -6.11234, -3.14672, -2.03684, -2.38635 ]
NArray.float(5):
[ 0.0636831, 0.148444, 0.0667207, 0.270623, 0.103646 ]

NArray.float(5):
[ -2.48532, -6.14573, -3.12615, -1.96976, -2.30282 ]
NArray.float(5):
[ 0.052023, 0.143876, 0.0575963, 0.264053, 0.102164 ]

NArray.float(5):
[ -2.49606, -6.14381, -3.12716, -2.14232, -2.33621 ]
NArray.float(5):
[ 0.0535792, 0.189626, 0.0360106, 0.212486, 0.126516 ]
```

Overall, the standard deviations decreased, indicating convergence, but interestingly they remained quite high for the `ki` coefficient (second number) and the mean steering angle time constant (fourth number), indicating that the objective (negative distance travelled) was not very sensitive to changes in these parameters. With further generations, the variances may nevertheless have decreased, but I am already late handing this in.

For submission, I used the `tune.R` script to pick the parameters with the lowest absolute cross track error of all of the parameters tested during the last generation of the CEM run, even though that was not what we were optimizing, because we just want to get around the track. These are the 'timid' parameters. I also included a set of 'aggressive' parameters that seem to work well, for reference, but they are commented out. The top results (in the last generation) by both criteria were:

```
> head(dOK[order(dOK$total_absolute_cte),]) # "timid"
    sample         kp          ki         kd min_throttle max_throttle
54     505 0.09246630 0.002171082 0.04401599         -0.6          0.6
76     544 0.08933176 0.001965898 0.04393657         -0.6          0.6
25     510 0.08131531 0.002600238 0.05222758         -0.6          0.6
116    547 0.09152920 0.002148535 0.04935019         -0.6          0.6
181    565 0.08996727 0.002037377 0.04472419         -0.6          0.6
168    538 0.09236225 0.001952292 0.04239050         -0.6          0.6
    mean_steer_delay throttle_steer_threshold crashed distance
54         0.1289787               0.06207176       0 1880.010
76         0.1895262               0.06517804       0 1804.503
25         0.1801097               0.05428013       0 1666.625
116        0.1222209               0.07132404       0 1954.375
181        0.1390824               0.07819560       0 2028.765
168        0.1390268               0.07761368       0 2018.675
    total_absolute_cte
54            64.94090
76            66.64975
25            67.92565
116           72.62713
181           73.71360
168           73.94333

> head(dOK[order(-dOK$distance),]) # "aggressive"
    sample         kp          ki         kd min_throttle max_throttle
365    579 0.07936167 0.002124203 0.04551714         -0.6          0.6
185    540 0.07795582 0.002041901 0.04254738         -0.6          0.6
246    599 0.07864267 0.001577405 0.04273478         -0.6          0.6
444    594 0.08341730 0.002869982 0.04197861         -0.6          0.6
394    513 0.08914621 0.002095229 0.04618493         -0.6          0.6
345    533 0.08575644 0.002544331 0.04152967         -0.6          0.6
    mean_steer_delay throttle_steer_threshold crashed distance
365       0.11048628               0.09574146       0 2290.510
185       0.08874864               0.07867998       0 2268.062
246       0.09872981               0.08389212       0 2265.740
444       0.14918138               0.10636313       0 2250.150
394       0.11755371               0.09923922       0 2244.012
345       0.11461219               0.09360496       0 2243.812
    total_absolute_cte
365           82.00758
185           81.27893
246           83.19930
444           80.31198
394           82.12273
345           80.51510
```

### Describe the effect each of the P, I, D components had in your implementation

- P: Steer in this proportion (with opposite sign) to the latest cross track error measurement.

- I: Steer in this proportion (with opposite sign) to the integral of all historical cross track error measurements. This corrects for systematic bias in the steering. The tuning algorithm consistently chose small values for the I coefficient, indicating that the simulated vehicle has relatively little bias to correct for.

- D: Steer in this proportion (with opposite sign) to the derivative of the cross track error measurement, as estimated using a first order backward difference between the latest cross track error measurement and the previous one. This avoids overshooting by straightening the car out as it approaches zero cross track error.

It is interesting to compare the timid and aggressive parameters from above:

- The timid parameters have higher P gain (~0.09), leading to tighter tracking but also more steering and therefore lower speed. They also have lower `throttle_steer_threshold`s, which means that they brake earlier in turns (and on less steep turns).

- The aggressive parameters have lower P gain (~0.08), leading to looser tracking but also less steering and generally higher speeds. They also have higher `throttle_steer_threshold`, which means that they brake less.

## Dependencies

* cmake >= 3.5
 * All OSes: [click here for installation instructions](https://cmake.org/install/)
* make >= 4.1
  * Linux: make is installed by default on most Linux distros
  * Mac: [install Xcode command line tools to get make](https://developer.apple.com/xcode/features/)
  * Windows: [Click here for installation instructions](http://gnuwin32.sourceforge.net/packages/make.htm)
* gcc/g++ >= 5.4
  * Linux: gcc / g++ is installed by default on most Linux distros
  * Mac: same deal as make - [install Xcode command line tools]((https://developer.apple.com/xcode/features/)
  * Windows: recommend using [MinGW](http://www.mingw.org/)
* [uWebSockets](https://github.com/uWebSockets/uWebSockets) == 0.13, but the master branch will probably work just fine
  * Follow the instructions in the [uWebSockets README](https://github.com/uWebSockets/uWebSockets/blob/master/README.md) to get setup for your platform. You can download the zip of the appropriate version from the [releases page](https://github.com/uWebSockets/uWebSockets/releases). Here's a link to the [v0.13 zip](https://github.com/uWebSockets/uWebSockets/archive/v0.13.0.zip).
  * If you run OSX and have homebrew installed you can just run the ./install-mac.sh script to install this
* Simulator. You can download these from the [project intro page](https://github.com/udacity/CarND-PID-Control-Project/releases) in the classroom.

## Basic Build Instructions

1. Clone this repo.
2. Make a build directory: `mkdir build && cd build`
3. Compile: `cmake .. && make`
4. Run it: `./pid`.

## Editor Settings

We've purposefully kept editor configuration files out of this repo in order to
keep it as simple and environment agnostic as possible. However, we recommend
using the following settings:

* indent using spaces
* set tab width to 2 spaces (keeps the matrices in source code aligned)

## Code Style

Please (do your best to) stick to [Google's C++ style guide](https://google.github.io/styleguide/cppguide.html).

## Project Instructions and Rubric

Note: regardless of the changes you make, your project must be buildable using
cmake and make!

More information is only accessible by people who are already enrolled in Term 2
of CarND. If you are enrolled, see [the project page](https://classroom.udacity.com/nanodegrees/nd013/parts/40f38239-66b6-46ec-ae68-03afd8a601c8/modules/f1820894-8322-4bb3-81aa-b26b3c6dcbaf/lessons/e8235395-22dd-4b87-88e0-d108c5e5bbf4/concepts/6a4d8d42-6a04-4aa6-b284-1697c0fd6562)
for instructions and the project rubric.

## Hints!

* You don't have to follow this directory structure, but if you do, your work
  will span all of the .cpp files here. Keep an eye out for TODOs.

## Call for IDE Profiles Pull Requests

Help your fellow students!

We decided to create Makefiles with cmake to keep this project as platform
agnostic as possible. Similarly, we omitted IDE profiles in order to we ensure
that students don't feel pressured to use one IDE or another.

However! I'd love to help people get up and running with their IDEs of choice.
If you've created a profile for an IDE that you think other students would
appreciate, we'd love to have you add the requisite profile files and
instructions to ide_profiles/. For example if you wanted to add a VS Code
profile, you'd add:

* /ide_profiles/vscode/.vscode
* /ide_profiles/vscode/README.md

The README should explain what the profile does, how to take advantage of it,
and how to install it.

Frankly, I've never been involved in a project with multiple IDE profiles
before. I believe the best way to handle this would be to keep them out of the
repo root to avoid clutter. My expectation is that most profiles will include
instructions to copy files to a new location to get picked up by the IDE, but
that's just a guess.

One last note here: regardless of the IDE used, every submitted project must
still be compilable with cmake and make./
