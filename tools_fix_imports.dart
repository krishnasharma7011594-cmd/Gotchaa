import 'dart:io';

void main() async {
  final dir = Directory('lib');
  int count = 0;
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = await entity.readAsString();
      if (content.contains('context.tr(') || content.contains('context.tr')) {
        if (!content.contains('app_localizations_x.dart')) {
          final lines = content.split('\n');
          // Find last import
          int lastImportIndex = 0;
          for (int i = 0; i < lines.length; i++) {
            if (lines[i].startsWith('import ')) {
              lastImportIndex = i;
            }
          }
          lines.insert(lastImportIndex + 1,
              "import 'package:gotchaa/core/l10n/app_localizations_x.dart';");
          await entity.writeAsString(lines.join('\n'));
          print('Patched: ${entity.path}');
          count++;
        }
      }
    }
  }
  print('Patched $count files.');
}
