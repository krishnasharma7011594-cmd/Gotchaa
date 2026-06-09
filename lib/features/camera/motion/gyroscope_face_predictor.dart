import 'dart:math';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'kalman_filter.dart';

class PredictedFacePose {
  PredictedFacePose({required this.boundingBox, required this.landmarks});
  final Rect boundingBox;
  final Map<FaceLandmarkType, Point<int>> landmarks;
}

class GyroscopeFacePredictor {
  final Map<FaceLandmarkType, KalmanFilter> _landmarkFilters = {};
  final KalmanFilter _boundsFilterLeft = KalmanFilter();
  final KalmanFilter _boundsFilterTop = KalmanFilter();
  final KalmanFilter _boundsFilterRight = KalmanFilter();
  final KalmanFilter _boundsFilterBottom = KalmanFilter();

  double _lastGyroX = 0;
  double _lastGyroY = 0;
  int _lastTimestamp = 0;

  Face? _lastTrueFace;

  void pushMLKitFace(Face face) {
    if (_lastTrueFace == null) {
      // Init filters
      _boundsFilterLeft.x = face.boundingBox.left;
      _boundsFilterTop.y = face.boundingBox.top;
      _boundsFilterRight.x = face.boundingBox.right;
      _boundsFilterBottom.y = face.boundingBox.bottom;

      for (final entry in face.landmarks.entries) {
        _landmarkFilters[entry.key] = KalmanFilter()
          ..x = entry.value!.position.x.toDouble()
          ..y = entry.value!.position.y.toDouble();
      }
    } else {
      // Update with new true measurement
      _boundsFilterLeft.update(face.boundingBox.left, 0);
      _boundsFilterTop.update(0, face.boundingBox.top);
      _boundsFilterRight.update(face.boundingBox.right, 0);
      _boundsFilterBottom.update(0, face.boundingBox.bottom);

      for (final entry in face.landmarks.entries) {
        if (_landmarkFilters[entry.key] != null) {
          _landmarkFilters[entry.key]!.update(
              entry.value!.position.x.toDouble(),
              entry.value!.position.y.toDouble());
        }
      }
    }

    _lastTrueFace = face;
  }

  PredictedFacePose predict(double currentGyroX, double currentGyroY) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (_lastTimestamp == 0) _lastTimestamp = now;
    final double dt = (now - _lastTimestamp) / 1000.0;
    _lastTimestamp = now;

    // Delta rotation
    final double dX = currentGyroX - _lastGyroX;
    final double dY = currentGyroY - _lastGyroY;

    _lastGyroX = currentGyroX;
    _lastGyroY = currentGyroY;

    if (_lastTrueFace == null) {
      return PredictedFacePose(boundingBox: Rect.zero, landmarks: {});
    }

    // Step prediction matching physical shift
    // Gyro X tilt means phone moved up/down -> affects Y coordinate
    // Gyro Y tilt means phone moved left/right -> affects X coordinate
    _boundsFilterLeft.predict(dt, dY, 0);
    _boundsFilterTop.predict(dt, 0, dX);
    _boundsFilterRight.predict(dt, dY, 0);
    _boundsFilterBottom.predict(dt, 0, dX);

    final mappedLandmarks = <FaceLandmarkType, Point<int>>{};
    for (final key in _landmarkFilters.keys) {
      _landmarkFilters[key]!.predict(dt, dY, dX);
      mappedLandmarks[key] = Point<int>(
          _landmarkFilters[key]!.x.round(), _landmarkFilters[key]!.y.round());
    }

    return PredictedFacePose(
      boundingBox: Rect.fromLTRB(
        _boundsFilterLeft.x,
        _boundsFilterTop.y,
        _boundsFilterRight.x,
        _boundsFilterBottom.y,
      ),
      landmarks: mappedLandmarks,
    );
  }
}
