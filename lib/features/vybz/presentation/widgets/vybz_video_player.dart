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
    if (!mounted) return;
    
    setState(() {
      _isInitialized = false;
      _controller = null;
    });

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      
      await controller.initialize();
      await controller.setLooping(true);
      
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });

      // Autoplay if active
      if (ref.read(activeVybzIdProvider) == widget.vybzId) {
        _controller?.play();
      }
    } catch (e) {
      debugPrint('Vybz init error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true; // Mark as done to show error UI
          _controller = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
      controller.pause();
    } else {
      controller.play();
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
          controller.play();
        }
      } else {
        if (controller != null && controller.value.isPlaying) {
          controller.pause();
        }
      }
    });

    // Still initializing — show loading
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white54),
              const SizedBox(height: 12),
              Text('Loading Vybz...', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    // Initialized but controller is null = load failed
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 48),
              const SizedBox(height: 12),
              Text('Could not load video', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _initController,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                label: Text('Retry', style: GoogleFonts.outfit(color: Colors.white70)),
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
