import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../firebase/performance_traces.dart';
import '../media/media_compression_service.dart';
import '../media/upload_result.dart';
import '../moderation/csam_hash_service.dart';

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadProfilePicture(
    XFile file,
    String uid, {
    UploadProgressCallback? onProgress,
  }) async {
    final ref = _storage.ref().child('profile_pictures').child('$uid.jpg');
    final bytes = await file.readAsBytes();
    final compressed = await MediaCompressionService.instance.compressImageBytes(
      Uint8List.fromList(bytes),
      kind: MediaUploadKind.profile,
    );
    await _csamGate(compressed.fullBytes);
    await GotchaaPerformanceTraces.instance.startImageUpload(kind: 'profile');
    try {
      return await _putAndGetUrl(
        ref,
        compressed.fullBytes,
        SettableMetadata(contentType: 'image/jpeg'),
        onProgress: onProgress,
      );
    } finally {
      await GotchaaPerformanceTraces.instance.stopImageUpload();
    }
  }

  Future<MediaUploadResult> uploadPostImage(
    XFile file,
    String uid, {
    UploadProgressCallback? onProgress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fullRef = _storage.ref().child('posts').child(uid).child('$timestamp.jpg');
    final thumbRef = _storage.ref().child('posts').child(uid).child('${timestamp}_thumb.jpg');

    final bytes = await file.readAsBytes();
    final compressed = await MediaCompressionService.instance.compressImageBytes(
      Uint8List.fromList(bytes),
      kind: MediaUploadKind.post,
    );
    await _csamGate(compressed.fullBytes);

    await GotchaaPerformanceTraces.instance.startImageUpload(kind: 'post');
    try {
      final url = await _putAndGetUrl(
        fullRef,
        compressed.fullBytes,
        SettableMetadata(contentType: 'image/jpeg'),
        onProgress: onProgress,
      );
      String? thumbUrl;
      if (compressed.thumbnailBytes != null) {
        thumbUrl = await _putAndGetUrl(
          thumbRef,
          compressed.thumbnailBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }
      return MediaUploadResult(url: url, thumbnailUrl: thumbUrl);
    } finally {
      await GotchaaPerformanceTraces.instance.stopImageUpload();
    }
  }

  Future<String> uploadVideo(
    XFile file,
    String userId, {
    UploadProgressCallback? onProgress,
  }) async {
    final compressedPath = await MediaCompressionService.instance.compressVideoPath(file.path);
    final uploadFile = compressedPath != null ? XFile(compressedPath) : file;
    final fileName = '${_uuid.v4()}.mp4';
    final ref = _storage.ref().child('vybz').child(userId).child(fileName);
    final bytes = await uploadFile.readAsBytes();

    await GotchaaPerformanceTraces.instance.startImageUpload(kind: 'video');
    try {
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'video/mp4'),
      );
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((s) {
          final total = s.totalBytes;
          if (total > 0) onProgress(s.bytesTransferred / total);
        });
      }
      final taskSnapshot = await uploadTask;
      if (taskSnapshot.state == TaskState.error || taskSnapshot.state == TaskState.canceled) {
        throw Exception('Upload failed or was canceled');
      }
      return taskSnapshot.ref.getDownloadURL();
    } finally {
      await GotchaaPerformanceTraces.instance.stopImageUpload();
    }
  }

  Future<String> uploadImage(
    XFile file,
    String userId, {
    String folder = 'profile',
    UploadProgressCallback? onProgress,
  }) async {
    final fileName = _uuid.v4();
    final ref = _storage.ref().child(folder).child(userId).child(fileName);
    final bytes = await file.readAsBytes();
    final kind = folder == 'stories'
        ? MediaUploadKind.story
        : (folder == 'posts' ? MediaUploadKind.post : MediaUploadKind.profile);
    final compressed = await MediaCompressionService.instance.compressImageBytes(
      Uint8List.fromList(bytes),
      kind: kind,
    );
    if (folder != 'vybz') await _csamGate(compressed.fullBytes);
    return _putAndGetUrl(
      ref,
      compressed.fullBytes,
      SettableMetadata(contentType: 'image/jpeg'),
      onProgress: onProgress,
    );
  }

  Future<String> uploadChatMedia(
    XFile file,
    String chatId,
    String type, {
    UploadProgressCallback? onProgress,
  }) async {
    final extension = type == 'video' ? 'mp4' : (type == 'voice' ? 'm4a' : 'jpg');
    final fileName = '${_uuid.v4()}.$extension';
    final ref = _storage.ref().child('chats').child(chatId).child(type).child(fileName);
    final metadata = SettableMetadata(
      contentType: type == 'video' ? 'video/mp4' : (type == 'voice' ? 'audio/mpeg' : 'image/jpeg'),
    );

    Uint8List bytes;
    if (type == 'video') {
      final path = await MediaCompressionService.instance.compressVideoPath(file.path);
      bytes = Uint8List.fromList(await XFile(path ?? file.path).readAsBytes());
    } else {
      final raw = await file.readAsBytes();
      if (type == 'image') {
        final c = await MediaCompressionService.instance.compressImageBytes(
          Uint8List.fromList(raw),
          kind: MediaUploadKind.chat,
        );
        bytes = c.fullBytes;
        await _csamGate(bytes);
      } else {
        bytes = Uint8List.fromList(raw);
      }
    }

    return _putAndGetUrl(ref, bytes, metadata, onProgress: onProgress);
  }

  Future<void> _csamGate(Uint8List bytes) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final result = await CsamHashService.instance.checkImageBytes(bytes, userId: uid);
    if (result.isBlocked) {
      throw Exception('Upload blocked for safety review. Your account has been suspended.');
    }
  }

  Future<String> _putAndGetUrl(
    Reference ref,
    Uint8List bytes,
    SettableMetadata metadata, {
    UploadProgressCallback? onProgress,
  }) async {
    final uploadTask = ref.putData(bytes, metadata);
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((s) {
        final total = s.totalBytes;
        if (total > 0) onProgress(s.bytesTransferred / total);
      });
    }
    final taskSnapshot = await uploadTask;
    if (taskSnapshot.state == TaskState.error || taskSnapshot.state == TaskState.canceled) {
      throw Exception('Upload failed or was canceled');
    }
    return taskSnapshot.ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}
