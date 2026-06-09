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
    try {
      _feedTrace = FirebasePerformance.instance.newTrace('feed_load');
      await _feedTrace!.start();
    } catch (_) {}
  }

  Future<void> stopFeedLoad() async {
    try {
      await _feedTrace?.stop();
    } catch (_) {} finally {
      _feedTrace = null;
    }
  }

  Future<void> startChatOpen() async {
    try {
      _chatTrace = FirebasePerformance.instance.newTrace('chat_open');
      await _chatTrace!.start();
    } catch (_) {}
  }

  Future<void> stopChatOpen() async {
    try {
      await _chatTrace?.stop();
    } catch (_) {} finally {
      _chatTrace = null;
    }
  }

  Future<void> startVibeTalkMatch() async {
    try {
      _vibetalkTrace = FirebasePerformance.instance.newTrace('vibetalk_match');
      await _vibetalkTrace!.start();
    } catch (_) {}
  }

  Future<void> stopVibeTalkMatch() async {
    try {
      await _vibetalkTrace?.stop();
    } catch (_) {} finally {
      _vibetalkTrace = null;
    }
  }

  Future<void> startImageUpload({String kind = 'image'}) async {
    try {
      _uploadTrace = FirebasePerformance.instance.newTrace('image_upload_$kind');
      await _uploadTrace!.start();
    } catch (_) {}
  }

  Future<void> stopImageUpload() async {
    try {
      await _uploadTrace?.stop();
    } catch (_) {} finally {
      _uploadTrace = null;
    }
  }
}
