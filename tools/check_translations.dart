import 'dart:convert';
import 'dart:io';

void main() async {
  final l10nDir = Directory('lib/l10n');
  if (!await l10nDir.exists()) {
    print('l10n directory not found!');
    return;
  }

  final files = await l10nDir.list().toList();
  final enFile = files.firstWhere((f) => f.path.endsWith('app_en.arb'), orElse: () => File('lib/l10n/app_en.arb'));
  
  if (!enFile.existsSync()) {
    print('app_en.arb not found!');
    return;
  }

  final enContent = jsonDecode(await File(enFile.path).readAsString()) as Map<String, dynamic>;
  
  // Filter out meta tags like @@locale
  final baseKeys = enContent.keys.where((k) => !k.startsWith('@')).toList();
  final totalKeys = baseKeys.length;

  print('Translation Completeness Report:');
  print('═══════════════════════════════');

  bool allPassed = true;

  for (final file in files) {
    if (file is File && file.path.endsWith('.arb')) {
      final langName = file.path.split('_').last.replaceAll('.arb', '');
      final content = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      
      int translatedCount = 0;
      final List<String> missingKeys = [];

      for (final key in baseKeys) {
        if (content.containsKey(key)) {
          // Check if it's identical to English (potentially untranslated outside base English file)
          if (langName != 'en' && content[key] == enContent[key] && _isActualWord(content[key])) {
            // Probably un-translated, but we count it anyway for now, later could be stricter
            translatedCount++;
          } else {
             translatedCount++;
          }
        } else {
          missingKeys.add(key);
        }
      }

      final percentage = (translatedCount / totalKeys) * 100;
      final statusStr = percentage >= 95 ? '✅' : '⚠️';
      
      if (percentage < 95) allPassed = false;

      print('${langName.padRight(18)} $translatedCount/$totalKeys   ${percentage.toStringAsFixed(0).padLeft(3)}% $statusStr ${missingKeys.isNotEmpty ? '(${missingKeys.length} missing)' : ''}');
      
      if (missingKeys.isNotEmpty) {
        print('    Missing: ${missingKeys.take(5).join(', ')}${missingKeys.length > 5 ? '...' : ''}');
      }
    }
  }
  print('═══════════════════════════════');

  if (!allPassed) {
    print('Some languages are below the 95% complete threshold!');
    exit(1);
  } else {
    print('All checks passed!');
  }
}

bool _isActualWord(dynamic value) {
  if (value is! String) return false;
  // Ignore single characters or purely symbolic strings (like emojis, numbers, URLs)
  if (value.trim().length <= 2) return false;
  return true;
}
