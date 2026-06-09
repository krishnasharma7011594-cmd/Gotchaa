import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// BeautySettings
/// 
/// User-controlled parameters for the beauty engine.
/// ─────────────────────────────────────────────────────────────────────────────
class BeautySettings {         // 0.0 - 0.1 (10% max)

  const BeautySettings({
    this.smoothness = 0.0,
    this.tone = 0.0,
    this.makeupIntensity = 0.0,
    this.sharpness = 0.0,
    this.lighting = 0.0,
    this.reshape = 0.0,
  });
  final double smoothness;      // 0.0 - 0.3 (30% max)
  final double tone;            // -1.0 (cool) to 1.0 (warm)
  final double makeupIntensity; // 0.0 - 1.0
  final double sharpness;       // 0.0 - 1.0
  final double lighting;        // 0.0 - 1.0
  final double reshape;

  BeautySettings copyWith({
    double? smoothness,
    double? tone,
    double? makeupIntensity,
    double? sharpness,
    double? lighting,
    double? reshape,
  }) => BeautySettings(
      smoothness: smoothness ?? this.smoothness,
      tone: tone ?? this.tone,
      makeupIntensity: makeupIntensity ?? this.makeupIntensity,
      sharpness: sharpness ?? this.sharpness,
      lighting: lighting ?? this.lighting,
      reshape: reshape ?? this.reshape,
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// FaceData
/// 
/// Processed landmarks and regions for a single frame.
/// ─────────────────────────────────────────────────────────────────────────────
class FaceData {

  FaceData({
    required this.faces,
    required this.sourceSize,
    required this.rotation,
  });
  final List<Face> faces;
  final Size sourceSize;
  final InputImageRotation rotation;
}
