import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'auth_providers.dart';
import 'profile_providers.dart';
import 'shared_prefs_provider.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final user = ref.watch(currentUserProvider);
  return LanguageNotifier(prefs, user?.uid);
});

/// Tracks whether the user has gone through the language picker at least once.
/// `null` = still loading, `false` = not picked yet, `true` = already picked.
final hasPickedLanguageProvider = StateNotifierProvider<HasPickedLanguageNotifier, bool?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final user = ref.watch(currentUserProvider);
  final profile = ref.watch(currentUserProfileProvider).asData?.value;
  return HasPickedLanguageNotifier(prefs, user?.uid, profile);
});

class HasPickedLanguageNotifier extends StateNotifier<bool?> {

  HasPickedLanguageNotifier(this._prefs, this._uid, UserProfile? profile) : super(null) {
    _load(profile);
  }
  final SharedPreferences _prefs;
  final String? _uid;
  String get _key => _uid != null ? '${_uid}_has_picked_language' : 'has_picked_language';

  void _load(UserProfile? profile) {
    final localVal = _prefs.getBool(_key) ?? false;
    final cloudVal = profile?.hasPickedLanguage ?? false;
    
    final val = localVal || cloudVal;

    state = val;
    
    if (cloudVal && !localVal) {
      _prefs.setBool(_key, true);
    }
  }

  Future<void> markPicked() async {
    
    // 1. Update state immediately for reactive UI
    state = true;
    
    // 2. Save to SharedPreferences immediately (fast)
    await _prefs.setBool(_key, true);
    
    // 3. Sync to Firestore in background (don't await)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'hasPickedLanguage': true})
          .catchError((_) => null);
    }
  }
}

class LanguageNotifier extends StateNotifier<Locale> {
  
  LanguageNotifier(this._prefs, this._uid) : super(ui.PlatformDispatcher.instance.locale) {
    _loadSavedLanguage();
  }
  final SharedPreferences _prefs;
  final String? _uid;
  String get _languageKey => _uid != null ? '${_uid}_preferred_ui_language' : 'preferred_ui_language';

  void _loadSavedLanguage() {
    final savedLang = _prefs.getString(_languageKey);
    if (savedLang != null) {
      state = Locale(savedLang);
    }
  }

  Future<void> setLanguage(String languageCode) async {
    // 1. Update state immediately
    state = Locale(languageCode);

    // 2. Save to SharedPreferences (essential for immediate UI feedback)
    await _prefs.setString(_languageKey, languageCode);

    // 3. Sync to Firestore in background (non-blocking)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'language': languageCode})
          .catchError((_) => null); // Fail silently in background
    }
  }
}
