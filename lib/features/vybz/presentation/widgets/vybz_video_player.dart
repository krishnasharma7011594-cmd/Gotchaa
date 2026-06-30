import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import 'package:visibility_detector/visibility_detector.dart';
import '../../../../core/providers/vybz_providers.dart';
import '../../../../core/services/audio_focus_manager.dart';

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
  String? _errorMessage;

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
      _errorMessage = null;
    });

    try {
      if (widget.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl.trim()),
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        },
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
          _errorMessage = e.toString();
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

    // Listen to active Vybz ID changes
    ref.listen(activeVybzIdProvider, (previous, next) {
      if (next == widget.vybzId) {
        if (_isInitialized && controller != null) {
          // When this Vybz becomes active, request audio focus
          ref
              .read(audioFocusManagerProvider)
              .requestAudioFocus('vybz_${widget.vybzId}', AudioRequester.vybz);

          // Only play if focus is granted (this will be handled by the focus provider listener)
          if (ref.read(isVybzAudioAllowedProvider)) {
            controller.play();
          }
        }
      } else {
        if (controller != null) {
          controller.pause();
          // Release focus when no longer active
          ref
              .read(audioFocusManagerProvider)
              .releaseAudioFocus('vybz_${widget.vybzId}');
        }
      }
    });

    // Listen to focus changes to pause/resume audio
    ref.listen(isVybzAudioAllowedProvider, (previous, isAllowed) {
      if (ref.read(activeVybzIdProvider) == widget.vybzId &&
          _isInitialized &&
          controller != null) {
        if (isAllowed) {
          if (!controller.value.isPlaying) controller.play();
        } else {
          if (controller.value.isPlaying) controller.pause();
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
              Text('Loading Vybz...',
                  style:
                      GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    // Initialized but controller is null = load failed
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white24, size: 48),
              const SizedBox(height: 16),
              Text('Could not load video',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_errorMessage ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 20),
              // Debug URL view
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.videoUrl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.firaCode(
                        color: Colors.white24, fontSize: 10)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initController,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return VisibilityDetector(
      key: Key('vybz_${widget.vybzId}'),
      onVisibilityChanged: (info) {
        final visibleFraction = info.visibleFraction;
        final isActive = ref.read(activeVybzIdProvider) == widget.vybzId;

        if (visibleFraction < 0.1) {
          // Video is mostly invisible, pause and release focus
          if (controller.value.isPlaying) {
            controller.pause();
          }
          if (isActive) {
            ref
                .read(audioFocusManagerProvider)
                .releaseAudioFocus('vybz_${widget.vybzId}');
          }
        } else if (visibleFraction > 0.8 && isActive) {
          // Video is highly visible and active, request focus and play
          ref
              .read(audioFocusManagerProvider)
              .requestAudioFocus('vybz_${widget.vybzId}', AudioRequester.vybz);
          if (ref.read(isVybzAudioAllowedProvider)) {
            controller.play();
          }
        }
      },
      child: GestureDetector(
        onTap: _handleTap,
        onDoubleTap: _handleDoubleTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width > 0
                    ? controller.value.size.width
                    : 1080,
                height: controller.value.size.height > 0
                    ? controller.value.size.height
                    : 1920,
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
                    .fadeOut(begin: 1, delay: 500.ms, duration: 300.ms),
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
      ),
    );
  }
}
