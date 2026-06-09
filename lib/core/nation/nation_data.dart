import 'package:cloud_firestore/cloud_firestore.dart';

/// Immutable value object representing a user's detected nation.
class NationData {
  const NationData({
    required this.countryCode,
    required this.countryName,
    required this.countryNameLocal,
    required this.flag,
    required this.continent,
    required this.timezone,
    required this.currencyCode,
    required this.currencySymbol,
    required this.primaryLanguage,
    required this.languageCode,
    required this.detectedVia,
    required this.confidence,
    required this.detectedAt,
  });

  factory NationData.fromFirestore(Map<String, dynamic> map) => NationData(
        countryCode: map['countryCode'] as String? ?? '',
        countryName: map['countryName'] as String? ?? '',
        countryNameLocal: map['countryNameLocal'] as String? ?? '',
        flag: map['flag'] as String? ?? '🌍',
        continent: map['continent'] as String? ?? '',
        timezone: map['timezone'] as String? ?? '',
        currencyCode: map['currencyCode'] as String? ?? '',
        currencySymbol: map['currencySymbol'] as String? ?? '',
        primaryLanguage: map['primaryLanguage'] as String? ?? '',
        languageCode: map['languageCode'] as String? ?? '',
        detectedVia: map['detectedVia'] as String? ?? 'UNKNOWN',
        confidence: map['confidence'] as String? ?? 'LOW',
        detectedAt:
            (map['detectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
  final String countryCode; // "IN"
  final String countryName; // "India"
  final String countryNameLocal; // "भारत"
  final String flag; // "🇮🇳"
  final String continent; // "Asia"
  final String timezone; // "Asia/Kolkata"
  final String currencyCode; // "INR"
  final String currencySymbol; // "₹"
  final String primaryLanguage; // "Hindi"
  final String languageCode; // "hi"
  final String detectedVia; // "LOCALE" | "IP" | "GPS" | "MANUAL" | "DATABASE"
  final String confidence; // "HIGH" | "MEDIUM" | "LOW"
  final DateTime detectedAt;

  // ── Computed ──────────────────────────────────────────────────────────────
  String get flagAndName => '$flag $countryName';
  String get flagOnly => flag;
  String get displayLine => '$flag $countryName • $continent';

  // ── Continent tint color (hex) ────────────────────────────────────────────
  String get continentColorHex {
    switch (continent) {
      case 'Asia':
        return '#FFF3E0'; // orange tint
      case 'Europe':
        return '#E3F2FD'; // blue tint
      case 'Americas':
        return '#E8F5E9'; // green tint
      case 'Africa':
        return '#FFFDE7'; // yellow tint
      case 'Oceania':
        return '#E0F2F1'; // teal tint
      case 'Antarctica':
        return '#F5F5F5'; // white tint
      default:
        return '#F3E5F5';
    }
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'countryCode': countryCode,
        'countryName': countryName,
        'countryNameLocal': countryNameLocal,
        'flag': flag,
        'continent': continent,
        'timezone': timezone,
        'currencyCode': currencyCode,
        'currencySymbol': currencySymbol,
        'primaryLanguage': primaryLanguage,
        'languageCode': languageCode,
        'detectedVia': detectedVia,
        'confidence': confidence,
        'detectedAt': Timestamp.fromDate(detectedAt),
      };

  NationData copyWith({
    String? detectedVia,
    String? confidence,
    DateTime? detectedAt,
  }) =>
      NationData(
        countryCode: countryCode,
        countryName: countryName,
        countryNameLocal: countryNameLocal,
        flag: flag,
        continent: continent,
        timezone: timezone,
        currencyCode: currencyCode,
        currencySymbol: currencySymbol,
        primaryLanguage: primaryLanguage,
        languageCode: languageCode,
        detectedVia: detectedVia ?? this.detectedVia,
        confidence: confidence ?? this.confidence,
        detectedAt: detectedAt ?? this.detectedAt,
      );

  @override
  bool operator ==(Object other) =>
      other is NationData && other.countryCode == countryCode;

  @override
  int get hashCode => countryCode.hashCode;

  @override
  String toString() =>
      'NationData($flagAndName, via=$detectedVia, confidence=$confidence)';
}
