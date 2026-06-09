import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/vybz/presentation/widgets/vybz_video_player.dart';
import '../models/vybz_model.dart';
import '../theme/app_colors.dart';

class VybzCard extends ConsumerWidget {
  const VybzCard({required this.vybz, super.key});
  final VybzModel vybz;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      height: 450,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricBlue.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Video Player
            VybzVideoPlayer(videoUrl: vybz.videoUrl, vybzId: vybz.id),

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),

            // Vybz Badge
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'VYBZ',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Creator Info & Caption
            Positioned(
              bottom: 16,
              left: 16,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: vybz.creatorPhoto.isNotEmpty
                            ? CachedNetworkImageProvider(vybz.creatorPhoto)
                            : null,
                        child: vybz.creatorPhoto.isEmpty
                            ? const Icon(Icons.person, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '@${vybz.creatorUsername}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vybz.caption,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Right Actions
            Positioned(
              bottom: 16,
              right: 12,
              child: Column(
                children: [
                  _VybzAction(
                    icon: Icons.favorite_rounded,
                    label: '${vybz.likesCount}',
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  _VybzAction(
                    icon: Icons.chat_bubble_rounded,
                    label: '${vybz.commentsCount}',
                  ),
                  const SizedBox(height: 16),
                  const _VybzAction(
                    icon: Icons.send_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}

class _VybzAction extends StatelessWidget {

  const _VybzAction({required this.icon, this.label, this.color});
  final IconData icon;
  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color ?? Colors.white, size: 24),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
}

