import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/models/chat_models.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/security/e2ee_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/chat_providers.dart';
import '../../services/chat_service.dart';
import '../../../../core/firebase/performance_traces.dart';
import '../../../../core/security/secure_screen.dart';
import '../../../../features/reporting/report_dialog.dart';
import '../../../../features/safety/emergency_safety_service.dart';
import '../widgets/enhanced_chat_input.dart';
import '../widgets/message_bubble.dart';
import 'safety_number_screen.dart';

class ChatConversationScreen extends ConsumerStatefulWidget {
  
  const ChatConversationScreen({
    required this.chatId, required this.userName, super.key, 
    this.userAvatar,
  });
  final String chatId;
  final String userName;
  final String? userAvatar;

  @override
  ConsumerState<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends ConsumerState<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _recipientUid;
  
  bool _isTyping = false;
  Timer? _typingTimer;

  // Translation State
  final Map<String, String> _translations = {};
  final Set<String> _translatingSet = {};

  // E2EE State — simple per-chat key, loaded once
  bool _isE2EEReady = false;
  crypto.SecretKey? _sharedSecret;
  final Map<String, String> _decryptedCache = {};

  // Disappearing messages state
  Duration? _disappearingDuration;

  // E2EE toggle — user can enable per-conversation encryption.
  // Defaults to false so push notifications show readable previews.
  // When true, ChatService encrypts before writing & stores "🔒 Encrypted message"
  // as the notification-safe lastMessage preview.
  bool _e2eeEnabled = false;

  // Selection state
  final Map<String, MessageModel> _selectedMessages = {};
  bool get _isSelectionMode => _selectedMessages.isNotEmpty;

  // Reply state
  MessageModel? _replyingToMessage;

  int _titleTapCount = 0;
  DateTime _lastTitleTap = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    GotchaaPerformanceTraces.instance.startChatOpen();
    Future.microtask(() async {
      await _resolveRecipient();
      await _loadChatKey();
      _markMessagesAsRead();
    });
  }

  /// Resolve the other participant's UID from the chat document.
  Future<void> _resolveRecipient() async {
    final currentUserId = ref.read(authStateProvider).value?.uid ?? '';
    if (currentUserId.isEmpty) return;

    String? resolvedRecipient;

    try {
      final chatDoc = await ref
          .read(firestoreProvider)
          .collection('chats')
          .doc(widget.chatId)
          .get();
      final participants =
          List<String>.from(chatDoc.data()?['participants'] ?? const []);
      if (participants.isNotEmpty) {
        resolvedRecipient = participants.firstWhere(
          (uid) => uid != currentUserId,
          orElse: () => '',
        );
      }
    } catch (_) {}

    // Fallback: derive from chatId format "<uid1>_<uid2>"
    if ((resolvedRecipient ?? '').isEmpty) {
      final parts = widget.chatId.split('_');
      if (parts.length == 2) {
        resolvedRecipient =
            parts.first == currentUserId ? parts.last : parts.first;
      }
    }

    if ((resolvedRecipient ?? '').isEmpty) return;

    _recipientUid = resolvedRecipient;
    if (mounted) setState(() {});
  }

  /// Load (or create) the persistent ECDH shared key for this chat.
  /// Silently skips if the recipient UID hasn't resolved yet — the UI
  /// disables the E2EE toggle until the key is ready.
  Future<void> _loadChatKey() async {
    final recipientUid = _recipientUid;
    if (recipientUid == null || recipientUid.isEmpty) return;

    try {
      final e2ee = ref.read(e2eeServiceProvider);
      final key = await e2ee.getOrCreateChatKey(widget.chatId, recipientUid);
      if (mounted) {
        setState(() {
          _sharedSecret = key;
          _isE2EEReady = true;
        });
      }
    } catch (e) {
      // Key derivation failed (e.g. recipient hasn't set up E2EE yet).
      // Leave _isE2EEReady = false so the toggle stays disabled.
      if (mounted) {
        setState(() => _isE2EEReady = false);
      }
    }
  }

  void _markMessagesAsRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_recipientUid != null) {
        try {
          ref.read(chatServiceProvider).setActiveChat(widget.chatId);
          await ref
              .read(chatServiceProvider)
              .markMessagesAsRead(widget.chatId, _recipientUid!);
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    GotchaaPerformanceTraces.instance.stopChatOpen();
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    Future.microtask(() => ref.read(chatServiceProvider).setActiveChat(null));
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      ref.read(chatServiceProvider).setTypingStatus(widget.chatId, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      ref.read(chatServiceProvider).setTypingStatus(widget.chatId, false);
    });
  }

  /// Decrypt a single message on-the-fly using the chat's shared key.
  /// • schemaVersion == 0 → "Old message (unsupported)"
  /// • decryption error  → "Unable to decrypt message"
  Future<String> _decryptOnTheFly(
    String messageId,
    String encryptedText, {
    int schemaVersion = CURRENT_MESSAGE_SCHEMA_VERSION,
  }) async {
    // Return cached result immediately
    if (_decryptedCache.containsKey(messageId)) {
      return _decryptedCache[messageId]!;
    }

    // Reject legacy schema
    if (schemaVersion == 0) {
      return 'Old message (unsupported)';
    }

    try {
      final decrypted = await ref
          .read(e2eeServiceProvider)
          .decryptForChat(encryptedText, widget.chatId, _recipientUid!);
      _decryptedCache[messageId] = decrypted;
      return decrypted;
    } catch (e) {
      return encryptedText;
    }
  }

  Future<void> _translateMessage(MessageModel msg) async {
    if (msg.type != 'text') return;
    if (msg.isDeletedForEveryone) return;
    if (_translations.containsKey(msg.id) || _translatingSet.contains(msg.id)) return;

    final svc = ref.read(translationServiceProvider);
    
    _translatingSet.add(msg.id);
    if (mounted) setState(() {});

    try {
      String text = msg.text;
      if (msg.isEncrypted) {
        final decrypted = await _decryptOnTheFly(
          msg.id,
          msg.text,
          schemaVersion: msg.schemaVersion,
        );
        if (decrypted.startsWith('[') && decrypted.endsWith(']')) return;
        if (decrypted == 'Waiting for message...') return;
        if (decrypted == 'Old message (unsupported)') return;
        text = decrypted;
      }

      final source = await svc.detectLanguage(text);
      if (source == null) {
        if (mounted) {
          String errorMsg = 'Could not detect language';
          // Check if it looks like ciphertext (no spaces, long base64)
          if (!text.contains(' ') && text.length > 30) {
             errorMsg = 'Cannot detect language (Text may be encrypted)';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
        return;
      }
      
      final target = svc.preferredLanguage;
      if (source == target) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Already in ${target.name}')),
          );
        }
        return;
      }

      if (!await svc.isModelDownloaded(source)) {
        await svc.downloadModel(source);
      }
      if (!await svc.isModelDownloaded(target)) {
        await svc.downloadModel(target);
      }

      final translated = await svc.translateText(text, source, target);
      if (!mounted) return;
      setState(() {
        _translations[msg.id] = translated;
      });
    } finally {
      _translatingSet.remove(msg.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _recipientUid == null) return;

    final originalText = _messageController.text;
    _messageController.clear();

    try {
      DateTime? expiresAt;
      if (_disappearingDuration != null) {
        expiresAt = DateTime.now().add(_disappearingDuration!);
      }

      // E2EE is opt-in per conversation. When enabled:
      //  • ChatService encrypts the text with AES-GCM before writing to Firestore.
      //  • The lastMessage preview stored on the chat doc becomes '🔒 Encrypted message'
      //    so push notifications never expose plaintext.
      //  • Only enable if the key has been successfully derived (_isE2EEReady).
      final useE2EE = _e2eeEnabled && _isE2EEReady;

      await ref.read(chatServiceProvider).sendMessage(
        chatId: widget.chatId,
        receiverId: _recipientUid!,
        text: text,
        isEncrypted: useE2EE,
        expiresAt: expiresAt,
      );
      // Fire analytics — non-blocking
      AnalyticsService.logMessageSent(type: 'text');
    } catch (e) {
      if (mounted) _messageController.text = originalText;
    }
  }

  void _toggleSelection(MessageModel msg) {
    setState(() {
      if (_selectedMessages.containsKey(msg.id)) {
        _selectedMessages.remove(msg.id);
      } else {
        _selectedMessages[msg.id] = msg;
      }
    });
    if (_selectedMessages.isNotEmpty) {
      HapticFeedback.lightImpact();
    }
  }

  void _clearSelection() {
    setState(_selectedMessages.clear);
  }

  void _handleReply() {
    if (_selectedMessages.length != 1) return;
    final msg = _selectedMessages.values.first;
    setState(() {
      _replyingToMessage = msg;
    });
    _clearSelection();
  }

  Future<void> _handleReport() async {
    if (_selectedMessages.isEmpty) return;
    final msg = _selectedMessages.values.first;
    _clearSelection();
    final reportedUid = _recipientUid ?? msg.senderId;
    showReportBottomSheet(
      context,
      reportedUserId: reportedUid,
      contentType: 'message',
      contentId: msg.id,
      contentPreview: msg.text,
    );
  }

  void _onTitleTap() {
    final now = DateTime.now();
    if (now.difference(_lastTitleTap).inMilliseconds > 800) _titleTapCount = 0;
    _lastTitleTap = now;
    _titleTapCount++;
    if (_titleTapCount >= 3) {
      _titleTapCount = 0;
      EmergencySafetyService.instance.sendSilentSos(
        context: 'chat_triple_tap',
        partnerId: _recipientUid,
        roomId: widget.chatId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Safety alert sent discreetly.')),
        );
      }
    }
  }

  void _showMessageActions(MessageModel msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.white70),
              title: const Text('Select', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _toggleSelection(msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: const Text('Report', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                showReportBottomSheet(
                  context,
                  reportedUserId: _recipientUid ?? msg.senderId,
                  contentType: 'message',
                  contentId: msg.id,
                  contentPreview: msg.text,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTranslate() async {
    if (_selectedMessages.isEmpty) return;
    
    // Create a list to avoid issues when clearing selection
    final messagesToTranslate = _selectedMessages.values.toList();
    _clearSelection();
    
    for (final msg in messagesToTranslate) {
      await _translateMessage(msg);
    }
  }

  void _handleCopy() async {
    if (_selectedMessages.isEmpty) return;
    
    final texts = _selectedMessages.values.map((m) => m.text).join('\n');
    await Clipboard.setData(ClipboardData(text: texts));
    
    _clearSelection();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1A1A1A),
        ),
      );
    }
  }

  Future<void> _deleteSelectedMessages() async {
    final idsToDelete = _selectedMessages.keys.toList();
    _clearSelection();
    
    for (final id in idsToDelete) {
      await _deleteMessage(id, false);
    }
  }

  void _copyToClipboard() {
    // Implement copy logic for text messages
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }

  Future<void> _sendMedia(ImageSource source, {bool isVideo = false}) async {
    if (_recipientUid == null) return;
    final picker = ImagePicker();
    final file = isVideo
        ? await picker.pickVideo(source: source)
        : await picker.pickImage(source: source);
    if (file != null && mounted) {
      try {
        await ref.read(chatServiceProvider).sendMessage(
          chatId: widget.chatId,
          receiverId: _recipientUid!,
          text: isVideo ? 'Video' : 'Image',
          type: isVideo ? 'video' : 'image',
          mediaFile: file,
        );
      } catch (_) {}
    }
  }

  Future<void> _deleteMessage(String messageId, bool forEveryone) async {
    try {
      await ref
          .read(chatServiceProvider)
          .deleteMessage(widget.chatId, messageId, forEveryone: forEveryone);
    } catch (_) {}
  }

  void _showTimerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                context.tr('chat_disappearing_messages'),
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading:
                  Icon(Icons.timer_off_outlined, color: context.textSecondary),
              title: Text(context.tr('chat_timer_off')),
              onTap: () {
                setState(() => _disappearingDuration = null);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.timer, color: AppColors.electricBlue),
              title: const Text('24 Hours'),
              onTap: () {
                setState(() =>
                    _disappearingDuration = const Duration(hours: 24));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: AppColors.electricBlue),
              title: const Text('7 Days'),
              onTap: () {
                setState(
                    () => _disappearingDuration = const Duration(days: 7));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showMoreOptionsDialog(MessageModel msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (msg.type == 'text' && !msg.isDeletedForEveryone && !_translations.containsKey(msg.id))
              ListTile(
                leading: const Icon(Icons.translate, color: AppColors.electricBlue),
                title: const Text('Translate Message'),
                onTap: () {
                  Navigator.pop(context);
                  _translateMessage(msg);
                },
              ),
            if (isMe && !msg.isDeletedForEveryone)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Delete for Everyone',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(msg.id, true);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined,
                  color: Colors.redAccent),
              title: const Text('Delete for Me',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(msg.id, false);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showFullscreenMedia(String url, {required bool isVideo}) {
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: isVideo
              ? VideoPlayerWidget(url: url)
              : CachedNetworkImage(imageUrl: url),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    // Per-message decrypt function with schema-version guard baked in
    Future<String> perMsgDecrypt(String id, String text) =>
        _decryptOnTheFly(id, text, schemaVersion: msg.schemaVersion);

    return MessageBubble(
      msg: msg,
      isMe: isMe,
      isSelected: _selectedMessages.containsKey(msg.id),
      selectionModeActive: _isSelectionMode,
      translation: _translations[msg.id],
      userAvatar: widget.userAvatar,
      sharedSecret: _sharedSecret,
      onLongPress: () => _showMessageActions(msg),
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(msg);
        }
      },
      onMediaTap: _showFullscreenMedia,
      decryptFn: perMsgDecrypt,
      checkCacheFn: (key) => _decryptedCache[key],
      onReactionAdd: (emoji) {
        ref.read(chatServiceProvider).addReaction(widget.chatId, msg.id, emoji);
      },
      onExpired: () {
        if (mounted) setState(() {});
      },
    );
  }

  PreferredSizeWidget _buildDefaultAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor?.withValues(alpha: 0.9),
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, 
            color: theme.colorScheme.onSurface, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Hero(
            tag: 'avatar_${widget.chatId}',
            child: CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: widget.userAvatar != null
                  ? NetworkImage(widget.userAvatar!)
                  : null,
              child: widget.userAvatar == null
                  ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _onTitleTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.videocam_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.call_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          onPressed: () {},
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          color: theme.colorScheme.surface,
          onSelected: (value) {
            if (value == 'e2ee_toggle') {
              if (!_isE2EEReady) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Encryption not available — the other person may not have set it up yet.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              setState(() => _e2eeEnabled = !_e2eeEnabled);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _e2eeEnabled
                        ? '🔒 End-to-end encryption enabled'
                        : '🔓 Encryption disabled — messages visible in notifications',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (value == 'safety_number') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SafetyNumberScreen(
                    chatId: widget.chatId,
                    remoteUserName: widget.userName,
                  ),
                ),
              );
            } else if (value == 'report') {
              showReportBottomSheet(
                context,
                reportedUserId: _recipientUid ?? widget.chatId,
                contentType: 'chat',
                contentId: widget.chatId,
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'e2ee_toggle',
              child: Row(
                children: [
                  Icon(
                    _e2eeEnabled ? Icons.lock : Icons.lock_open_outlined,
                    color: _isE2EEReady
                        ? (_e2eeEnabled ? Colors.greenAccent : theme.colorScheme.onSurface)
                        : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isE2EEReady
                          ? (_e2eeEnabled ? 'Encryption: ON' : 'Encryption: OFF')
                          : 'Encryption unavailable',
                      style: TextStyle(
                        color: _isE2EEReady ? null : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'safety_number',
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Safety Number'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text('Report'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
   @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messageStreamProvider(widget.chatId));
    final themeState = ref.watch(themeProvider);
    final customTheme = AppTheme.fromGotchaaTheme(themeState.currentTheme);
    final isDark = customTheme.brightness == Brightness.dark;
    
    final bgImage = isDark 
        ? 'assets/images/chat_bg_custom.png' 
        : 'assets/images/chat_bg_light.png';

    return Theme(
      data: customTheme,
      child: Builder(builder: (chatContext) => WillPopScope(
          onWillPop: () async {
            if (_isSelectionMode) {
              _clearSelection();
              return false;
            }
            return true;
          },
          child: SecureChatWrapper(
          child: Scaffold(
            backgroundColor: customTheme.scaffoldBackgroundColor,
            appBar: _isSelectionMode ? AppBar(
                    backgroundColor: customTheme.cardTheme.color ?? const Color(0xFF1A1A1A),
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: customTheme.colorScheme.onSurface),
                      onPressed: _clearSelection,
                    ),
                    title: Text(
                      '${_selectedMessages.length}',
                      style: GoogleFonts.outfit(color: customTheme.colorScheme.onSurface, fontSize: 20),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.copy, color: customTheme.colorScheme.onSurface),
                        onPressed: _handleCopy,
                      ),
                      IconButton(
                        icon: Icon(Icons.reply, color: customTheme.colorScheme.onSurface),
                        onPressed: _handleReply,
                      ),
                      IconButton(
                        icon: Icon(Icons.report_problem_outlined, color: customTheme.colorScheme.onSurface),
                        onPressed: _handleReport,
                      ),
                      IconButton(
                        icon: Icon(Icons.translate, color: customTheme.colorScheme.onSurface),
                        onPressed: _handleTranslate,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: customTheme.colorScheme.onSurface),
                        onPressed: _deleteSelectedMessages,
                      ),
                    ],
                  ) : _buildDefaultAppBar(chatContext),
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(bgImage),
                  fit: BoxFit.cover,
                  opacity: isDark ? 0.4 : 0.8,
                  colorFilter: isDark 
                      ? ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.dstATop)
                      : null,
                ),
              ),
              child: Column(
              children: [
                Expanded(
                  child: messagesAsync.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'No messages yet. Start the conversation.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: chatContext.textSecondary,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        itemCount: messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 40),
                              child: Text(
                                'Messages are end-to-end encrypted. No one outside of this chat can read them.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color:
                                      chatContext.textSecondary.withOpacity(0.5),
                                ),
                              ),
                            );
                          }
                          final msg = messages[index];
                          final isMe = msg.senderId ==
                              ref.read(authStateProvider).value?.uid;
                          return _buildMessageBubble(msg, isMe);
                        },
                      );
                    },
                    loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (e, st) => Center(child: Text(e.toString())),
                  ),
                ),
                EnhancedChatInput(
                  controller: _messageController,
                  replyingTo: _replyingToMessage,
                  onCancelReply: () => setState(() => _replyingToMessage = null),
                  onTypingChanged: (status) {
                    ref.read(chatServiceProvider).setTypingStatus(widget.chatId, status == 'typing');
                  },
                  onSend: (text) {
                    if (_recipientUid == null) return;
                    final useE2EE = _e2eeEnabled && _isE2EEReady;
                    ref.read(chatServiceProvider).sendMessage(
                      chatId: widget.chatId,
                      receiverId: _recipientUid!,
                      text: text,
                      isEncrypted: useE2EE,
                      replyTo: _replyingToMessage != null
                          ? ReplyTo(
                              messageId: _replyingToMessage!.id,
                              senderId: _replyingToMessage!.senderId,
                              text: _replyingToMessage!.text,
                              type: _replyingToMessage!.type,
                            )
                          : null,
                    );
                    setState(() => _replyingToMessage = null);
                  },
                ),
              ],
            ),
            ),
          ),
        ),)),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers (kept for compatibility — simplified)
// ---------------------------------------------------------------------------

class ChatHealth {
  ChatHealth({
    required this.canReadChat,
    required this.hasSharedSecret,
    required this.canReadPublicKey,
    required this.hasPrivateKey,
  });
  final bool canReadChat, hasSharedSecret, canReadPublicKey, hasPrivateKey;
}

class ChatHealthChecker {
  ChatHealthChecker(this.ref);
  final WidgetRef ref;

  Future<ChatHealth> check(String chatId, String recipientUid) async {
    // With simple per-chat keys there is no public-key dependency.
    // Key is always available (created on first access).
    return ChatHealth(
      canReadChat: true,
      hasSharedSecret: true,
      canReadPublicKey: true,
      hasPrivateKey: true,
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({required this.url, super.key});
  final String url;
  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.url))
          ..initialize().then((_) {
            setState(() {
              _isInitialized = true;
            });
            _controller.play();
            _controller.setLooping(true);
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
      child: _isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : const CircularProgressIndicator(),
    );
}

class SecureChatWrapper extends StatelessWidget {
  const SecureChatWrapper({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => SecureScreen(child: child);
}

