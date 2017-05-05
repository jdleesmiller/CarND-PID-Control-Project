#include "PID.h"

#include <cmath>
#include <iostream>

// The steering angle is capped at [-1, 1], which corresponds to -/+ 25 degrees.
const double MIN_CONTROL = -1;
const double MAX_CONTROL = 1;

// Wait this long before recording stats, in seconds.
const double WARMUP = 5;

// If car is going slower than this, in miles per hour, assume it has crashed.
const double MIN_SPEED = 0.5;

// If car has absolute CTE larger than this, in meters, assume it has crashed.
const double MAX_CTE = 5;

// 1609.34m / mile * 1h / 3600s = x (m / s) / (miles / h).
const double MPH_TO_METERS_PER_SECOND = (1609.34 / 3600.0);

PID::PID(bool tuning, double Kp, double Ki, double Kd)
  : tuning(tuning), Kp(Kp), Ki(Ki), Kd(Kd) { }

void PID::Init() {
  p_error = 0;
  i_error = 0;
  d_error = 0;
  t_init = std::chrono::steady_clock::now();
  t = t_init;
  crashed = false;
  runtime = 0;
  previous_speed = 0;
  distance = 0;
  total_absolute_cte = 0;
}

void PID::Update(double cte, double speed, double angle) {
  auto new_t = std::chrono::steady_clock::now();
  std::chrono::duration<double> dt_duration = new_t - t;
  double dt = dt_duration.count();
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

    total_absolute_cte += fabs(cte);
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

std::ostream &operator<<(std::ostream &os, const PID &pid) {
  os << "{\"runtime\":" << pid.runtime
    << ", \"distance\":" << pid.distance
    << ", \"total_absolute_cte\":" << pid.total_absolute_cte << "}";
  return os;
}
