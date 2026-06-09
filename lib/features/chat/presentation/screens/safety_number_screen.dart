import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/security/e2ee_service.dart';
import '../../../../core/theme/app_colors.dart';

class SafetyNumberScreen extends ConsumerStatefulWidget {
  const SafetyNumberScreen({
    required this.chatId,
    required this.remoteUserName,
    super.key,
  });
  final String chatId;
  final String remoteUserName;

  @override
  ConsumerState<SafetyNumberScreen> createState() => _SafetyNumberScreenState();
}

class _SafetyNumberScreenState extends ConsumerState<SafetyNumberScreen> {
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String _fingerprint = '';
  bool _isVerified = false;
  bool _loadingVerification = true;

  String get _verificationKey => 'safety_verified_${widget.chatId}';

  @override
  void initState() {
    super.initState();
    _loadVerifiedState();
    _calculateFingerprint();
  }

  /// M-1 FIX: Load persisted verification state from secure storage.
  Future<void> _loadVerifiedState() async {
    final stored = await _secureStorage.read(key: _verificationKey);
    if (mounted) {
      setState(() {
        _isVerified = stored == 'true';
        _loadingVerification = false;
      });
    }
  }

  Future<void> _calculateFingerprint() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No user');
      final parts = widget.chatId.split('_');
      final otherUserId =
          parts.first == currentUser.uid ? parts.last : parts.first;

      final e2ee = ref.read(e2eeServiceProvider);
      final fingerprint =
          await e2ee.calculateSafetyNumber(widget.chatId, otherUserId);

      if (mounted) {
        setState(() {
          _fingerprint = fingerprint;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _fingerprint = 'ERROR');
    }
  }

  Future<void> _markAsVerified() async {
    // M-1 FIX: Persist verified state to secure storage so it survives screen closes.
    await _secureStorage.write(key: _verificationKey, value: 'true');
    if (mounted) {
      setState(() => _isVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session marked as verified! ✅')),
      );
    }
  }

  Future<void> _revokeVerification() async {
    await _secureStorage.delete(key: _verificationKey);
    if (mounted) {
      setState(() => _isVerified = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification revoked.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          title: Text('Safety Number', style: GoogleFonts.outfit()),
          backgroundColor: Colors.transparent,
          actions: [
            if (_isVerified)
              TextButton.icon(
                onPressed: _revokeVerification,
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.orange, size: 16),
                label: Text('Revoke',
                    style:
                        GoogleFonts.outfit(color: Colors.orange, fontSize: 13)),
              ),
          ],
        ),
        body: _loadingVerification
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Verify that your messages with ${widget.remoteUserName} are end-to-end encrypted.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 16),
                    ),

                    if (_isVerified) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Verified Session',
                              style: GoogleFonts.outfit(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: QrImageView(
                        data: _fingerprint.isNotEmpty ? _fingerprint : ' ',
                        version: QrVersions.auto,
                        size: 200,
                      ),
                    )
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 40),

                    // Numeric Code
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: SelectableText(
                        _fingerprint.isNotEmpty
                            ? _fingerprint
                            : 'Calculating...',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.electricBlue,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    if (!_isVerified)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _markAsVerified,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.electricBlue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.verified_user_rounded),
                              const SizedBox(width: 12),
                              Text(
                                'Mark as Verified',
                                style: GoogleFonts.outfit(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                    Text(
                      'Confirm that the numbers above match the ones on their screen. If they match, this chat is 100% secure.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
      );
}
