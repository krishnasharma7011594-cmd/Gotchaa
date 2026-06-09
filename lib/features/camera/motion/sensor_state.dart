import 'dart:ui';

class SensorState {

  const SensorState({
    required this.tiltX,
    required this.tiltY,
    required this.rotationZ,
    required this.shakeIntensity,
    required this.isShaking,
    required this.tiltVelocity,
    required this.motionBlurVector,
    required this.stabilizedTilt,
  });

  factory SensorState.zero() => const SensorState(
        tiltX: 0,
        tiltY: 0,
        rotationZ: 0,
        shakeIntensity: 0,
        isShaking: false,
        tiltVelocity: 0,
        motionBlurVector: Offset.zero,
        stabilizedTilt: Offset.zero,
      );
  final double tiltX;
  final double tiltY;
  final double rotationZ;
  final double shakeIntensity;
  final bool isShaking;
  final double tiltVelocity;
  final Offset motionBlurVector;
  final Offset stabilizedTilt;
}
