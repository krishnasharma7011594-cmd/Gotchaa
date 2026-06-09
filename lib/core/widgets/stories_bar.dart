import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/create/presentation/screens/camera_screen.dart';
import '../providers/profile_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class StoriesBar extends ConsumerStatefulWidget {
  const StoriesBar({super.key, this.isExplore = false});
  final bool isExplore;

  @override
  ConsumerState<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends ConsumerState<StoriesBar> {
  bool _isExpanded = false; // Closed by default to save screen space

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isExplore ? 'Trending Creators' : 'Recent Updates',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      if (!widget.isExplore)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.electricBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '5 New',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: AppColors.electricBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: context.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            child: SizedBox(
              height: _isExpanded ? 105 : 0,
              child: _isExpanded
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: widget.isExplore ? 6 : 7,
                      itemBuilder: (context, index) {
                        if (!widget.isExplore && index == 0) {
                          return _buildYourStory(context, ref);
                        }
                        final dataIndex = widget.isExplore ? index : index - 1;
                        return _buildStoryItem(
                            context, dataIndex, widget.isExplore);
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      );

  Widget _buildYourStory(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const CameraScreen())),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 32,
                  backgroundColor: context.shimmerBase,
                  backgroundImage: profileAsync.hasValue &&
                          profileAsync.value?.photoUrl.isNotEmpty == true
                      ? CachedNetworkImageProvider(profileAsync.value!.photoUrl)
                      : null,
                  child: (!profileAsync.hasValue ||
                          profileAsync.value?.photoUrl.isEmpty == true)
                      ? Icon(Icons.person_rounded,
                          color: context.iconSecondary, size: 28)
                      : null,
                ),
                // Instagram style bottom-right + button
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.bg, width: 2),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your Vybz',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(BuildContext context, int index, bool isExplore) {
    // These were identified as "fake" data by the user.
    // In a real app, these would be fetched from Firestore.
    // For now, we will return an empty list or only the current user's story.
    return const SizedBox.shrink();
  }
}
