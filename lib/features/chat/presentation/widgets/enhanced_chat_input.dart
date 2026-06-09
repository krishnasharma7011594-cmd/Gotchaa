import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/models/chat_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class EnhancedChatInput extends ConsumerStatefulWidget {

  const EnhancedChatInput({
    required this.controller, required this.onSend, required this.onTypingChanged, super.key,
    this.replyingTo,
    this.onCancelReply,
  });
  final TextEditingController controller;
  final Function(String) onSend;
  final Function(String) onTypingChanged;
  final MessageModel? replyingTo;
  final VoidCallback? onCancelReply;

  @override
  ConsumerState<EnhancedChatInput> createState() => _EnhancedChatInputState();
}

class _EnhancedChatInputState extends ConsumerState<EnhancedChatInput> {
  bool _showEmoji = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final isTyping = widget.controller.text.trim().isNotEmpty;
    if (isTyping != _isTyping) {
      setState(() => _isTyping = isTyping);
      widget.onTypingChanged(isTyping ? 'typing' : 'idle');
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _handleSend() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      widget.controller.clear();
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
      onWillPop: () async {
        if (_showEmoji) {
          setState(() => _showEmoji = false);
          return false;
        }
        return true;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyingTo != null) _buildReplyPreview(),
          _buildInputBar(),
          if (_showEmoji) _buildEmojiPicker(),
        ],
      ),
    );

  Widget _buildReplyPreview() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.electricBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to',
                  style: GoogleFonts.outfit(
                    color: AppColors.electricBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.replyingTo!.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: context.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancelReply,
            icon: Icon(Icons.close, color: context.iconSecondary, size: 20),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);

  Widget _buildInputBar() => Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: context.bg,
        border: Border(top: BorderSide(color: context.divider, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Emoji Toggle ──────────────────────────────────────────
          IconButton(
            onPressed: () {
              if (_showEmoji) {
                FocusScope.of(context).requestFocus(FocusNode());
              } else {
                FocusScope.of(context).unfocus();
              }
              setState(() => _showEmoji = !_showEmoji);
            },
            icon: Icon(
              _showEmoji ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
              color: _showEmoji ? AppColors.electricBlue : context.iconSecondary,
              size: 26,
            ),
          ),

          // ── Text Input ────────────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.divider),
              ),
              child: TextField(
                controller: widget.controller,
                maxLines: 5,
                minLines: 1,
                style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: context.tr('chat_type_message'),
                  hintStyle: GoogleFonts.outfit(color: context.textHint, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onTap: () {
                  if (_showEmoji) setState(() => _showEmoji = false);
                },
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Send Button ───────────────────────────────────────────
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isTyping ? AppColors.brandGradient : null,
                color: _isTyping ? null : context.surface,
              ),
              child: Icon(
                Icons.send_rounded,
                color: _isTyping ? Colors.white : context.iconMuted,
                size: 22,
              ),
            ),
          ).animate(target: _isTyping ? 1 : 0).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
        ],
      ),
    );

  Widget _buildEmojiPicker() => SizedBox(
      height: 280,
      child: emoji.EmojiPicker(
        onEmojiSelected: (category, e) {
          widget.controller.text += e.emoji;
        },
        config: emoji.Config(
          height: 280,
          checkPlatformCompatibility: true,
          emojiViewConfig: emoji.EmojiViewConfig(
            backgroundColor: context.bg,
            columns: 7,
            emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
          ),
          categoryViewConfig: emoji.CategoryViewConfig(
            backgroundColor: context.surface,
            indicatorColor: AppColors.electricBlue,
            iconColorSelected: AppColors.electricBlue,
            iconColor: context.iconSecondary,
          ),
          bottomActionBarConfig: emoji.BottomActionBarConfig(
            backgroundColor: context.surface,
            buttonColor: context.surface,
            buttonIconColor: context.iconSecondary,
          ),
          searchViewConfig: emoji.SearchViewConfig(
            backgroundColor: context.surface,
            buttonIconColor: context.iconPrimary,
          ),
        ),
      ),
    );
}
