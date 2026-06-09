class LanguageMeta {
  const LanguageMeta({
    required this.code,
    required this.nameEn,
    required this.nameNative,
    required this.flag,
  });

  factory LanguageMeta.fromConfig(Map<String, String> map) {
    final code = map['code'] ?? 'en';
    return LanguageMeta(
      code: code,
      nameEn: map['name'] ?? '',
      nameNative: map['nativeName'] ?? '',
      flag: _flags[code] ?? '🏳️',
    );
  }
  final String code;
  final String nameEn;
  final String nameNative;
  final String flag;

  static const Map<String, String> _flags = {
    'en': '🇬🇧',
    'hi': '🇮🇳',
    'es': '🇪🇸',
    'pt': '🇵🇹',
    'ar': '🇸🇦',
    'fr': '🇫🇷',
    'de': '🇩🇪',
    'ru': '🇷🇺',
    'ja': '🇯🇵',
    'ko': '🇰🇷',
    'zh': '🇨🇳',
    'tr': '🇹🇷',
    'it': '🇮🇹',
    'nl': '🇳🇱',
  };
}
