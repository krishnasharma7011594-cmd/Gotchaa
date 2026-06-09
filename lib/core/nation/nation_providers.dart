import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'nation_data.dart';
import 'nation_detection_service.dart';

// ── Service providers ─────────────────────────────────────────────────────

final nationDetectionServiceProvider =
    Provider<NationDetectionService>((ref) => NationDetectionService());

// ── Detection state ───────────────────────────────────────────────────────

/// Detects the user's nation once and caches the result.
/// Runs automatically on first read; safe to call many times.
final detectedNationProvider = FutureProvider<NationData?>((ref) async {
  final service = ref.read(nationDetectionServiceProvider);
  // Try cache first for instant result, then do full detection in background
  final cached = await service.getCached();
  if (cached != null) {
    // Trigger background refresh but return cached immediately
    service.detectNation().then((fresh) {
      // Result is auto-saved to cache by service; no extra action needed.
    });
    return cached;
  }
  return service.detectNation();
});

// ── Manually selected nation ──────────────────────────────────────────────

/// Holds the user's manually selected or confirmed nation during sign-up.
/// Initialised from [detectedNationProvider], overridable by user tap.
class SelectedNationNotifier extends StateNotifier<NationData?> {
  SelectedNationNotifier() : super(null);

  void select(NationData nation) => state = nation;
  void clear() => state = null;
}

final selectedNationProvider =
    StateNotifierProvider<SelectedNationNotifier, NationData?>(
  (ref) => SelectedNationNotifier(),
);

// ── Login travel detection ────────────────────────────────────────────────

/// Background service: on login compares detected country with stored homeCountry
/// and updates Firestore if the user is travelling.
class LoginNationUpdateService {
  LoginNationUpdateService(this._detector);
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NationDetectionService _detector;

  /// Call after successful Firebase Auth sign-in.
  /// [uid] is the signed-in user's UID.
  Future<TravelResult> checkAndUpdateOnLogin(String uid) async {
    try {
      final detected = await _detector.detectNation();
      if (detected == null) return TravelResult.unknown;

      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return TravelResult.unknown;

      final data = doc.data()!;
      final nationMap = data['nation'] as Map<String, dynamic>?;
      final homeCode = nationMap?['homeCountry'] as String?;

      final currentCode = detected.countryCode;

      if (homeCode == null) {
        // First login after signup — save everything
        await _saveNationToFirestore(uid, detected, isFirst: true);
        return TravelResult.unknown;
      }

      if (homeCode == currentCode) {
        // Same country — just refresh timestamp
        await _db.collection('users').doc(uid).update({
          'nation.currentCountry': currentCode,
          'nation.isTravelling': false,
          'nation.lastSeenAt': FieldValue.serverTimestamp(),
        });
        return TravelResult.sameCountry;
      } else {
        // Different country → travelling
        await _db.collection('users').doc(uid).update({
          'nation.currentCountry': currentCode,
          'nation.currentFlag': detected.flag,
          'nation.currentCountryName': detected.countryName,
          'nation.currentContinent': detected.continent,
          'nation.isTravelling': true,
          'nation.lastSeenAt': FieldValue.serverTimestamp(),
        });

        // Log to location history
        await _db
            .collection('users')
            .doc(uid)
            .collection('locationHistory')
            .add({
          'countryCode': currentCode,
          'countryName': detected.countryName,
          'flag': detected.flag,
          'continent': detected.continent,
          'detectedVia': detected.detectedVia,
          'confidence': detected.confidence,
          'timestamp': FieldValue.serverTimestamp(),
        });

        return TravelResult.travelling(detected);
      }
    } catch (e) {
      return TravelResult.unknown;
    }
  }

  /// Save nation on first signup.
  Future<void> _saveNationToFirestore(String uid, NationData nation,
      {bool isFirst = false}) async {
    await _db.collection('users').doc(uid).set({
      'nation': {
        'homeCountry': nation.countryCode,
        'homeFlag': nation.flag,
        'homeCountryName': nation.countryName,
        'homeContinent': nation.continent,
        'currentCountry': nation.countryCode,
        'currentFlag': nation.flag,
        'currentCountryName': nation.countryName,
        'currentContinent': nation.continent,
        'isTravelling': false,
        'primaryLanguage': nation.primaryLanguage,
        'languageCode': nation.languageCode,
        'timezone': nation.timezone,
        'detectedVia': nation.detectedVia,
        'confidence': nation.confidence,
        'detectedAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'isManuallySet': false,
      }
    }, SetOptions(merge: true));
  }

  /// Save nation chosen on signup (may be manually picked).
  Future<void> saveSignupNation(String uid, NationData nation,
      {bool isManual = false}) async {
    await _db.collection('users').doc(uid).set({
      'nation': {
        'homeCountry': nation.countryCode,
        'homeFlag': nation.flag,
        'homeCountryName': nation.countryName,
        'homeContinent': nation.continent,
        'currentCountry': nation.countryCode,
        'currentFlag': nation.flag,
        'currentCountryName': nation.countryName,
        'currentContinent': nation.continent,
        'isTravelling': false,
        'primaryLanguage': nation.primaryLanguage,
        'languageCode': nation.languageCode,
        'timezone': nation.timezone,
        'currencyCode': nation.currencyCode,
        'currencySymbol': nation.currencySymbol,
        'detectedVia': nation.detectedVia,
        'confidence': nation.confidence,
        'isManuallySet': isManual,
        'detectedAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
  }
}

final loginNationUpdateServiceProvider = Provider<LoginNationUpdateService>(
    (ref) =>
        LoginNationUpdateService(ref.read(nationDetectionServiceProvider)));

// ── Travel result ─────────────────────────────────────────────────────────

class TravelResult {
  const TravelResult._({required this.isTravelling, this.currentNation});

  factory TravelResult.travelling(NationData nation) =>
      TravelResult._(isTravelling: true, currentNation: nation);
  final bool isTravelling;
  final NationData? currentNation;

  static const sameCountry = TravelResult._(isTravelling: false);
  static const unknown = TravelResult._(isTravelling: false);
}

// ── Privacy settings ──────────────────────────────────────────────────────

enum NationVisibility { country, continent, private }

class NationVisibilityService {
  static NationVisibility fromString(String? s) {
    switch (s) {
      case 'continent':
        return NationVisibility.continent;
      case 'private':
        return NationVisibility.private;
      default:
        return NationVisibility.country;
    }
  }

  /// Applies privacy filter before sharing nation data with strangers.
  static Map<String, String> applyPrivacy(
      NationData nation, NationVisibility visibility) {
    switch (visibility) {
      case NationVisibility.country:
        return {
          'display': nation.flagAndName,
          'flag': nation.flag,
          'label': nation.countryName,
        };
      case NationVisibility.continent:
        return {
          'display': '${_continentFlag(nation.continent)} ${nation.continent}',
          'flag': _continentFlag(nation.continent),
          'label': nation.continent,
        };
      case NationVisibility.private:
        return {
          'display': '🌍 Somewhere on Earth',
          'flag': '🌍',
          'label': 'Private',
        };
    }
  }

  static String _continentFlag(String continent) {
    switch (continent) {
      case 'Asia':
        return '🌏';
      case 'Europe':
        return '🌍';
      case 'Americas':
        return '🌎';
      case 'Africa':
        return '🌍';
      case 'Oceania':
        return '🌏';
      default:
        return '🌍';
    }
  }
}
