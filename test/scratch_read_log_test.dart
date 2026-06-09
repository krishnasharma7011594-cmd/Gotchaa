import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('read transcript user messages', () {
    final file = File(
        r'C:\Users\hp\.gemini\antigravity\brain\a25eaee5-1f98-4089-9e5f-a34b2ba27a12\.system_generated\logs\transcript.jsonl');
    if (!file.existsSync()) {
      print('File not found at ${file.path}');
      return;
    }

    final lines = file.readAsLinesSync();
    print('Total lines in transcript: ${lines.length}');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('"type":"USER_INPUT"')) {
        try {
          final parsed = jsonDecode(line);
          final content = parsed['content'] ?? '';
          if (content.contains('Dangerous Permissions')) {
            print(
                '--- User Message with Dangerous Permissions at index $i ---');
            print(content);
          }
        } catch (e) {
          // ignore
        }
      }
    }
  });
}
