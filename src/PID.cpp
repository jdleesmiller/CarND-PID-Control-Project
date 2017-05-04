#include "PID.h"

#include <cmath>
#include <iostream>

// The steering angle is capped at [-1, 1], which corresponds to -/+ 25 degrees.
const double MIN_CONTROL = -1;
const double MAX_CONTROL = 1;

// Wait this long before recording stats, in seconds.
const double WARMUP = 5;

// TODO what are the units of speed?
// If car is going slower than this, assume it has crashed.
const double MIN_SPEED = 0.1;

// If car has absolute CTE larger than this, in meters, assume it has crashed.
const double MAX_CTE = 0.5;

PID::PID(double Kp, double Ki, double Kd, double max_runtime)
  : Kp(Kp), Ki(Ki), Kd(Kd), max_runtime(max_runtime) { }

void PID::Init() {
  p_error = 0;
  i_error = 0;
  d_error = 0;
  t_init = std::chrono::steady_clock::now();
  t = t_init;
  crashed = false;
}

void PID::Update(double cte, double speed, double angle) {
  auto new_t = std::chrono::steady_clock::now();
  std::chrono::duration<double> dt_duration = new_t - t;
  double dt = dt_duration.count();
  t = new_t;

  // Detect crashes.
  std::chrono::duration<double> runtime_duration = new_t - t_init;
  double runtime = runtime_duration.count();
  if (runtime > WARMUP) {
    if (fabs(cte) > MAX_CTE || speed < MIN_SPEED) {
      crashed = true;
    }
    if (runtime > max_runtime) {
      done = true;
    }
  }

  // Update error terms.
  d_error = (cte - p_error) / dt;
  p_error = cte;
  i_error += cte * dt;
}

double PID::SteeringAngle() {
  double control = -(Kp * p_error + Ki * i_error + Kd * d_error);
  if (control > MAX_CONTROL) {
    control = MAX_CONTROL;
  }
  if (control < MIN_CONTROL) {
    control = MIN_CONTROL;
  }
  return control;
}
