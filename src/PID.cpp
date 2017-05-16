#include "PID.h"

#include <cmath>
#include <iostream>

// The steering angle is capped at [-1, 1], which corresponds to -/+ 25 degrees.
const double MIN_CONTROL = -1;
const double MAX_CONTROL = 1;

// There should also be a maximum rate of change in the steering angle. Based
// on this paper:
// https://www.nhtsa.gov/DOT/NHTSA/NRD/Multimedia/PDFs/VRTC/ca/capubs/NHTSA_forkenbrock_driversteeringcapabilityrpt.pdf
// steering wheel controllers can typically steer at about 1000 steering wheel
// degrees / second. According to https://en.wikipedia.org/wiki/Steering_ratio,
// the steering ratio is not usually larger than 12:1 (360 wheel degrees :
// 30 steering degrees). This gives a peak rate of change of ~33 degrees per
// second. The simulator timestep is roughly 0.05s, so we should not be changing
// the steering angle by no more than about 1.67 degrees per timestep. In
// control units, with 25 degrees per control unit, that is 0.0667.
const double MAX_CONTROL_DELTA = 1000.0 / 30.0 / 25.0 * 0.05;

// Wait this long before recording stats, in seconds.
const double WARMUP = 5;

// If car is going slower than this, in miles per hour, assume it has crashed.
const double MIN_SPEED = 5;

// If car has absolute CTE larger than this, in meters, assume it has crashed.
const double MAX_CTE = 4.5;

// 1609.34m / mile * 1h / 3600s = x (m / s) / (miles / h).
const double MPH_TO_METERS_PER_SECOND = (1609.34 / 3600.0);

PID::PID(bool tuning, double Kp, double Ki, double Kd,
  double min_throttle, double max_throttle,
  double mean_steer_delay, double throttle_steer_threshold)
  : tuning(tuning), Kp(Kp), Ki(Ki), Kd(Kd),
    min_throttle(min_throttle), max_throttle(max_throttle),
    mean_steer_delay(mean_steer_delay),
    throttle_steer_threshold(throttle_steer_threshold) { }

void PID::Init() {
  p_error = 0;
  i_error = 0;
  d_error = 0;
  t_init = std::chrono::steady_clock::now();
  t = t_init;
  dt = 0;
  crashed = false;
  runtime = 0;
  previous_speed = 0;
  distance = 0;
  mean_steer = 0;
  total_absolute_cte = 0;
}

void PID::Update(double cte, double speed) {
  auto new_t = std::chrono::steady_clock::now();
  std::chrono::duration<double> dt_duration = new_t - t;
  dt = dt_duration.count();
  t = new_t;

  if (tuning) {
    std::chrono::duration<double> runtime_duration = new_t - t_init;
    runtime = runtime_duration.count();
    if (runtime > WARMUP && (fabs(cte) > MAX_CTE || speed < MIN_SPEED)) {
      crashed = true;
    }

    double average_speed = (speed + previous_speed) / 2;
    distance += average_speed * dt * MPH_TO_METERS_PER_SECOND;
    previous_speed = speed;

    total_absolute_cte += fabs((cte + p_error) / 2.0) * dt;
  }

  // Update error terms.
  d_error = (cte - p_error) / dt;
  p_error = cte;
  i_error += cte * dt;
}

double PID::SteeringAngle(double angle) {
  double old_control = angle / 25.0;
  double new_control = -(Kp * p_error + Ki * i_error + Kd * d_error);

  double max_control = old_control + MAX_CONTROL_DELTA;
  double min_control = old_control - MAX_CONTROL_DELTA;
  if (max_control > MAX_CONTROL) {
    max_control = MAX_CONTROL;
  }
  if (min_control < MIN_CONTROL) {
    max_control = MIN_CONTROL;
  }

  if (new_control > max_control) {
    new_control = max_control;
  }
  if (new_control < min_control) {
    new_control = min_control;
  }
  return new_control;
}

double PID::Throttle(double speed, double steer_value) {
  double weight = 1 - exp(-dt / mean_steer_delay);
  mean_steer = weight * steer_value + (1 - weight) * mean_steer;

  if (speed > 20 &&
    fabs(steer_value) > fabs(mean_steer) + throttle_steer_threshold)
  {
    return min_throttle;
  } else {
    return max_throttle;
  }
}

std::ostream &operator<<(std::ostream &os, const PID &pid) {
  os << "{\"runtime\":" << pid.runtime
    << ", \"distance\":" << pid.distance
    << ", \"total_absolute_cte\":" << pid.total_absolute_cte << "}";
  return os;
}
