import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    print('lib directory not found');
    return;
  }

  final searchTerms = [
    'Geolocator',
    'location',
    'Permission.location',
    'image_picker',
    'FilePicker',
    'file_picker',
    'photo_picker',
    'external_storage',
    'READ_EXTERNAL_STORAGE',
    'WRITE_EXTERNAL_STORAGE',
    'File('
  ];

  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      for (final term in searchTerms) {
        if (content.contains(term)) {
          // print file path and lines containing it
          final lines = content.split('\n');
          for (int i = 0; i < lines.length; i++) {
            if (lines[i].contains(term)) {
              print('${entity.path}:${i + 1}: ${lines[i].trim()}');
            }
          }
        }
      }
    }
  });
}
