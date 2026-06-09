import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/chat_providers.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ChatAppBar({
    required this.recipientUid,
    required this.chatId,
    required this.userName,
    required this.isE2EEReady,
    required this.onTimerTap,
    super.key,
    this.userAvatar,
    this.disappearingDuration,
  });
  final String? recipientUid;
  final String chatId;
  final String? userAvatar;
  final String userName;
  final bool isE2EEReady;
  final Duration? disappearingDuration;
  final VoidCallback onTimerTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenceAsync = recipientUid != null
        ? ref.watch(userPresenceProvider(recipientUid!))
        : null;
    final typingMapAsync = ref.watch(typingProvider(chatId));

    bool isTyping = false;
    if (recipientUid != null) {
      isTyping = typingMapAsync.value?[recipientUid!] ?? false;
    }

    // Presence and last seen UI removed for privacy as requested.

    return AppBar(
      titleSpacing: 0,
      elevation: 1,
      backgroundColor: context.surface,
      title: Row(
        children: [
          CachedNetworkImage(
            imageUrl: userAvatar ?? '',
            imageBuilder: (context, imageProvider) => CircleAvatar(
              radius: 18,
              backgroundColor: context.shimmerBase,
              backgroundImage: imageProvider,
            ),
            placeholder: (context, url) => const CircleAvatar(
              radius: 18,
              child: BlurHash(hash: 'L5H2EC=pPdpWXVJs00QQV_9H00XY'),
            ),
            errorWidget: (context, url, error) => CircleAvatar(
              radius: 18,
              backgroundColor: context.shimmerBase,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                        child: Text(userName,
                            style: GoogleFonts.outfit(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
                if (isTyping)
                  Text(context.tr('chat_typing'),
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
            onPressed: onTimerTap,
            icon: Icon(
                disappearingDuration != null
                    ? Icons.timer
                    : Icons.timer_off_outlined,
                color: disappearingDuration != null
                    ? AppColors.electricBlue
                    : null)),
      ],
    );
  }
}
