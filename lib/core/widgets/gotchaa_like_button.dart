import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/explore/presentation/screens/likes_screen.dart';
import '../providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/social_providers.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

class GotchaaLikeButton extends ConsumerStatefulWidget {
  const GotchaaLikeButton({
    required this.contentId,
    required this.contentType,
    this.parentId,
    this.initialCount = 0,
    this.ownerId,
    this.ownerName,
    this.iconSize = 24,
    this.textSize = 14,
    this.showCount = true,
    this.onChanged,
    super.key,
  });

  final String contentId;
  final String contentType; // 'posts', 'vybz', 'comments'
  final String? parentId;
  final int initialCount;
  final String? ownerId;
  final String? ownerName;
  final double iconSize;
  final double textSize;
  final bool showCount;
  final Function(bool isLiked, int newCount)? onChanged;

  @override
  ConsumerState<GotchaaLikeButton> createState() => _GotchaaLikeButtonState();
}

class _GotchaaLikeButtonState extends ConsumerState<GotchaaLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;

  bool? _isLikedLocal;
  int _likesCountLocal = 0;
  final bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _likesCountLocal = widget.initialCount;
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 500));
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final myUser = ref.read(currentUserProfileProvider).value;
    final myUid = ref.read(authStateProvider).value?.uid;
    if (myUid == null || myUser == null) return;

    final bool currentlyLiked = _isLikedLocal ?? false;
    final bool nextLikedState = !currentlyLiked;

    // Optimistic UI update
    setState(() {
      _isLikedLocal = nextLikedState;
      _likesCountLocal += nextLikedState ? 1 : -1;
    });

    if (widget.onChanged != null) {
      widget.onChanged!(nextLikedState, _likesCountLocal);
    }

    // Log engagement
    AnalyticsService.logContentLiked(
      contentType: widget.contentType,
      isLiked: nextLikedState,
    );

    // Feedback
    if (nextLikedState) {
      HapticFeedback.lightImpact();
      _animController.forward(from: 0);
      _confettiController.play();
    } else {
      HapticFeedback.selectionClick();
    }

    try {
      final socialRepo = ref.read(socialRepositoryProvider);
      if (nextLikedState) {
        await socialRepo.likeContent(
          contentId: widget.contentId,
          uid: myUid,
          contentType: widget.contentType,
          parentId: widget.parentId,
          contentOwnerId: widget.ownerId,
          contentOwnerName: widget.ownerName,
          likerName: myUser.displayName,
          likerPhotoUrl: myUser.photoUrl,
        );
      } else {
        await socialRepo.unlikeContent(
          contentId: widget.contentId,
          uid: myUid,
          contentType: widget.contentType,
          parentId: widget.parentId,
        );
      }
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          _isLikedLocal = currentlyLiked;
          _likesCountLocal += currentlyLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update like. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(authStateProvider).value?.uid ?? '';

    // Watch the real-time status to sync with backend
    final likedAsync = ref.watch(isContentLikedProvider((
      contentId: widget.contentId,
      uid: myUid,
      contentType: widget.contentType,
      parentId: widget.parentId,
    )));

    // Use likedAsync as source of truth, but allow _isLikedLocal to override it for optimistic UI
    final isLiked = _isLikedLocal ?? likedAsync.value ?? false;

    // Reset optimistic state if the backend has caught up
    if (_isLikedLocal != null &&
        likedAsync.hasValue &&
        likedAsync.value == _isLikedLocal) {
      // Clear the local override in the next frame to avoid "setState during build"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isLikedLocal = null);
      });
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.red, Colors.pink, Colors.orange],
              createParticlePath: (size) {
                final path = Path();
                path.addOval(Rect.fromCircle(center: Offset.zero, radius: 2));
                return path;
              },
            ),
            ScaleTransition(
              scale: _scaleAnimation,
              child: IconButton(
                onPressed: _toggleLike,
                icon: Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  color: isLiked ? Colors.red : context.iconSecondary,
                  size: widget.iconSize,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
            ),
          ],
        ),
        if (widget.showCount) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GotchaaLikesScreen(
                    contentId: widget.contentId,
                    contentType: widget.contentType,
                    parentId: widget.parentId,
                  ),
                ),
              );
            },
            child: Text(
              '$_likesCountLocal',
              style: GoogleFonts.outfit(
                fontSize: widget.textSize,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
