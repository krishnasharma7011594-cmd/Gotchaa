import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/language_provider.dart';
import '../providers/shared_prefs_provider.dart';

// ──────────────────────────────────────────────────────────
//  TranslationService  (ML Kit chat translation)
// ──────────────────────────────────────────────────────────
class TranslationService {

  TranslationService(this._prefs);
  final SharedPreferences _prefs;

  static const _chatLangKey     = 'preferred_chat_language';
  static const _autoTranslateKey = 'auto_translate_enabled';
  /// Key that stores the UI locale language code, e.g. 'es', 'hi', 'ja'
  static const _uiLangKey       = 'preferred_ui_language';

  // ── UI locale ──────────────────────────────────────────
  String get preferredUiLanguageCode =>
      _prefs.getString(_uiLangKey) ?? 'en';

  Future<void> setPreferredUiLanguageCode(String code) async {
    await _prefs.setString(_uiLangKey, code);
  }

  // ── ML Kit chat language ───────────────────────────────
  TranslateLanguage get preferredLanguage {
    final stored = _prefs.getString(_chatLangKey)?.toLowerCase() ?? 'english';
    return TranslateLanguage.values.firstWhere(
      (lang) => lang.name.toLowerCase() == stored,
      orElse: () => TranslateLanguage.english,
    );
  }

  Future<void> setPreferredLanguage(TranslateLanguage lang) async {
    await _prefs.setString(_chatLangKey, lang.name.toLowerCase());
  }

  bool get autoTranslateEnabled => _prefs.getBool(_autoTranslateKey) ?? false;

  Future<void> setAutoTranslate(bool value) async {
    await _prefs.setBool(_autoTranslateKey, value);
  }

  // ── ML Kit utilities ───────────────────────────────────
  Future<TranslateLanguage?> detectLanguage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return null;
    
    // Lower threshold for short messages (like chat)
    final languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.1);
    try {
      final String languageCode = await languageIdentifier.identifyLanguage(cleanText);

      if (languageCode == 'und') {
        // Fallback: try to see if it's a very short message that might be identifiable anyway
        final possible = await languageIdentifier.identifyPossibleLanguages(cleanText);
        if (possible.isNotEmpty && possible.first.confidence > 0.05) {
          final bestCode = possible.first.languageTag;
          
          return _mapCodeToLanguage(bestCode);
        }
        return null;
      }
      
      return _mapCodeToLanguage(languageCode);
    } catch (e) {
      
      return null;
    } finally {
      languageIdentifier.close();
    }
  }

  TranslateLanguage? _mapCodeToLanguage(String code) {
    // Standardize code (e.g. en-US -> en)
    final shortCode = code.split('-').first.toLowerCase();
    
    for (final lang in TranslateLanguage.values) {
      if (lang.bcpCode.toLowerCase() == shortCode) return lang;
    }
    return null;
  }

  Future<String> translateText(
      String text, TranslateLanguage source, TranslateLanguage target) async {
    if (source == target) return text;
    
    // Ensure models are available
    final modelManager = OnDeviceTranslatorModelManager();
    if (!await modelManager.isModelDownloaded(source.bcpCode)) {
      
      await modelManager.downloadModel(source.bcpCode, isWifiRequired: false);
    }
    if (!await modelManager.isModelDownloaded(target.bcpCode)) {
      
      await modelManager.downloadModel(target.bcpCode, isWifiRequired: false);
    }

    final onDeviceTranslator =
        OnDeviceTranslator(sourceLanguage: source, targetLanguage: target);
    try {
      final response = await onDeviceTranslator.translateText(text);
      await onDeviceTranslator.close();
      return response;
    } catch (e) {
      
      await onDeviceTranslator.close();
      return 'Translation Error';
    }
  }

  Future<bool> isModelDownloaded(TranslateLanguage lang) async {
    final modelManager = OnDeviceTranslatorModelManager();
    return modelManager.isModelDownloaded(lang.bcpCode);
  }

  Future<bool> downloadModel(TranslateLanguage lang) async {
    final modelManager = OnDeviceTranslatorModelManager();
    try {
      
      final success =
          await modelManager.downloadModel(lang.bcpCode, isWifiRequired: false);
      return success;
    } catch (e) {
      
      return false;
    }
  }
}

// ──────────────────────────────────────────────────────────
//  Providers
// ──────────────────────────────────────────────────────────
final translationServiceProvider = Provider<TranslationService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TranslationService(prefs);
});

// import '../providers/language_provider.dart'; // removed from here

/// Reactive UI locale — drives MaterialApp.locale
final localeProvider = Provider<Locale>((ref) => ref.watch(languageProvider));

// Legacy LocaleNotifier kept for backward-compatibility if needed, 
// but it now just redirects to languageProvider
class LocaleNotifier extends StateNotifier<Locale> {

  LocaleNotifier(this._ref) : super(_ref.read(languageProvider));
  final Ref _ref;

  Future<void> setLocale(String languageCode) async {
    await _ref.read(languageProvider.notifier).setLanguage(languageCode);
  }

  void updateLocale() {
    state = _ref.read(languageProvider);
  }
}
