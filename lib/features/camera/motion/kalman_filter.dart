class KalmanFilter {
  // State variables [P_x, P_y, V_x, V_y]
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;

  // Covariance matrix
  List<List<double>> P = [
    [1, 0, 0, 0],
    [0, 1, 0, 0],
    [0, 0, 10, 0],
    [0, 0, 0, 10]
  ];

  // Process noise (confidence in our motion model)
  double q = 0.05;
  // Measurement noise (confidence in ML Kit)
  double r = 0.5;

  void predict(double dt, double gyroDeltaX, double gyroDeltaY) {
    // We update velocity based on gyro (delta angle creates lateral shift)
    // Scale factor maps angle delta to pixel delta
    vx = gyroDeltaX * 15.0;
    vy = gyroDeltaY * 15.0;

    // State Transition Matrix
    // x = x + vx * dt
    // y = y + vy * dt
    x = x + vx * dt;
    y = y + vy * dt;

    // Covariance update
    // P = P + Q
    P[0][0] += q;
    P[1][1] += q;
    P[2][2] += q;
    P[3][3] += q;
  }

  void update(double mx, double my) {
    // Kalman Gain K = P / (P + R)
    final double kx = P[0][0] / (P[0][0] + r);
    final double ky = P[1][1] / (P[1][1] + r);

    // Update state using measurement residual
    x = x + kx * (mx - x);
    y = y + ky * (my - y);

    // Update Covariance P = (1 - K) * P
    P[0][0] = (1 - kx) * P[0][0];
    P[1][1] = (1 - ky) * P[1][1];
  }
}
