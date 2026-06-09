import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otp/otp.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';

class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() =>
      _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  String? _secret;
  List<String>? _backupCodes;
  final _codeController = TextEditingController();
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _generateSecret();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _generateSecret() {
    final rand = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    _secret =
        List.generate(32, (_) => chars[rand.nextInt(chars.length)]).join();
    _backupCodes = List.generate(8, (_) => _randomBackupCode());
  }

  String _randomBackupCode() {
    final r = Random.secure();
    return List.generate(8, (_) => r.nextInt(10)).join();
  }

  Future<void> _enable2FA() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _secret == null) return;

    final code = _codeController.text.trim();
    final expected = OTP.generateTOTPCodeString(
      _secret!,
      DateTime.now().millisecondsSinceEpoch,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
    if (code != expected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code. Try again.')),
      );
      return;
    }

    final algo = Sha256();
    final hashedCodes = <String>[];
    for (final c in _backupCodes!) {
      final digest = await algo.hash(utf8.encode(c));
      hashedCodes.add(base64Encode(digest.bytes));
    }

    await FirebaseFirestore.instance.collection('users_private').doc(uid).set({
      'totpSecret': _secret,
      'totpBackupHashes': hashedCodes,
      'totpEnabledAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await ref.read(profileRepositoryProvider).updatePrivacySettings(
      uid: uid,
      settings: {'isTwoFactorEnabled': true},
    );

    setState(() => _verified = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Two-factor authentication enabled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = FirebaseAuth.instance.currentUser?.email ?? 'user';
    final uri = 'otpauth://totp/GOTCHAA:$email?secret=$_secret&issuer=GOTCHAA';

    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Authentication')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Scan with Google Authenticator or Authy',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (_secret != null)
            Center(
              child: QrImageView(
                data: uri,
                size: 200,
                backgroundColor: isDark ? Colors.white : Colors.white,
              ),
            ),
          const SizedBox(height: 12),
          SelectableText('Secret: $_secret',
              style: GoogleFonts.outfit(fontSize: 12)),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '6-digit code',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _enable2FA,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue),
            child: const Text('Verify & Enable'),
          ),
          if (_backupCodes != null && !_verified) ...[
            const SizedBox(height: 24),
            Text('Backup codes (save once):',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ..._backupCodes!
                .map((c) => Text(c, style: GoogleFonts.robotoMono())),
          ],
        ],
      ),
    );
  }
}
