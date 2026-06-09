import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'nation_data.dart';
import 'nation_database.dart';

/// Three-tier nation detection service.
///
/// Priority:
///   1. Device locale   — instant, offline, no permissions
///   2. IP geolocation  — ip-api.com (free, no API key, 45 req/min)
///   3. Cache           — last known result from secure storage
///
/// Never blocks UI. Call [detectNation] in the background.
class NationDetectionService {
  NationDetectionService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );
  static const _cacheKey = 'gotchaa_cached_nation_v1';
  static const _ipApiUrl =
      'http://ip-api.com/json/?fields=status,countryCode,country,city,regionName,timezone';

  final FlutterSecureStorage _storage;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Detect nation using all available methods. Never throws.
  /// Returns a [NationData] or null only if all methods fail.
  Future<NationData?> detectNation() async {
    try {
      // 1. Try locale (instant, works offline on every Android API level)
      final localResult = _detectFromLocale();

      // 2. Try IP in parallel (non-blocking, ~300ms)
      NationData? ipResult;
      try {
        ipResult = await _detectFromIp().timeout(const Duration(seconds: 5));
      } catch (_) {
        ipResult = null;
      }

      NationData? best;

      if (localResult != null && ipResult != null) {
        if (localResult.countryCode == ipResult.countryCode) {
          // HIGH confidence — both agree
          best = ipResult.copyWith(
            detectedVia: 'LOCALE+IP',
            confidence: 'HIGH',
            detectedAt: DateTime.now(),
          );
        } else {
          // Disagree — prefer IP (more accurate for physical location)
          best = ipResult.copyWith(
              confidence: 'MEDIUM', detectedAt: DateTime.now());
        }
      } else if (ipResult != null) {
        best =
            ipResult.copyWith(confidence: 'MEDIUM', detectedAt: DateTime.now());
      } else if (localResult != null) {
        best = localResult.copyWith(
            confidence: 'MEDIUM', detectedAt: DateTime.now());
      }

      // 3. Fall back to cache if live detection failed
      best ??= await _loadCached();

      if (best != null) await _saveCache(best);
      return best;
    } catch (e) {
      return _loadCached();
    }
  }

  /// Load the last cached nation without hitting any network.
  Future<NationData?> getCached() => _loadCached();

  /// Clear cached nation (e.g. on sign-out).
  Future<void> clearCache() => _storage.delete(key: _cacheKey);

  // ── Locale detection ──────────────────────────────────────────────────────

  NationData? _detectFromLocale() {
    try {
      // Works on Android 19+ and all iOS versions.
      // ui.PlatformDispatcher.instance.locale is the canonical way in Flutter.
      // It reflects what Build.VERSION.SDK_INT >= 24 uses (LocaleList) via Flutter.
      final locale = ui.PlatformDispatcher.instance.locale;
      final localeStr = locale.toLanguageTag(); // e.g. "en-IN", "pt-BR"

      // Extract country code from locale tag
      String? countryCode = locale.countryCode;

      if (countryCode == null || countryCode.isEmpty) {
        // Fallback: parse manually from "en-IN" or "en_IN"
        final parts = localeStr.replaceAll('-', '_').split('_');
        if (parts.length >= 2) {
          countryCode = parts[1].toUpperCase();
          if (countryCode.length != 2) countryCode = null;
        }
      }

      if (countryCode == null) return null;

      final nation = NationDatabase.fromCode(countryCode);
      if (nation == null) return null;

      return nation.copyWith(
        detectedVia: 'LOCALE',
        confidence: 'MEDIUM',
        detectedAt: DateTime.now(),
      );
    } catch (e) {
      // Platform.localeName fallback for very old Flutter versions
      try {
        final localeName = Platform.localeName; // e.g. "en_IN"
        return NationDatabase.fromLocale(localeName)?.copyWith(
          detectedVia: 'LOCALE',
          confidence: 'MEDIUM',
          detectedAt: DateTime.now(),
        );
      } catch (_) {
        return null;
      }
    }
  }

  // ── IP geolocation ────────────────────────────────────────────────────────

  Future<NationData?> _detectFromIp() async {
    try {
      final response = await http.get(
        Uri.parse(_ipApiUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'success') return null;

      final code = json['countryCode'] as String?;
      if (code == null || code.isEmpty) return null;

      final base = NationDatabase.fromCode(code);
      if (base == null) return null;

      return base.copyWith(
        detectedVia: 'IP',
        confidence: 'HIGH',
        detectedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  // ── Cache ─────────────────────────────────────────────────────────────────

  Future<void> _saveCache(NationData data) async {
    try {
      final json = jsonEncode(
          data.toFirestore().map((k, v) => MapEntry(k, v.toString())));
      await _storage.write(key: _cacheKey, value: json);
    } catch (e) {}
  }

  Future<NationData?> _loadCached() async {
    try {
      final raw = await _storage.read(key: _cacheKey);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final code = map['countryCode'] as String?;
      final base = NationDatabase.fromCode(code);
      if (base == null) return null;
      return base.copyWith(
        detectedVia: map['detectedVia'] as String? ?? 'CACHE',
        confidence: map['confidence'] as String? ?? 'LOW',
        detectedAt: DateTime.tryParse(map['detectedAt'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
