import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/models/chat_models.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/shell_navigation_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/security/e2ee_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gotchaa_empty_state.dart';
import '../../../../core/widgets/gotchaa_skeleton_loader.dart';
import '../../../ai/presentation/screens/gemini_chat_screen.dart';
import '../../../home/presentation/screens/main_shell.dart';
import '../../providers/chat_providers.dart';
import 'chat_conversation_screen.dart';

class ChatHomeScreen extends ConsumerStatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  ConsumerState<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends ConsumerState<ChatHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final chatsAsync = ref.watch(chatListProvider);
    final themeState = ref.watch(themeProvider);

    // Automatically clean up E2EE keys for chats that no longer exist
    ref.listen(chatListProvider, (previous, next) {
      if (next.hasValue) {
        final chatIds = next.value!.map((c) => c.id).toList();
        E2EEService().cleanupOrphanedKeys(chatIds);
      }
    });

    final customTheme = AppTheme.fromGotchaaTheme(themeState.currentTheme);

    return Theme(
      data: customTheme,
      child: Builder(
          builder: (chatContext) => Scaffold(
                backgroundColor: customTheme.scaffoldBackgroundColor,
                body: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                mainShellScaffoldKey.currentState?.openDrawer();
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: chatContext.inputFill,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.menu_rounded,
                                    color: chatContext.iconPrimary, size: 20),
                              ),
                            ),
                            profileAsync.when(
                              data: (profile) => CircleAvatar(
                                radius: 20,
                                backgroundImage: profile != null &&
                                        profile.photoUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(
                                        profile.photoUrl)
                                    : null,
                                backgroundColor: chatContext.shimmerBase,
                                child:
                                    profile == null || profile.photoUrl.isEmpty
                                        ? Icon(Icons.person_rounded,
                                            color: chatContext.iconSecondary)
                                        : null,
                              ),
                              loading: () => CircleAvatar(
                                  radius: 20,
                                  backgroundColor: chatContext.shimmerBase),
                              error: (_, __) => CircleAvatar(
                                  radius: 20,
                                  backgroundColor: chatContext.shimmerBase,
                                  child: Icon(Icons.person_rounded,
                                      color: chatContext.iconSecondary)),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              chatContext.tr('chat_title'),
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: chatContext.textPrimary,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: chatsAsync.when(
                          data: (chats) {
                            if (chats.isEmpty) {
                              return _buildEmptyChatState(chatContext);
                            }
                            return ListView.builder(
                              padding:
                                  const EdgeInsets.only(top: 4, bottom: 100),
                              itemCount: chats.length + 1,
                              itemBuilder: (context, i) {
                                if (i == 0) {
                                  return _buildE2EENotice(chatContext);
                                }
                                return _ChatTile(
                                  chat: chats[i - 1],
                                  currentUid: currentUser?.uid ?? '',
                                );
                              },
                            );
                          },
                          loading: () => const GotchaaSkeletonLoader.chatList(
                              itemCount: 5),
                          error: (e, _) => Center(
                            child: Text(
                              chatContext.tr('error_load_failed',
                                  args: [e.toString()]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                floatingActionButton: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'gemini_fab',
                      onPressed: () {
                        Navigator.push(
                            chatContext,
                            MaterialPageRoute(
                                builder: (_) => const GeminiChatScreen()));
                      },
                      backgroundColor: chatContext.inputFill,
                      elevation: 2,
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: AppColors.electricBlue),
                    ),
                    const SizedBox(height: 16),
                    FloatingActionButton(
                      heroTag: 'chat_fab',
                      onPressed: () {},
                      backgroundColor: chatContext.primary,
                      child: const Icon(Icons.chat_bubble_rounded,
                          color: Colors.white),
                    ),
                  ],
                ),
              )),
    );
  }

  Widget _buildE2EENotice(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.tr('chat_e2ee_notice'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: context.textSecondary.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('chat_e2ee_subtitle'),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppColors.electricBlue.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyChatState(BuildContext context) => GotchaaEmptyState.chat(
        actionLabel: 'Find Someone to Chat',
        onAction: () {
          ref.read(shellPageControllerProvider).animateToPage(
                3, // Explore tab
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
        },
      );
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.chat, required this.currentUid});
  final ChatModel chat;
  final String currentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUid =
        chat.participants.firstWhere((p) => p != currentUid, orElse: () => '');
    if (otherUid.isEmpty) return const SizedBox.shrink();

    final otherUserAsync = ref.watch(userPresenceProvider(otherUid));
    final isOnline = otherUserAsync.value?.isOnline ?? false;

    final otherName = otherUserAsync.when(
      data: (user) {
        final displayName = user?.displayName ?? '';
        final username = user?.username ?? '';
        final cachedName = chat.participantNames[otherUid] ?? '';

        if (displayName.isNotEmpty && displayName != 'Unknown') {
          return displayName;
        }
        if (username.isNotEmpty && username != 'Unknown') return username;
        if (cachedName.isNotEmpty && cachedName != 'Unknown') return cachedName;
        return otherUid.length > 8
            ? 'User ${otherUid.substring(0, 6)}'
            : 'User';
      },
      loading: () => chat.participantNames[otherUid] ?? '...',
      error: (_, __) => chat.participantNames[otherUid] ?? 'User',
    );

    final otherAvatar = (chat.participantAvatars[otherUid]?.isNotEmpty ?? false)
        ? chat.participantAvatars[otherUid]!
        : (otherUserAsync.value?.photoUrl ?? '');

    final unreadCount = chat.unreadCount[currentUid] ?? 0;
    final isTyping = chat.typing[otherUid] ?? false;
    final isMuted = chat.isMuted[currentUid] ?? false;

    final isMe = chat.lastMessageSenderId == currentUid;
    final prefix = isMe ? 'You: ' : '';
    final themeState = ref.watch(themeProvider);
    final maxLines = themeState.chatListViewLines;

    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatConversationScreen(
                  chatId: chat.id,
                  userName: otherName,
                  userAvatar: otherAvatar),
            ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: otherAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(otherAvatar)
                      : null,
                  backgroundColor: context.shimmerBase,
                  child: otherAvatar.isEmpty
                      ? Text(
                          otherName.isNotEmpty
                              ? otherName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: context.textSecondary))
                      : null,
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(otherName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: context.textPrimary)),
                      ),
                      if (isMuted)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.volume_off_rounded,
                              size: 14, color: context.iconMuted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (isTyping)
                    Text('typing...',
                        style: GoogleFonts.outfit(
                            color: Colors.green,
                            fontSize: 13,
                            fontStyle: FontStyle.italic))
                  else ...[
                    if (chat.lastMessageType == 'image')
                      Text('$prefix Photo',
                          maxLines: maxLines,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: unreadCount > 0
                                  ? context.textPrimary
                                  : context.textSecondary,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400))
                    else if (chat.lastMessageType == 'audio')
                      Text('$prefix Audio',
                          maxLines: maxLines,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: unreadCount > 0
                                  ? context.textPrimary
                                  : context.textSecondary,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400))
                    else
                      DecryptedPreviewWidget(
                        lastMessage: chat.lastMessage,
                        chatId: chat.id,
                        otherUserId: otherUid,
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: unreadCount > 0
                                ? context.textPrimary
                                : context.textSecondary,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400),
                        prefix: prefix,
                        status: chat.lastMessageStatus,
                        isMe: isMe,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (chat.lastMessageTime != null)
                  Text(DateFormat.jm().format(chat.lastMessageTime!),
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: unreadCount > 0
                              ? AppColors.electricBlue
                              : context.textHint,
                          fontWeight: unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.w500)),
                const SizedBox(height: 6),
                if (unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DecryptedPreviewWidget extends ConsumerStatefulWidget {
  const DecryptedPreviewWidget({
    required this.lastMessage,
    required this.chatId,
    required this.otherUserId,
    required this.style,
    required this.prefix,
    super.key,
    this.maxLines = 1,
    this.status = 'sent',
    this.isMe = false,
  });
  final String lastMessage;
  final String chatId;
  final String otherUserId;
  final TextStyle style;
  final String prefix;
  final int maxLines;
  final String status;
  final bool isMe;

  @override
  ConsumerState<DecryptedPreviewWidget> createState() =>
      _DecryptedPreviewWidgetState();
}

class _DecryptedPreviewWidgetState
    extends ConsumerState<DecryptedPreviewWidget> {
  String? _decrypted;

  @override
  void initState() {
    super.initState();
    _decrypt();
  }

  @override
  void didUpdateWidget(covariant DecryptedPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lastMessage != widget.lastMessage ||
        oldWidget.chatId != widget.chatId) {
      if (mounted) setState(() => _decrypted = null);
      _decrypt();
    }
  }

  Future<void> _decrypt() async {
    if (widget.lastMessage.isEmpty) {
      if (mounted) setState(() => _decrypted = '');
      return;
    }

    try {
      final e2ee = ref.read(e2eeServiceProvider);
      final result = await e2ee
          .decryptForChat(widget.lastMessage, widget.chatId, widget.otherUserId)
          .timeout(const Duration(seconds: 3));
      if (mounted) setState(() => _decrypted = result);
    } catch (_) {
      if (mounted) setState(() => _decrypted = widget.lastMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_decrypted == null) {
      return Text(
        '${widget.prefix}...',
        maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis,
        style:
            widget.style.copyWith(color: widget.style.color?.withOpacity(0.5)),
      );
    }
    return Row(
      children: [
        if (widget.isMe) ...[
          _buildStatusIcon(),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            '${widget.prefix}$_decrypted',
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color = widget.style.color?.withOpacity(0.5) ?? Colors.grey;

    switch (widget.status) {
      case 'read':
        icon = Icons.done_all_rounded;
        color = AppColors.electricBlue;
        break;
      case 'delivered':
        icon = Icons.done_all_rounded;
        break;
      case 'sent':
        icon = Icons.done_rounded;
        break;
      default:
        icon = Icons.access_time_rounded;
    }

    return Icon(icon, size: 14, color: color);
  }
}
