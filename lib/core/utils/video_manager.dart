import 'package:video_player/video_player.dart';

class FeedVideoManager {
  factory FeedVideoManager() => _instance;
  FeedVideoManager._internal();
  static final FeedVideoManager _instance = FeedVideoManager._internal();

  // Cache pool mapping: videoUrl -> VideoPlayerController
  final Map<String, VideoPlayerController> _pool = {};

  // LRU eviction queue tracker
  final List<String> _history = [];

  /// Get a cached or freshly initialized controller for the specified URL.
  Future<VideoPlayerController> getOrCreateController(String url) async {
    if (_pool.containsKey(url)) {
      // Update LRU history: move to the end (most recently used)
      _history.remove(url);
      _history.add(url);

      final controller = _pool[url]!;
      if (!controller.value.isInitialized) {
        await controller.initialize();
      }
      return controller;
    }

    // Limit active controllers to maximum 3
    if (_pool.length >= 3) {
      final oldestUrl = _history.isEmpty ? _pool.keys.first : _history.first;
      await _evictController(oldestUrl);
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _pool[url] = controller;
    _history.add(url);

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1.0);
    } catch (e) {
      print('Video init error for $url: $e');
    }
    return controller;
  }

  /// Remove controller from cache, pause, and safely dispose.
  Future<void> _evictController(String url) async {
    final controller = _pool.remove(url);
    _history.remove(url);
    if (controller != null) {
      try {
        await controller.pause();
        await controller.dispose();
      } catch (_) {}
    }
  }

  /// Play the active video and pause all other cached controllers.
  void play(String url) {
    _pool.forEach((key, controller) {
      if (key == url) {
        if (controller.value.isInitialized && !controller.value.isPlaying) {
          controller.play();
        }
      } else {
        if (controller.value.isPlaying) {
          controller.pause();
        }
      }
    });
  }

  /// Pause play for a specific URL.
  void pause(String url) {
    _pool[url]?.pause();
  }

  /// Stop and pause all active players.
  void stop() {
    _pool.forEach((_, controller) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    });
  }

  /// Preload the next video in the queue asynchronously.
  void preload(String url) {
    if (_pool.containsKey(url) || url.isEmpty || !url.startsWith('http'))
      return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    controller.initialize().then((_) {
      if (_pool.length >= 3) {
        final oldestUrl = _history.isEmpty ? _pool.keys.first : _history.first;
        _evictController(oldestUrl);
      }
      _pool[url] = controller;
      _history.add(url);
      controller.setLooping(true);
    }).catchError((_) {
      // Fail silently for network timeouts
    });
  }

  /// Keep compatibility, but let the pool manage destruction
  void onDispose(VideoPlayerController controller) {
    // No-op: Lifecycle managed by pool eviction policy
  }

  /// Clean all active controllers (e.g. leaving the Vybz feed screen)
  void clearAll() {
    _pool.forEach((_, controller) {
      try {
        controller.pause();
        controller.dispose();
      } catch (_) {}
    });
    _pool.clear();
    _history.clear();
  }
}
