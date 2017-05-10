# CarND-Controls-PID
Self-Driving Car Engineer Nanodegree Program

---

## NOTES

- To get dt, does not seem to be in message but can use a monotonic clock.

- `data/tune_grid_60s_1.csv`: first grid; run for 30s; measured average speed and i_error, but i_error is not very informative, and average speed as measured was an exponential moving average so only considered speed at the end

- CEM:

best I've seen:
0.07900659638247182,0.02423707195142647,0.03316989870883789,false,120.024,1713.4,2015.18

throttle 0.3 (tune_cem_120s_2.csv):
NArray.float(3):
[ -1.91955, -2.06475, -0.442202 ]
NArray.float(3):
[ 2.0181, 1.97754, 0.76513 ]
NArray.float(3):
[ -2.28419, -2.8472, -1.53843 ]
NArray.float(3):
[ 0.801199, 0.962971, 0.16103 ]
NArray.float(3):
[ -2.66262, -2.73212, -1.78096 ]
NArray.float(3):
[ 0.634971, 0.807285, 0.0853592 ]
NArray.float(3):
[ -2.99307, -2.57763, -1.90488 ]
NArray.float(3):
[ 0.430431, 0.286394, 0.0620535 ]
NArray.float(3):
[ -3.46039, -2.7463, -1.94329 ]
NArray.float(3):
[ 0.420683, 0.274237, 0.0431037 ]
NArray.float(3):
[ -3.59167, -2.76433, -1.99097 ]
NArray.float(3):
[ 0.238477, 0.147028, 0.0100475 ]
NArray.float(3):
[ -3.74762, -2.76786, -1.99717 ]
NArray.float(3):
[ 0.138708, 0.0306208, 0.0106798 ]

throttle variable (tune_cem_100s_3.csv):
NArray.float(4):
[ -1.36579, -1.46741, 0.598061, 0.477702 ]
NArray.float(4):
[ 2.09073, 1.6011, 2.06196, 0.871262 ]
NArray.float(4):
[ -2.05455, -2.02612, -0.461838, 0.393801 ]
NArray.float(4):
[ 1.29906, 1.18918, 0.952388, 0.388758 ]
NArray.float(4):
[ -2.38202, -1.68539, -1.51939, 0.301323 ]
NArray.float(4):
[ 0.828505, 0.64684, 0.447218, 0.297995 ]
NArray.float(4):
[ -2.36083, -1.54442, -1.72562, 0.648241 ]
NArray.float(4):
[ 0.403199, 0.238242, 0.357555, 0.208694 ]
NArray.float(4):
[ -2.72255, -1.7553, -1.85485, 0.805717 ]
NArray.float(4):
[ 0.421478, 0.191416, 0.289546, 0.236319 ]
NArray.float(4):
[ -3.12406, -1.74314, -2.24427, 0.808426 ]
NArray.float(4):
[ 0.354344, 0.133994, 0.249618, 0.173558 ]
NArray.float(4):
[ -3.12193, -1.76121, -2.38471, 1.02913 ]
NArray.float(4):
[ 0.279362, 0.17295, 0.10651, 0.0795897 ]
NArray.float(4):
[ -3.06833, -1.84497, -2.44307, 1.15038 ]
NArray.float(4):
[ 0.222798, 0.108335, 0.112303, 0.0629306 ]
NArray.float(4):
[ -3.156, -1.89518, -2.54315, 1.22856 ]
NArray.float(4):
[ 0.119162, 0.0680847, 0.0123835, 0.0438266 ]
NArray.float(4):
[ -3.18513, -1.84011, -2.54418, 1.2956 ]
NArray.float(4):
[ 0.0990855, 0.0448953, 0.0160553, 0.0176234 ]
NArray.float(4):
[ -3.21664, -1.84487, -2.55177, 1.31848 ]
NArray.float(4):
[ 0.0412811, 0.0558589, 0.0164166, 0.00587072 ]
NArray.float(4):
[ -3.21874, -1.8474, -2.56601, 1.32362 ]
NArray.float(4):
[ 0.0282526, 0.0265305, 0.0156761, 0.00681051 ]
NArray.float(4):
[ -3.24035, -1.87156, -2.5721, 1.32927 ]
NArray.float(4):
[ 0.0289707, 0.0260128, 0.0162352, 0.00624611 ]
NArray.float(4):
[ -3.2404, -1.8786, -2.57892, 1.3357 ]
NArray.float(4):
[ 0.0214111, 0.031139, 0.0152841, 0.00546524 ]
NArray.float(4):
[ -3.23482, -1.87968, -2.58896, 1.34093 ]
NArray.float(4):
[ 0.0191606, 0.0344678, 0.0102654, 0.0032314 ]

throttle variable (tune_cem_100s_4.csv):
changed the objective to include some weight on integrated absolute CTE
quite a lot of crashing even in the final stages
NArray.float(4):
[ -1.35491, -2.77766, -0.0885864, -0.0470385 ]
NArray.float(4):
[ 1.25431, 1.61552, 0.765034, 0.40164 ]
NArray.float(4):
[ -1.74475, -1.76989, -1.12646, 0.120486 ]
NArray.float(4):
[ 0.847916, 0.693549, 0.472276, 0.392671 ]
NArray.float(4):
[ -2.35833, -1.47633, -1.81976, 0.33095 ]
NArray.float(4):
[ 0.616919, 0.318808, 0.0829921, 0.198973 ]
NArray.float(4):
[ -2.58483, -1.72652, -1.81904, 0.5343 ]
NArray.float(4):
[ 0.567779, 0.300152, 0.0743068, 0.0807303 ]
NArray.float(4):
[ -2.59992, -1.85785, -1.88996, 0.657738 ]
NArray.float(4):
[ 0.328542, 0.19303, 0.0346423, 0.0562103 ]
NArray.float(4):
[ -2.6385, -1.86736, -1.91491, 0.724923 ]
NArray.float(4):
[ 0.256431, 0.096398, 0.0242208, 0.00820931 ]
NArray.float(4):
[ -2.75731, -1.87329, -1.93635, 0.732893 ]
NArray.float(4):
[ 0.235187, 0.112629, 0.00567658, 0.00839164 ]
NArray.float(4):
[ -2.773, -1.87016, -1.93341, 0.735248 ]
NArray.float(4):
[ 0.236014, 0.0715998, 0.00513092, 0.0058176 ]
NArray.float(4):
[ -2.8286, -1.8592, -1.93337, 0.738508 ]
NArray.float(4):
[ 0.289381, 0.0429836, 0.00354126, 0.0051396 ]
NArray.float(4):
[ -2.83693, -1.80866, -1.93405, 0.740048 ]
NArray.float(4):
[ 0.208281, 0.00761719, 0.00316737, 0.00434303 ]
NArray.float(4):
[ -2.78682, -1.80614, -1.93383, 0.742224 ]
NArray.float(4):
[ 0.186485, 0.00961114, 0.00239782, 0.00568537 ]
NArray.float(4):
[ -2.83414, -1.80182, -1.9351, 0.743527 ]
NArray.float(4):
[ 0.201168, 0.00773727, 0.00215003, 0.00634866 ]
NArray.float(4):
[ -2.87355, -1.80401, -1.93655, 0.746134 ]
NArray.float(4):
[ 0.274271, 0.010361, 0.00290906, 0.00617921 ]
NArray.float(4):
[ -2.87197, -1.8092, -1.93843, 0.747303 ]
NArray.float(4):
[ 0.122261, 0.00894389, 0.00264586, 0.00607892 ]
NArray.float(4):
[ -2.8205, -1.80441, -1.93995, 0.752923 ]
NArray.float(4):
[ 0.068183, 0.00443207, 0.00266507, 0.0080482 ]
NArray.float(4):
[ -2.82952, -1.80323, -1.94023, 0.755395 ]
NArray.float(4):
[ 0.0595202, 0.00458676, 0.00205168, 0.00206674 ]

tune_cem_100s_5.csv: rerun, but it crashed
NArray.float(4):
[ -2.04894, -2.41257, -0.733017, -0.0926693 ]
NArray.float(4):
[ 1.2195, 1.22063, 0.753667, 0.376634 ]
NArray.float(4):
[ -1.88113, -2.64969, -1.16865, 0.18802 ]
NArray.float(4):
[ 0.887493, 1.4712, 0.618159, 0.311586 ]
NArray.float(4):
[ -2.06539, -3.14863, -1.75631, 0.353967 ]
NArray.float(4):
[ 0.901938, 1.6218, 0.592967, 0.178268 ]
NArray.float(4):
[ -2.20646, -3.56662, -2.48805, 0.367376 ]
NArray.float(4):
[ 0.498403, 1.05766, 0.190698, 0.135625 ]
NArray.float(4):
[ -2.36798, -2.77557, -2.59355, 0.52947 ]
NArray.float(4):
[ 0.170949, 0.523367, 0.140383, 0.0501684 ]
NArray.float(4):
[ -2.48081, -3.07526, -2.74084, 0.611537 ]
NArray.float(4):
[ 0.183879, 0.490794, 0.125253, 0.0317819 ]

tune_cem_100s_6.csv: rerun, but interestingly it seems to have got stuck in a local minimum with high gains and high throttle. The car sort of 'shimmies' its way along, achieving roughly 50mph.
NArray.float(4):
[ -1.73086, -0.563114, 0.154994, 0.41623 ]
NArray.float(4):
[ 1.82768, 2.00702, 0.987322, 0.603177 ]
NArray.float(4):
[ -0.43908, -1.41144, 0.162773, 0.534288 ]
NArray.float(4):
[ 0.857753, 1.6973, 0.347621, 0.197122 ]
NArray.float(4):
[ -1.45478, -1.16037, 0.0538369, 0.75175 ]
NArray.float(4):
[ 0.685805, 1.73456, 0.2, 0.138187 ]
NArray.float(4):
[ -1.18427, -1.80763, -0.178826, 0.810452 ]
NArray.float(4):
[ 0.429563, 1.63765, 0.145625, 0.120263 ]
NArray.float(4):
[ -1.04469, -0.759902, -0.181851, 0.783435 ]
NArray.float(4):
[ 0.507183, 1.01826, 0.129323, 0.146684 ]
NArray.float(4):
[ -0.938325, -0.779098, -0.209533, 0.861876 ]
NArray.float(4):
[ 0.241385, 0.30214, 0.16991, 0.147018 ]
NArray.float(4):
[ -1.07575, -0.785861, -0.435923, 0.921982 ]
NArray.float(4):
[ 0.244579, 0.464159, 0.247063, 0.127044 ]

tune_cem_60s_7.csv: Increased the number of samples to 120 per generation (and selected 12 elites) but decreased the max runtime to 60s. Again it crashed quite a lot even in the later stages. Seems to be risk seeking.
NArray.float(4):
[ -2.19533, -1.521, -0.767498, 0.917996 ]
NArray.float(4):
[ 0.740336, 1.22953, 1.03322, 0.8485 ]
NArray.float(4):
[ -2.32322, -1.14896, -1.20475, 0.986126 ]
NArray.float(4):
[ 0.559587, 0.41163, 0.592932, 0.571315 ]
NArray.float(4):
[ -2.32927, -1.22089, -1.31281, 1.13454 ]
NArray.float(4):
[ 0.643348, 0.281953, 0.41437, 0.349667 ]
NArray.float(4):
[ -2.36421, -1.30433, -1.51886, 1.15023 ]
NArray.float(4):
[ 0.332124, 0.231685, 0.214279, 0.250995 ]
NArray.float(4):
[ -2.52153, -1.22535, -1.70581, 1.24357 ]
NArray.float(4):
[ 0.336949, 0.180477, 0.166385, 0.203653 ]
NArray.float(4):
[ -2.49778, -1.30686, -1.83711, 1.31158 ]
NArray.float(4):
[ 0.32875, 0.130766, 0.109975, 0.125241 ]
NArray.float(4):
[ -2.81619, -1.40392, -1.87155, 1.44306 ]
NArray.float(4):
[ 0.133239, 0.143823, 0.092655, 0.108215 ]
NArray.float(4):
[ -2.79524, -1.39263, -1.89521, 1.54222 ]
NArray.float(4):
[ 0.107884, 0.108686, 0.0624016, 0.0489188 ]
NArray.float(4):
[ -2.83078, -1.3989, -1.91975, 1.58383 ]
NArray.float(4):
[ 0.0834371, 0.0946652, 0.0616019, 0.044204 ]
NArray.float(4):
[ -2.83592, -1.3708, -1.93497, 1.62496 ]
NArray.float(4):
[ 0.0892217, 0.0926018, 0.0563908, 0.0429952 ]
NArray.float(4):
[ -2.85097, -1.34642, -1.98613, 1.64491 ]
NArray.float(4):
[ 0.0586483, 0.121842, 0.0751867, 0.0386004 ]
NArray.float(4):
[ -2.87623, -1.37059, -2.08717, 1.63964 ]
NArray.float(4):
[ 0.0711592, 0.116359, 0.0495597, 0.0453222 ]
NArray.float(4):
[ -2.88898, -1.41302, -2.15394, 1.68655 ]
NArray.float(4):
[ 0.0528382, 0.0930614, 0.0465937, 0.0410446 ]
NArray.float(4):
[ -2.89889, -1.47588, -2.18659, 1.71058 ]
NArray.float(4):
[ 0.0560685, 0.0779511, 0.0407446, 0.0347821 ]
NArray.float(4):
[ -2.8862, -1.48574, -2.2112, 1.73948 ]
NArray.float(4):
[ 0.0530539, 0.0464132, 0.0300221, 0.0258965 ]
NArray.float(4):
[ -2.86435, -1.48223, -2.24445, 1.75361 ]
NArray.float(4):
[ 0.0679396, 0.0362308, 0.0243165, 0.0149663 ]

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
