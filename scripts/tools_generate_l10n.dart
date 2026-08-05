import 'dart:convert';
import 'dart:io';

void main() async {
  final l10nDir = Directory('assets/l10n');
  if (!l10nDir.existsSync()) {
    print('assets/l10n not found!');
    return;
  }

  final files = l10nDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();

  final Map<String, Map<String, String>> translations = {};

  for (final file in files) {
    final langCode = file.uri.pathSegments.last.split('.').first;
    final content = file.readAsStringSync();
    final Map<String, dynamic> jsonMap = json.decode(content);

    translations[langCode] = jsonMap.map((k, v) => MapEntry(k, v.toString()));
  }

  // Generate the dart code
  final buffer = StringBuffer();
  buffer.writeln("import 'package:flutter/widgets.dart';");
  buffer.writeln(
      "import 'package:flutter_localizations/flutter_localizations.dart';");
  buffer.writeln('');
  buffer.writeln('class LanguageMeta {');
  buffer.writeln('  final String code;');
  buffer.writeln('  final String nameNative;');
  buffer.writeln('  final String nameEn;');
  buffer.writeln('  final String flag;');
  buffer.writeln('');
  buffer.writeln(
      '  const LanguageMeta(this.code, this.nameNative, this.nameEn, this.flag);');
  buffer.writeln('}');
  buffer.writeln('');
  buffer.writeln('class AppLocalizationsConfig {');
  buffer.writeln('  static const List<LanguageMeta> languages = [');
  buffer.writeln("    LanguageMeta('en', 'English', 'English', '🇬🇧'),");
  buffer.writeln("    LanguageMeta('hi', 'हिन्दी', 'Hindi', '🇮🇳'),");
  buffer.writeln("    LanguageMeta('es', 'Español', 'Spanish', '🇪🇸'),");
  buffer.writeln("    LanguageMeta('pt', 'Português', 'Portuguese', '🇵🇹'),");
  buffer.writeln("    LanguageMeta('ar', 'العربية', 'Arabic', '🇸🇦'),");
  buffer.writeln("    LanguageMeta('fr', 'Français', 'French', '🇫🇷'),");
  buffer.writeln("    LanguageMeta('de', 'Deutsch', 'German', '🇩🇪'),");
  buffer.writeln("    LanguageMeta('ru', 'Русский', 'Russian', '🇷🇺'),");
  buffer.writeln("    LanguageMeta('ja', '日本語', 'Japanese', '🇯🇵'),");
  buffer.writeln("    LanguageMeta('ko', '한국어', 'Korean', '🇰🇷'),");
  buffer.writeln("    LanguageMeta('zh', '中文', 'Chinese', '🇨🇳'),");
  buffer.writeln("    LanguageMeta('tr', 'Türkçe', 'Turkish', '🇹🇷'),");
  buffer.writeln("    LanguageMeta('it', 'Italiano', 'Italian', '🇮🇹'),");
  buffer.writeln("    LanguageMeta('nl', 'Nederlands', 'Dutch', '🇳🇱'),");
  buffer.writeln('  ];');
  buffer.writeln('}');
  buffer.writeln('');

  buffer.writeln('class TrData {');
  buffer.writeln(
      '  static String tr(String key, String locale, {List<String>? args, Map<String, String>? namedArgs}) {');
  buffer.writeln(
      "    String value = data[locale]?[key] ?? data['en']?[key] ?? key;");
  buffer.writeln('    if (args != null && args.isNotEmpty) {');
  buffer.writeln('      for (final arg in args) {');
  buffer.writeln("        value = value.replaceFirst('{}', arg);");
  buffer.writeln('      }');
  buffer.writeln('    }');
  buffer.writeln('    if (namedArgs != null && namedArgs.isNotEmpty) {');
  buffer.writeln('      namedArgs.forEach((k, v) {');
  buffer.writeln(r"        value = value.replaceAll('{$k}', v);");
  buffer.writeln('      });');
  buffer.writeln('    }');
  buffer.writeln('    return value;');
  buffer.writeln('  }');
  buffer.writeln('');
  buffer.writeln('  static const Map<String, Map<String, String>> data = {');
  for (final lang in translations.keys) {
    buffer.writeln("    '$lang': {");
    final map = translations[lang]!;
    for (final key in map.keys) {
      // escape quotes and dollars
      final val = map[key]!
          .replaceAll(r'\', r'\\')
          .replaceAll("'", r"\'")
          .replaceAll(r'$', r'\$')
          .replaceAll('\n', r'\n');
      buffer.writeln("      '$key': '$val',");
    }
    buffer.writeln('    },');
  }
  buffer.writeln('  };');
  buffer.writeln('}');
  buffer.writeln('');
  buffer.writeln('extension AppLocalizationsX on BuildContext {');
  buffer.writeln(
      '  String tr(String key, {List<String>? args, Map<String, String>? namedArgs}) {');
  buffer
      .writeln('    final locale = Localizations.localeOf(this).languageCode;');
  buffer.writeln(
      '    return TrData.tr(key, locale, args: args, namedArgs: namedArgs);');
  buffer.writeln('  }');
  buffer.writeln('}');

  final outFile = File('lib/core/l10n/app_localizations_x.dart');
  outFile.writeAsStringSync(buffer.toString());
  print(
      r'Generated app_localizations_x.dart with ${translations.length} languages!');
}
