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
