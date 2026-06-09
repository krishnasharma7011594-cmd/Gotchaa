import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/models/chat_models.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'chat_components.dart';

class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    required this.msg,
    required this.isMe,
    required this.onLongPress,
    required this.onTap,
    required this.onMediaTap,
    required this.decryptFn,
    required this.checkCacheFn,
    required this.onExpired,
    super.key,
    this.isSelected = false,
    this.selectionModeActive = false,
    this.translation,
    this.userAvatar,
    this.sharedSecret,
    this.onReactionAdd,
  });
  final MessageModel msg;
  final bool isMe;
  final bool isSelected;
  final bool selectionModeActive;
  final String? translation;
  final String? userAvatar;
  final crypto.SecretKey? sharedSecret;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final Function(String, {required bool isVideo}) onMediaTap;
  final Future<String> Function(String, String) decryptFn;
  final String? Function(String) checkCacheFn;
  final VoidCallback onExpired;
  final Function(String emoji)? onReactionAdd;

  void _showReactionPicker(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Center(
        child: FadeInUp(
          duration: const Duration(milliseconds: 200),
          from: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(32),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 30,
                    spreadRadius: 10),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: ['❤️', '😂', '😮', '😢', '🙏', '👍']
                  .map((emoji) => GestureDetector(
                        onTap: () {
                          onReactionAdd?.call(emoji);
                          Navigator.pop(context);
                          HapticFeedback.lightImpact();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 28)),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final radius = themeState.messageCornerRadius;

    if (msg.isDeletedForEveryone || msg.type == 'deleted') {
      return _buildDeletedMessage(context);
    }

    final isExpired =
        msg.expiresAt != null && msg.expiresAt!.isBefore(DateTime.now());
    if (isExpired) return const GhostMessageWidget();

    return Material(
      color: isSelected
          ? AppColors.electricBlue.withOpacity(0.15)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onLongPress();
          _showReactionPicker(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMe && userAvatar != null) _buildAvatar(),
                    _buildContent(context, themeState.currentTheme),
                  ],
                ),
                if (msg.reactions != null && msg.reactions!.isNotEmpty)
                  _buildReactions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8, bottom: 4),
        child: CachedNetworkImage(
          imageUrl: userAvatar!,
          imageBuilder: (context, imageProvider) => CircleAvatar(
            radius: 14,
            backgroundImage: imageProvider,
          ),
          placeholder: (context, url) => const CircleAvatar(
              radius: 14, child: Icon(Icons.person, size: 14)),
          errorWidget: (context, url, error) => const CircleAvatar(
              radius: 14, child: Icon(Icons.person, size: 14)),
        ),
      );

  Widget _buildContent(BuildContext context, GotchaaThemeData theme) {
    final radius = theme.cornerRadius;
    final otherBubbleColor = theme.bubbleThem;
    final otherTextColor = theme.textPrimary;
    final timeColor = theme.textSecondary;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? theme.bubbleMe : otherBubbleColor,
          gradient: isMe
              ? (theme.type == ThemeType.gotchaaDark ||
                      theme.type == ThemeType.gotchaaLight
                  ? AppColors.brandGradient
                  : null)
              : null,
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(radius),
            topEnd: Radius.circular(radius),
            bottomStart: Radius.circular(isMe ? radius : 6),
            bottomEnd: Radius.circular(isMe ? 6 : radius),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
          border: isMe
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.2),
                  width: 0.5,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (msg.type == 'image')
              const Icon(Icons.image_not_supported_rounded,
                  color: Colors.white24, size: 40)
            else
              msg.isEncrypted
                  ? EncryptedTextWidget(
                      messageId: msg.id,
                      encryptedText: msg.text,
                      sharedSecret: sharedSecret,
                      decryptFn: decryptFn,
                      checkCacheFn: checkCacheFn,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: isMe ? Colors.white : otherTextColor,
                        height: 1.3,
                      ),
                    )
                  : Text(
                      msg.text,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: isMe ? Colors.white : otherTextColor,
                        height: 1.3,
                      ),
                    ),
            if (translation != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isMe ? Colors.black : AppColors.electricBlue)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.translate,
                          size: 10,
                          color: isMe ? Colors.white70 : AppColors.electricBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Translated',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color:
                                isMe ? Colors.white70 : AppColors.electricBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      translation!,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: isMe
                            ? Colors.white.withOpacity(0.9)
                            : otherTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.timestamp != null
                      ? DateFormat('HH:mm').format(msg.timestamp!)
                      : '--:--',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : timeColor,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.status == 'sent'
                        ? Icons.done_rounded
                        : Icons.done_all_rounded,
                    size: 14,
                    color: msg.status == 'read'
                        ? const Color(0xFF3DDEC8)
                        : Colors.white70,
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactions() => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Wrap(
          spacing: 4,
          children: msg.reactions!.entries
              .map((e) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.05), width: 0.5),
                    ),
                    child: Text(e.value, style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
        ),
      );

  Widget _buildDeletedMessage(BuildContext context) => Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block_flipped, size: 14, color: Colors.white38),
              const SizedBox(width: 8),
              Text(
                context.tr('chat_deleted_notice'),
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.white38),
              ),
            ],
          ),
        ),
      );
}
