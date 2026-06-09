import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class VoiceMessageService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordPath;

  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final Directory tempDir = await getTemporaryDirectory();
      final String path = '${tempDir.path}/voice_${const Uuid().v4()}.m4a';
      _currentRecordPath = path;

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
    }
  }

  Future<String?> stopRecordingAndUpload(String chatId) async {
    final String? path = await _audioRecorder.stop();
    if (path != null && File(path).existsSync()) {
      final File audioFile = File(path);
      final String fileName = 'voice_${const Uuid().v4()}.m4a';
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('chats')
          .child(chatId)
          .child('voice_messages')
          .child(fileName);

      final bytes = await audioFile.readAsBytes();

      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'audio/m4a'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Cleanup local file
      await audioFile.delete();
      
      return downloadUrl;
    }
    return null;
  }

  Future<void> cancelRecording() async {
    final String? path = await _audioRecorder.stop();
    if (path != null && File(path).existsSync()) {
      File(path).deleteSync();
    }
    _currentRecordPath = null;
  }

  Future<void> dispose() async {
    await _audioRecorder.dispose();
  }
}
