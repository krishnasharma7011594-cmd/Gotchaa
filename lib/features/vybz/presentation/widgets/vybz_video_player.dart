import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/providers/vybz_providers.dart';
import '../../../../core/utils/video_manager.dart';

class VybzVideoPlayer extends ConsumerStatefulWidget {
  const VybzVideoPlayer({
    required this.videoUrl,
    required this.vybzId,
    this.onDoubleTap,
    super.key,
  });
  final String videoUrl;
  final String vybzId;
  final VoidCallback? onDoubleTap;

  @override
  ConsumerState<VybzVideoPlayer> createState() => _VybzVideoPlayerState();
}

class _VybzVideoPlayerState extends ConsumerState<VybzVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    // 💡 IMPROVED: Using a more robust initialization with skip cache if possible
    final controller =
        await FeedVideoManager().getOrCreateController(widget.videoUrl);
    if (!mounted) return;
    setState(() {
      _controller = controller;
      _isInitialized = true;
    });

    // Autoplay if this video is currently active in the page controller
    if (mounted && ref.read(activeVybzIdProvider) == widget.vybzId) {
      FeedVideoManager().play(widget.videoUrl);
      setState(() {}); // Force rebuild to show video
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

  void _handleDoubleTap() {
    if (widget.onDoubleTap != null) {
      widget.onDoubleTap!();
    }
    setState(() => _showHeart = true);
    HapticFeedback.heavyImpact();
    
    // Auto-hide heart after animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeart = false);
    });
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

    if (!_isInitialized || controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white24),
              const SizedBox(height: 12),
              Text(
                'Loading Vybz...',
                style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width > 0 ? controller.value.size.width : 1080,
              height: controller.value.size.height > 0 ? controller.value.size.height : 1920,
              child: VideoPlayer(controller),
            ),
          ),
          
          // Large Pop-up Heart for Double Tap
          if (_showHeart)
            Center(
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white70,
                size: 110,
              )
                  .animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeOut(begin: 1.0, delay: 500.ms, duration: 300.ms),
            ),

          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              if (!value.isPlaying && !_showHeart) {
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
