import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/security/e2ee_service.dart';
import '../../../../core/theme/app_colors.dart';

// =============================================================================
// E2EE Key Management Screen
// Shows technical info about the cryptography in use, and exposes
// key rotation, backup export, and backup import to the user.
// =============================================================================

class E2eeKeyManagementScreen extends ConsumerStatefulWidget {
  const E2eeKeyManagementScreen({super.key});

  @override
  ConsumerState<E2eeKeyManagementScreen> createState() =>
      _E2eeKeyManagementScreenState();
}

class _E2eeKeyManagementScreenState
    extends ConsumerState<E2eeKeyManagementScreen> {
  bool _isRotating = false;
  bool _isExporting = false;
  bool _isImporting = false;

  // ---------------------------------------------------------------------------
  // Key Rotation
  // ---------------------------------------------------------------------------
  Future<void> _rotateKeys() async {
    final confirmed = await _showConfirmDialog(
      title: 'Rotate Identity Keys?',
      body:
          'This generates a new X25519 key pair and updates your public key on GOTCHAA servers.\n\n'
          '⚠️ After rotation, contacts will need to verify your new Safety Number. '
          'Old messages will still decrypt as long as this device keeps the old key in cache.',
      confirmLabel: 'Rotate Keys',
      confirmColor: Colors.orange,
    );
    if (!confirmed) return;

    setState(() => _isRotating = true);
    try {
      await ref.read(e2eeServiceProvider).rotateKeys();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Keys rotated successfully! New key uploaded to Firestore.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Rotation failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRotating = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Key Backup Export (PBKDF2 + AES-256-GCM passphrase-protected)
  // ---------------------------------------------------------------------------
  Future<void> _exportBackup() async {
    final passphrase = await _showPassphraseDialog(
      title: 'Export Key Backup',
      hint: 'Choose a strong passphrase to protect your backup',
      buttonLabel: 'Export',
    );
    if (passphrase == null || passphrase.isEmpty) return;

    setState(() => _isExporting = true);
    try {
      final e2ee = ref.read(e2eeServiceProvider);
      final backupBase64 = await e2ee.exportKeyBackup(passphrase);

      // Write to app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/gotchaa_key_backup.e2ee');
      await file.writeAsString(backupBase64);

      // Copy to clipboard as well
      await Clipboard.setData(ClipboardData(text: backupBase64));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Backup saved to ${file.path} and copied to clipboard.',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Key Backup Import
  // ---------------------------------------------------------------------------
  Future<void> _importBackup() async {
    final confirmed = await _showConfirmDialog(
      title: 'Import Key Backup?',
      body:
          'This will OVERWRITE your current private key with the imported one.\n\n'
          '⚠️ Only do this if you exported a backup from another device. '
          'Your current key will be permanently replaced.',
      confirmLabel: 'Continue',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    // Get backup text
    final backupData = await _showTextInputDialog(
      title: 'Paste Key Backup',
      hint: 'Paste the base64 backup string here',
    );
    if (backupData == null || backupData.isEmpty) return;

    final passphrase = await _showPassphraseDialog(
      title: 'Decrypt Key Backup',
      hint: 'Enter the passphrase you used when exporting',
      buttonLabel: 'Import',
    );
    if (passphrase == null || passphrase.isEmpty) return;

    setState(() => _isImporting = true);
    try {
      final e2ee = ref.read(e2eeServiceProvider);
      await e2ee.importKeyBackup(backupData.trim(), passphrase);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Key backup imported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Import failed: wrong passphrase or corrupt backup. ($e)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Dialog helpers
  // ---------------------------------------------------------------------------
  Future<bool> _showConfirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(body, style: GoogleFonts.outfit(color: Colors.white70, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel, style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _showPassphraseDialog({
    required String title,
    required String hint,
    required String buttonLabel,
  }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: GoogleFonts.outfit(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: Colors.white38),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.electricBlue)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricBlue),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(buttonLabel, style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  Future<String?> _showTextInputDialog({required String title, required String hint}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.electricBlue),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricBlue),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text('Confirm', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Encryption & Keys',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header banner ---
            _buildInfoBanner(),
            const SizedBox(height: 28),

            // --- Crypto Technical Details ---
            _buildSectionTitle('How It Works'),
            const SizedBox(height: 12),
            _buildTechCard(),
            const SizedBox(height: 28),

            // --- Actions ---
            _buildSectionTitle('Key Management'),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.autorenew_rounded,
              color: Colors.orange,
              title: 'Rotate Identity Keys',
              subtitle: 'Generate a new X25519 key pair. Contacts will see a new Safety Number.',
              isLoading: _isRotating,
              onTap: _rotateKeys,
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.upload_rounded,
              color: AppColors.electricBlue,
              title: 'Export Key Backup',
              subtitle: 'Encrypt & save your private key with a passphrase. Use on a new device.',
              isLoading: _isExporting,
              onTap: _exportBackup,
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.download_rounded,
              color: Colors.green,
              title: 'Import Key Backup',
              subtitle: 'Restore a previous backup to decrypt messages from your old device.',
              isLoading: _isImporting,
              onTap: _importBackup,
              isDanger: false,
            ),
            const SizedBox(height: 28),

            // --- Forward Secrecy Note ---
            _buildForwardSecrecyNote(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title.toUpperCase(),
    style: GoogleFonts.outfit(
      color: Colors.white38,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    ),
  );

  Widget _buildInfoBanner() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.electricBlue.withValues(alpha: 0.2), Colors.purple.withValues(alpha: 0.15)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.electricBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'End-to-End Encrypted',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'GOTCHAA cannot read your messages. Private keys never leave your device.',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);

  Widget _buildTechCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      children: [
        _buildTechRow('Key Exchange', 'X25519 Elliptic Curve Diffie-Hellman', Icons.swap_horiz_rounded),
        _divider(),
        _buildTechRow('Key Derivation', 'HKDF-SHA256 (chatId as info)', Icons.functions_rounded),
        _divider(),
        _buildTechRow('Encryption', 'AES-256-GCM (random 12-byte IV per message)', Icons.enhanced_encryption_rounded),
        _divider(),
        _buildTechRow('Integrity', 'AES-GCM Authentication Tag (128-bit)', Icons.verified_rounded),
        _divider(),
        _buildTechRow('Key Storage', 'flutter_secure_storage (Android Keystore / iOS Secure Enclave)', Icons.security_rounded),
        _divider(),
        _buildTechRow('Safety Number', 'SHA-256(pubKeyA ‖ pubKeyB) — first 40 hex chars', Icons.fingerprint_rounded),
        _divider(),
        _buildTechRow('Key Backup', 'PBKDF2-SHA256 (100k iterations) + AES-256-GCM', Icons.backup_rounded),
        _divider(),
        _buildTechRow('Forward Secrecy', 'Symmetric Ratchet foundation (Double Ratchet ready)', Icons.repeat_rounded),
      ],
    ),
  ).animate().fadeIn(delay: 100.ms);

  Widget _divider() => Divider(color: Colors.white10, height: 20);

  Widget _buildTechRow(String label, String value, IconData icon) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: AppColors.electricBlue.withValues(alpha: 0.8)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    ],
  );

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isLoading,
    required VoidCallback onTap,
    bool isDanger = false,
  }) => InkWell(
    onTap: isLoading ? null : onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                : Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 3),
                Text(subtitle, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ],
      ),
    ),
  ).animate().fadeIn(delay: 200.ms);

  Widget _buildForwardSecrecyNote() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.purple.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.science_rounded, color: Colors.purple, size: 18),
            const SizedBox(width: 8),
            Text(
              'Double Ratchet (Forward Secrecy)',
              style: GoogleFonts.outfit(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'GOTCHAA has implemented the RatchetState and symmetric ratchet step — the foundation of the Signal Protocol Double Ratchet. Full implementation provides Perfect Forward Secrecy: even if one key is compromised, future and past messages remain secure.',
          style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12, height: 1.5),
        ),
      ],
    ),
  ).animate().fadeIn(delay: 300.ms);
}
