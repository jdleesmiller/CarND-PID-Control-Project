#include "PID.h"

#include <iostream>

// The steering angle is capped at [-1, 1], which corresponds to -/+ 25 degrees.
const double MIN_CONTROL = -1;
const double MAX_CONTROL = 1;

PID::PID() {}

PID::~PID() {}

void PID::Init(double Kp, double Ki, double Kd) {
  this->Kp = Kp;
  this->Ki = Ki;
  this->Kd = Kd;
  p_error = 0;
  i_error = 0;
  d_error = 0;
  t = std::chrono::steady_clock::now();
}

void PID::UpdateError(double cte) {
  auto new_t = std::chrono::steady_clock::now();
  std::chrono::duration<double> dt_duration = new_t - t;
  double dt = dt_duration.count();
  t = new_t;

  d_error = (cte - p_error) / dt;
  p_error = cte;
  i_error += cte * dt;
}

double PID::TotalError() {
  double control = -(Kp * p_error + Ki * i_error + Kd * d_error);
  if (control > MAX_CONTROL) {
    control = MAX_CONTROL;
  }
  if (control < MIN_CONTROL) {
    control = MIN_CONTROL;
  }
  return control;
}
