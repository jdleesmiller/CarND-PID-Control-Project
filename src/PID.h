#ifndef PID_H
#define PID_H

#include <chrono>
#include <iostream>

class PID {
public:
  /*
  * Errors
  */
  double p_error;
  double i_error;
  double d_error;

  /*
  * Coefficients
  */
  bool tuning;
  double Kp;
  double Ki;
  double Kd;
  double max_throttle;

  // Time of last Init.
  std::chrono::steady_clock::time_point t_init;

  // Time of last update, or time of last Init on first measurement.
  std::chrono::steady_clock::time_point t;

  // When tuning, do we think the car has crashed?
  bool crashed;

  // When tuning, the elapsed time from init to the last update, in seconds.
  double runtime;

  // When tuning, the measured speed in the previous update, in miles per hour.
  double previous_speed;

  // When tuning, estimate of total distance driven in meters.
  double distance;

  // When tuning, sum of absolute CTE over a whole run, in meters.
  double total_absolute_cte;

  /*
  * Constructor
  */
  PID(bool tuning, double Kp, double Ki, double Kd, double max_throttle);

  /*
  * Initialize PID.
  */
  void Init();

  /*
  * Update the PID error variables given cross track error.
  */
  void Update(double cte, double speed, double angle);

  /*
  * Calculate the steering angle control output.
  */
  double SteeringAngle();
};

/*
* Print the key metrics for the controller; used for tuning.
*/
std::ostream &operator<<(std::ostream &os, const PID &pid);

#endif /* PID_H */
