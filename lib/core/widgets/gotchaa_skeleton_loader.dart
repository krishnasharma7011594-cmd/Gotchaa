import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// Shimmer skeleton loading states for GOTCHAA.
///
/// Use these while async data is loading to give the UI a polished feel
/// instead of showing a bare [CircularProgressIndicator].
///
/// Available skeletons:
///   - [GotchaaSkeletonLoader.feed]         — post card list
///   - [GotchaaSkeletonLoader.chatList]     — chat conversation list
///   - [GotchaaSkeletonLoader.notification] — notification items
///   - [GotchaaSkeletonLoader.profile]      — profile header + grid
///   - [GotchaaSkeletonLoader.card]         — generic content card

class GotchaaSkeletonLoader extends StatelessWidget {
  const GotchaaSkeletonLoader.feed({super.key, this.itemCount = 3})
      : type = _SkeletonType.feed;

  const GotchaaSkeletonLoader.chatList({super.key, this.itemCount = 5})
      : type = _SkeletonType.chatList;

  const GotchaaSkeletonLoader.notification({super.key, this.itemCount = 4})
      : type = _SkeletonType.notification;

  const GotchaaSkeletonLoader.profile({super.key, this.itemCount = 6})
      : type = _SkeletonType.profile;

  const GotchaaSkeletonLoader.card({super.key, this.itemCount = 2})
      : type = _SkeletonType.card;
  final _SkeletonType type;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final baseColor = context.shimmerBase;
    final highlightColor = context.shimmerHighlight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: itemCount,
        itemBuilder: (context, index) => _buildSkeleton(context),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    switch (type) {
      case _SkeletonType.feed:
        return _FeedSkeleton();
      case _SkeletonType.chatList:
        return _ChatListSkeleton();
      case _SkeletonType.notification:
        return _NotificationSkeleton();
      case _SkeletonType.profile:
        return _ProfileSkeleton();
      case _SkeletonType.card:
        return _CardSkeleton();
    }
  }
}

enum _SkeletonType { feed, chatList, notification, profile, card }

// ── Feed Skeleton ──────────────────────────────────────────────────────────

class _FeedSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                _Circle(size: 40),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bar(width: 120, height: 14),
                    SizedBox(height: 6),
                    _Bar(width: 80, height: 11),
                  ],
                ),
              ],
            ),
            SizedBox(height: 14),
            // Text lines
            _Bar(width: double.infinity, height: 13),
            SizedBox(height: 6),
            _Bar(width: double.infinity, height: 13),
            SizedBox(height: 6),
            _Bar(width: 160, height: 13),
            SizedBox(height: 14),
            // Image placeholder
            _Bar(width: double.infinity, height: 180, radius: 12),
            SizedBox(height: 14),
            // Action row
            Row(
              children: [
                _Bar(width: 60, height: 12),
                SizedBox(width: 16),
                _Bar(width: 60, height: 12),
                Spacer(),
                _Bar(width: 40, height: 12),
              ],
            ),
          ],
        ),
      );
}

// ── Chat List Skeleton ─────────────────────────────────────────────────────

class _ChatListSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            _Circle(size: 56),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Bar(width: 130, height: 14),
                      Spacer(),
                      _Bar(width: 45, height: 11),
                    ],
                  ),
                  SizedBox(height: 8),
                  _Bar(width: double.infinity, height: 12),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Notification Skeleton ──────────────────────────────────────────────────

class _NotificationSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Circle(size: 44),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bar(width: double.infinity, height: 13),
                  SizedBox(height: 6),
                  _Bar(width: 200, height: 13),
                  SizedBox(height: 6),
                  _Bar(width: 80, height: 10),
                ],
              ),
            ),
            SizedBox(width: 12),
            _Bar(width: 48, height: 36, radius: 8),
          ],
        ),
      );
}

// ── Profile Skeleton ───────────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const _Circle(size: 80),
            const SizedBox(height: 12),
            const _Bar(width: 140, height: 16),
            const SizedBox(height: 8),
            const _Bar(width: 100, height: 12),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Bar(width: 60, height: 12),
                SizedBox(width: 24),
                _Bar(width: 60, height: 12),
                SizedBox(width: 24),
                _Bar(width: 60, height: 12),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              children: List.generate(
                6,
                (_) => const _Bar(
                    width: double.infinity, height: double.infinity, radius: 0),
              ),
            ),
          ],
        ),
      );
}

// ── Generic Card Skeleton ──────────────────────────────────────────────────

class _CardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            _Circle(size: 48),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bar(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  _Bar(width: 160, height: 12),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Primitive shapes ──────────────────────────────────────────────────────

class _Bar extends StatelessWidget {
  const _Bar({
    required this.width,
    required this.height,
    this.radius = 8,
  });
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width == double.infinity ? null : width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );
}
