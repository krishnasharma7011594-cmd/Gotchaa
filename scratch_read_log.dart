import 'dart:convert';
import 'dart:io';

void main() {
  final file = File(
      r'C:\Users\hp\.gemini\antigravity\brain\a25eaee5-1f98-4089-9e5f-a34b2ba27a12\.system_generated\logs\transcript.jsonl');
  if (!file.existsSync()) {
    print('File not found at ${file.path}');
    return;
  }

  final lines = file.readAsLinesSync();
  print('Total lines in transcript: ${lines.length}');

  for (var i = lines.length - 1; i >= 0; i--) {
    final line = lines[i];
    if (line.contains('Dangerous Permissions')) {
      print('--- Found in line $i ---');
      try {
        final parsed = jsonDecode(line);
        final content = parsed['content'] ?? '';
        print(content);
      } catch (e) {
        print('Error parsing: $e');
        print(line);
      }
      break;
    }
  }
}
