import 'package:firebase_performance/firebase_performance.dart';

/// Custom Firebase Performance traces for key user journeys.
class GotchaaPerformanceTraces {
  GotchaaPerformanceTraces._();
  static final GotchaaPerformanceTraces instance = GotchaaPerformanceTraces._();

  Trace? _feedTrace;
  Trace? _chatTrace;
  Trace? _vibetalkTrace;
  Trace? _uploadTrace;

  Future<void> startFeedLoad() async {
    _feedTrace = FirebasePerformance.instance.newTrace('feed_load');
    await _feedTrace!.start();
  }

  Future<void> stopFeedLoad() async {
    await _feedTrace?.stop();
    _feedTrace = null;
  }

  Future<void> startChatOpen() async {
    _chatTrace = FirebasePerformance.instance.newTrace('chat_open');
    await _chatTrace!.start();
  }

  Future<void> stopChatOpen() async {
    await _chatTrace?.stop();
    _chatTrace = null;
  }

  Future<void> startVibeTalkMatch() async {
    _vibetalkTrace = FirebasePerformance.instance.newTrace('vibetalk_match');
    await _vibetalkTrace!.start();
  }

  Future<void> stopVibeTalkMatch() async {
    await _vibetalkTrace?.stop();
    _vibetalkTrace = null;
  }

  Future<void> startImageUpload({String kind = 'image'}) async {
    _uploadTrace = FirebasePerformance.instance.newTrace('image_upload_$kind');
    await _uploadTrace!.start();
  }

  Future<void> stopImageUpload() async {
    await _uploadTrace?.stop();
    _uploadTrace = null;
  }
}
