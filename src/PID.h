#ifndef PID_H
#define PID_H

#include <chrono>

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
  double Kp;
  double Ki;
  double Kd;

  // Time of last Init.
  std::chrono::steady_clock::time_point t_init;

  // Time of last update, or time of last Init on first measurement.
  std::chrono::steady_clock::time_point t;

  // Do we think the car has crashed?
  bool crashed;

  /*
  * Constructor
  */
  PID();

  /*
  * Destructor.
  */
  virtual ~PID();

  /*
  * Initialize PID.
  */
  void Init(double Kp, double Ki, double Kd);

  /*
  * Update the PID error variables given cross track error.
  */
  void Update(double cte, double speed, double angle);

  /*
  * Calculate the steering angle control output.
  */
  double SteeringAngle();
};

#endif /* PID_H */
