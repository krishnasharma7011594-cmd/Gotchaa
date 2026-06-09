import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/providers/vybz_providers.dart';
import '../../../../core/utils/video_manager.dart';

class VybzVideoPlayer extends ConsumerStatefulWidget {
  const VybzVideoPlayer({required this.videoUrl, required this.vybzId, super.key});
  final String videoUrl;
  final String vybzId;

  @override
  ConsumerState<VybzVideoPlayer> createState() => _VybzVideoPlayerState();
}

class _VybzVideoPlayerState extends ConsumerState<VybzVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final controller = await FeedVideoManager().getOrCreateController(widget.videoUrl);
    if (!mounted) return;
    setState(() {
      _controller = controller;
      _isInitialized = true;
    });

    // Autoplay if this video is currently active in the page controller
    if (ref.read(activeVybzIdProvider) == widget.vybzId) {
      FeedVideoManager().play(widget.videoUrl);
    }
  }

  @override
  void didUpdateWidget(VybzVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      setState(() {
        _isInitialized = false;
        _controller = null;
      });
      _initController();
    }
  }

  @override
  void dispose() {
    // ⚠️ CRITICAL: Do NOT dispose the controller here as the lifecycle 
    // is entirely controlled by FeedVideoManager pool to prevent OOM/ANRs
    super.dispose();
  }

  void _handleTap() {
    final controller = _controller;
    if (controller == null || !_isInitialized) return;

    if (controller.value.isPlaying) {
      FeedVideoManager().pause(widget.videoUrl);
    } else {
      FeedVideoManager().play(widget.videoUrl);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    ref.listen(activeVybzIdProvider, (previous, next) {
      if (next == widget.vybzId) {
        if (_isInitialized && controller != null) {
          FeedVideoManager().play(widget.videoUrl);
        }
      } else {
        if (controller != null && controller.value.isPlaying) {
          controller.pause();
        }
      }
    });

    if (!_isInitialized || controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white24),
        ),
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              if (!value.isPlaying) {
                return Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.5),
                  ).animate().scale(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
