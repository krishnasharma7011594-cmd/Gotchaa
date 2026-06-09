import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/consent_gate_service.dart';
import '../../../../core/services/two_factor_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/two_factor_code_dialog.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isDeleting = false;
  bool _isReauthenticating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _confirmController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (_confirmController.text != context.tr('delete_account_type_delete')) {
      setState(() => _errorMessage = 'Please type ${context.tr('delete_account_type_delete')} to confirm');
      return;
    }

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final profile = ref.read(currentUserProfileProvider).asData?.value;
      if (profile?.isTwoFactorEnabled == true) {
        final code = await showTwoFactorCodeDialog(context);
        if (code == null) {
          setState(() => _isDeleting = false);
          return;
        }
        final ok = await TwoFactorService.instance.verifyCode(code);
        if (!ok) {
          setState(() {
            _isDeleting = false;
            _errorMessage = 'Invalid two-factor code';
          });
          return;
        }
      }

      // 1. Re-authentication check
      // For simplicity in this demo, we'll try to re-authenticate if it's a recent login failure
      // But usually, we should show a dialog first.
      
      await ref.read(authRepositoryProvider).deleteUserAccount();
      await ConsentGateService.resetAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('delete_account_success'))),
        );
        // Auth state changes will handle navigation to login
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showReauthDialog();
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showReauthDialog() {
    final user = FirebaseAuth.instance.currentUser;
    final isGoogle = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('delete_account_reauth_title'),
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('delete_account_reauth_desc'),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            if (isGoogle)
              _buildGoogleReauthButton()
            else
              _buildEmailReauthForm(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleReauthButton() => SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () async {
          Navigator.pop(context);
          setState(() => _isReauthenticating = true);
          try {
            await ref.read(authRepositoryProvider).reauthenticateWithGoogle();
            _handleDelete();
          } catch (e) {
            setState(() => _errorMessage = e.toString());
          } finally {
            if (mounted) setState(() => _isReauthenticating = false);
          }
        },
        icon: CachedNetworkImage(
          imageUrl: 'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
          height: 24,
          placeholder: (context, url) => const SizedBox(
            height: 24,
            width: 24,
            child: BlurHash(hash: 'L5H2EC=pPdpWXVJs00QQV_9H00XY'),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error, size: 24),
        ),
        label: Text(
          'Re-authenticate with Google',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );

  Widget _buildEmailReauthForm() => Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: context.tr('auth_email'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: context.tr('auth_password'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () async {
              final email = _emailController.text.trim();
              final password = _passwordController.text;
              if (email.isEmpty || password.isEmpty) return;

              Navigator.pop(context);
              setState(() => _isReauthenticating = true);
              try {
                await ref.read(authRepositoryProvider).reauthenticate(email, password);
                _handleDelete();
              } catch (e) {
                setState(() => _errorMessage = e.toString());
              } finally {
                if (mounted) setState(() => _isReauthenticating = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              context.tr('btn_confirm'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ],
    );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('delete_account_title'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              context.tr('delete_account_warning'),
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              context.tr('delete_account_consequences'),
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _consequenceItem(context.tr('delete_account_consequence_profile')),
            _consequenceItem(context.tr('delete_account_consequence_posts')),
            _consequenceItem(context.tr('delete_account_consequence_chat')),

            const SizedBox(height: 40),

            Text(
              context.tr('delete_account_confirm_text'),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _confirmController,
              decoration: InputDecoration(
                hintText: context.tr('delete_account_type_delete'),
                hintStyle: GoogleFonts.outfit(color: Colors.grey.withOpacity(0.5)),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.error,
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: GoogleFonts.outfit(color: AppColors.error, fontSize: 13),
              ),
            ],

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isDeleting || _isReauthenticating ? null : _handleDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isDeleting || _isReauthenticating
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        context.tr('delete_account_title'),
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _consequenceItem(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: Colors.grey.shade600,
          height: 1.5,
        ),
      ),
    );
}
