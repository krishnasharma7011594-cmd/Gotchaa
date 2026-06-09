import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search files', () {
    final root = Directory('lib');
    final files = root.listSync(recursive: true).whereType<File>();
    
    final searchTerms = [
      'Permission.location',
      'Permission.storage',
      'Permission.photos',
      'image_picker',
      'picker',
      'Geolocator',
      'putFile',
      'File(',
    ];
    
    print('Found files checking...');
    for (final file in files) {
      if (!file.path.endsWith('.dart')) continue;
      final content = file.readAsStringSync();
      final matches = <String>[];
      for (final term in searchTerms) {
        if (content.contains(term)) {
          matches.add(term);
        }
      }
      if (matches.isNotEmpty) {
        print('${file.path}: matches $matches');
      }
    }
  });
}
