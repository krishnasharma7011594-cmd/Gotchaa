import 'beauty_models.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// BeautyPresetRegistry
///
/// Preset logic for the 10 production beauty filters.
/// ─────────────────────────────────────────────────────────────────────────────
class BeautyPresetRegistry {
  static const List<String> presetNames = [
    'Natural Glow',
    'Soft Skin',
    'Clean Acne',
    'Golden Hour',
    'Cool Matte',
    'Smart Makeup',
    'Eye Pop',
    'HD Detail',
    'Slim Face',
    'AI Adaptive',
  ];

  static BeautySettings getPreset(String name) {
    switch (name) {
      case 'Natural Glow':
        return const BeautySettings(
          smoothness: 0.15,
          tone: 0.1,
          lighting: 0.15,
          sharpness: 0.2,
        );
      case 'Soft Skin':
        return const BeautySettings(
          smoothness: 0.30,
          tone: 0.05,
          lighting: 0.1,
          sharpness: 0,
        );
      case 'Clean Acne':
        return const BeautySettings(
          smoothness: 0.25,
          sharpness: 0.5,
          lighting: 0.1,
        );
      case 'Golden Hour':
        return const BeautySettings(
          smoothness: 0.15,
          tone: 0.8, // Very Warm
          lighting: 0.4,
          makeupIntensity: 0.2,
        );
      case 'Cool Matte':
        return const BeautySettings(
          smoothness: 0.20,
          tone: -0.6, // Very Cool
          sharpness: 0.4,
          lighting: -0.1,
        );
      case 'Smart Makeup':
        return const BeautySettings(
          smoothness: 0.15,
          makeupIntensity: 0.9,
          lighting: 0.2,
        );
      case 'Eye Pop':
        return const BeautySettings(
          lighting: 0.6,
          sharpness: 0.8,
          smoothness: 0.1,
        );
      case 'HD Detail':
        return const BeautySettings(
          smoothness: 0.05,
          sharpness: 1,
          lighting: 0.2,
        );
      case 'Slim Face':
        return const BeautySettings(
          smoothness: 0.15,
          reshape: 0.1,
          lighting: 0.1,
        );
      case 'AI Adaptive':
        return const BeautySettings(
          smoothness: 0.25,
          tone: 0.15,
          lighting: 0.3,
          reshape: 0.05,
        );
      default:
        return const BeautySettings();
    }
  }
}
