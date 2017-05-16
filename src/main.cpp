#include <uWS/uWS.h>
#include <iostream>
#include "json.hpp"
#include "PID.h"
#include <math.h>

#include <sysexits.h>

// for convenience
using json = nlohmann::json;

// Use this code when closing the socket after we detect that the car has
// crashed; this lets the server know that it was closed intentionally, rather
// than due to a network / simulator crashing problem.
const int CAR_CRASHED_CODE = 2000;
const int MAX_RUNTIME_CODE = 2001;

// For converting back and forth between radians and degrees.
constexpr double pi() { return M_PI; }
double deg2rad(double x) { return x * pi() / 180; }
double rad2deg(double x) { return x * 180 / pi(); }

// Checks if the SocketIO event has JSON data.
// If there is data the JSON object in string format will be returned,
// else the empty string "" will be returned.
std::string hasData(std::string s) {
  auto found_null = s.find("null");
  auto b1 = s.find_first_of("[");
  auto b2 = s.find_last_of("]");
  if (found_null != std::string::npos) {
    return "";
  }
  else if (b1 != std::string::npos && b2 != std::string::npos) {
    return s.substr(b1, b2 - b1 + 1);
  }
  return "";
}

int main(int argc, char **argv)
{
  uWS::Hub h;
  bool reset = false;
  bool tuning;
  double Kp;
  double Ki;
  double Kd;
  double min_throttle;
  double max_throttle;
  double mean_steer_delay;
  double throttle_steer_threshold;
  double max_runtime;

  if (argc == 9) {
    tuning = true;
    Kp = atof(argv[1]);
    Ki = atof(argv[2]);
    Kd = atof(argv[3]);
    min_throttle = atof(argv[4]);
    max_throttle = atof(argv[5]);
    mean_steer_delay = atof(argv[6]);
    throttle_steer_threshold = atof(argv[7]);
    max_runtime = atof(argv[8]);
  } else {
    tuning = false;
    // timid:
    Kp = 0.09246630;
    Ki = 0.002171082;
    Kd = 0.04401599;
    min_throttle = -0.6;
    max_throttle = 0.6;
    mean_steer_delay = 0.1289787;
    throttle_steer_threshold = 0.06207176;
    // aggressive:
    // Kp = 0.07936167;
    // Ki = 0.002124203;
    // Kd = 0.04551714;
    // min_throttle = -0.6;
    // max_throttle = 0.6;
    // mean_steer_delay = 0.11048628;
    // throttle_steer_threshold = 0.09574146;
    max_runtime = 24 * 3600;
  }
  PID pid(tuning, Kp, Ki, Kd, min_throttle, max_throttle, mean_steer_delay,
    throttle_steer_threshold);

  h.onMessage([&reset, max_runtime, &pid](
    uWS::WebSocket<uWS::SERVER> ws, char *data, size_t length,
    uWS::OpCode opCode) {
    // "42" at the start of the message means there's a websocket message event.
    // The 4 signifies a websocket message
    // The 2 signifies a websocket event
    if (length && length > 2 && data[0] == '4' && data[1] == '2')
    {
      auto s = hasData(std::string(data));
      if (s != "") {
        auto j = json::parse(s);
        std::string event = j[0].get<std::string>();
        if (event == "telemetry") {
          // Make sure we've reset the simulator once on this run.
          if (pid.tuning && !reset) {
            std::string reset_msg = "42[\"reset\", {}]";
            ws.send(reset_msg.data(), reset_msg.length(), uWS::OpCode::TEXT);
            reset = true;
            return;
          }

          // j[1] is the data JSON object
          double cte = std::stod(j[1]["cte"].get<std::string>());
          double speed = std::stod(j[1]["speed"].get<std::string>());
          double angle = std::stod(j[1]["steering_angle"].get<std::string>());

          // Update the PID controller.
          pid.Update(cte, speed);

          // If the controller thinks it has crashed the car, terminate the
          // simulator.
          if (pid.tuning && pid.crashed) {
            std::cout << pid << std::endl;
            ws.close(CAR_CRASHED_CODE);
            return;
          }

          // If we've run all the way to the deadline, stop.
          if (pid.tuning && pid.runtime > max_runtime) {
            std::cout << pid << std::endl;
            ws.close(MAX_RUNTIME_CODE);
            return;
          }

          /*
          * TODO: Feel free to play around with the throttle and speed. Maybe use
          * another PID controller to control the speed!
          */

          double steer_value = pid.SteeringAngle(angle);
          double throttle = pid.Throttle(speed, steer_value);

          // if (!pid.tuning) {
          //   std::cout << "CTE: " << cte << " Steering Value: " << steer_value
          //     << " Speed: " << speed << " Throttle: " << throttle << std::endl;
          // }

          json msgJson;
          msgJson["steering_angle"] = steer_value;
          msgJson["throttle"] = throttle;
          auto msg = "42[\"steer\"," + msgJson.dump() + "]";
          ws.send(msg.data(), msg.length(), uWS::OpCode::TEXT);
        }
      } else {
        // Manual driving
        std::string msg = "42[\"manual\",{}]";
        ws.send(msg.data(), msg.length(), uWS::OpCode::TEXT);
      }
    }
  });

  // We don't need this since we're not using HTTP but if it's removed the program
  // doesn't compile :-(
  h.onHttpRequest([](uWS::HttpResponse *res, uWS::HttpRequest req, char *data, size_t, size_t) {
    const std::string s = "<h1>Hello world!</h1>";
    if (req.getUrl().valueLength == 1)
    {
      res->end(s.data(), s.length());
    }
    else
    {
      // i guess this should be done more gracefully?
      res->end(nullptr, 0);
    }
  });

  h.onConnection(
    [&h, &pid](uWS::WebSocket<uWS::SERVER> ws, uWS::HttpRequest req) {
    if (!pid.tuning) {
      std::cout << "Connected!!!" << std::endl;
    }
    pid.Init();
  });

  h.onDisconnection([](uWS::WebSocket<uWS::SERVER> ws, int code, char *message, size_t length) {
    switch (code) {
      case CAR_CRASHED_CODE:
        // The car crashed; let the caller know.
        exit(1);
      case MAX_RUNTIME_CODE:
        // The simulator ran until our deadline; that's a success.
        exit(EX_OK);
      default:
        // If the simulator exits, we seem to get code 1006 or 0.
        std::cerr << "Disconnected: code=" << code << ":" <<
          std::string(message, length) << std::endl;
        exit(EX_UNAVAILABLE);
    }
  });

  int port = 4567;
  if (h.listen(port))
  {
    if (!pid.tuning) {
      std::cout << "Listening to port " << port << std::endl;
    }
  }
  else
  {
    std::cerr << "Failed to listen to port" << std::endl;
    return -1;
  }
  h.run();
}
