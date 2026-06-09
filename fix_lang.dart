import 'dart:io';
void main() {
  final f = File('lib/features/settings/presentation/screens/language_settings_screen.dart');
  var s = f.readAsStringSync();
  s = s.replaceFirst(RegExp(r"import 'package:flutter/material\.dart';[\s\S]*?'Hindi \(हिन्दी\)': TranslateLanguage\.hindi,"),
  """
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:gotchaa/core/l10n/app_localizations_x.dart';
import 'package:gotchaa/core/providers/language_provider.dart';

// ──────────────────────────────────────────────────────────
//  ML Kit chat-language list (unchanged)
// ──────────────────────────────────────────────────────────
const Map<String, TranslateLanguage> _chatLanguages = {
  'English': TranslateLanguage.english,
  'Hindi (हिन्दी)': TranslateLanguage.hindi,""");
  f.writeAsStringSync(s);
}
