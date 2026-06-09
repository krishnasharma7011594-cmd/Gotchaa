import 'dart:async';

import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class EncryptedTextWidget extends StatefulWidget {
  const EncryptedTextWidget({
    required this.messageId,
    required this.encryptedText,
    required this.decryptFn,
    required this.checkCacheFn,
    required this.style,
    super.key,
    this.sharedSecret,
  });
  final String messageId;
  final String encryptedText;
  final crypto.SecretKey? sharedSecret;
  final Future<String> Function(String, String) decryptFn;
  final String? Function(String) checkCacheFn;
  final TextStyle style;

  @override
  State<EncryptedTextWidget> createState() => _EncryptedTextWidgetState();
}

class _EncryptedTextWidgetState extends State<EncryptedTextWidget> {
  String? _decrypted;

  @override
  void initState() {
    super.initState();
    _decrypted = widget.checkCacheFn(widget.messageId) ??
        widget.checkCacheFn(widget.encryptedText);
    if (_decrypted == null) {
      _decrypt();
    }
  }

  @override
  void didUpdateWidget(EncryptedTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final secretChanged = widget.sharedSecret != oldWidget.sharedSecret;
    final notYetDecrypted =
        _decrypted == null || (_decrypted?.startsWith('[') ?? false);

    if (secretChanged && notYetDecrypted) {
      setState(() => _decrypted = null);
      _decrypt();
    }
    if (widget.encryptedText != oldWidget.encryptedText) {
      setState(() => _decrypted = null);
      _decrypt();
    }
  }

  Future<void> _decrypt() async {
    if (widget.sharedSecret == null) return;

    try {
      final res = await widget
          .decryptFn(widget.messageId, widget.encryptedText)
          .timeout(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _decrypted = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _decrypted = '[Decryption Failed]';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_decrypted == null) {
      return Text(
        '...',
        style:
            widget.style.copyWith(color: widget.style.color?.withOpacity(0.3)),
      );
    }

    if (_decrypted!.startsWith('[') && _decrypted!.endsWith(']')) {
      return DecryptionErrorBubble(
        errorText: _decrypted!,
        onRetry: () {
          setState(() => _decrypted = null);
          _decrypt();
        },
      );
    }

    return Text(_decrypted ?? '', style: widget.style);
  }
}

class DecryptionErrorBubble extends StatelessWidget {
  const DecryptionErrorBubble(
      {required this.errorText, super.key, this.onRetry});
  final VoidCallback? onRetry;
  final String errorText;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                context.tr('chat_waiting_message_title'),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _dialogMessage(errorText),
                    style: GoogleFonts.outfit(color: context.textSecondary),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onRetry!();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time,
                size: 12, color: context.textSecondary.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              _inlineMessage(errorText),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: context.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );

  String _inlineMessage(String error) {
    if (error == '[Message format error]') return 'Unsupported format';
    if (error == '[Encryption error]') return 'Encryption error';
    if (error == '[Decryption Failed]') return 'Syncing secure message...';
    return 'Message unavailable';
  }

  String _dialogMessage(String error) {
    if (error == '[Message format error]') {
      return 'This message uses an older format and cannot be displayed for security reasons.';
    }
    if (error == '[Encryption error]') {
      return 'This message is incomplete or was interrupted during transmission.';
    }
    if (error == '[Decryption Failed]') {
      return 'Gotchaa uses end-to-end encryption to keep your chats private. This message is waiting for a secure key update. This happens when you switch devices or accounts. It will appear once the other person comes online.';
    }
    return 'This message is temporarily unavailable due to encryption sync.';
  }
}

class GhostMessageWidget extends StatelessWidget {
  const GhostMessageWidget({super.key});

  @override
  Widget build(BuildContext context) => Align(
        alignment: AlignmentDirectional.center,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_fix_high, size: 14, color: Colors.white54),
              const SizedBox(width: 8),
              Text(
                'Message vanished',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
}

class MessageCountdownWidget extends StatefulWidget {
  const MessageCountdownWidget({
    required this.expiresAt,
    required this.onExpired,
    super.key,
  });
  final DateTime expiresAt;
  final VoidCallback onExpired;

  @override
  State<MessageCountdownWidget> createState() => _MessageCountdownWidgetState();
}

class _MessageCountdownWidgetState extends State<MessageCountdownWidget> {
  Timer? _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(_updateTimeLeft);
    });
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    if (now.isAfter(widget.expiresAt)) {
      _timeLeft = Duration.zero;
      _timer?.cancel();
      widget.onExpired();
    } else {
      _timeLeft = widget.expiresAt.difference(now);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String minutes = twoDigits(d.inMinutes.remainder(60));
    final String seconds = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 10, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            _formatDuration(_timeLeft),
            style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70),
          ),
        ],
      );
}
