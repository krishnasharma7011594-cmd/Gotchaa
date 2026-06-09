import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/legal/legal_documents.dart';
import '../../../../core/providers/legal_provider.dart';
import '../../../../core/services/consent_gate_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../compliance/widgets/gotchaa_consent_modal.dart';
import '../../../settings/presentation/screens/legal_document_reader_screen.dart';

class LegalConsentGateScreen extends ConsumerStatefulWidget {
  const LegalConsentGateScreen({super.key});

  @override
  ConsumerState<LegalConsentGateScreen> createState() => _LegalConsentGateScreenState();
}

class _LegalConsentGateScreenState extends ConsumerState<LegalConsentGateScreen> {
  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // App Logo or Icon
              Image.asset(
                'assets/logo/gotchaa_logo_white.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to GOTCHAA',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Before we start, please review and accept our legal agreements to ensure a safe experience for everyone.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              
              // Consent Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _isAccepted,
                            onChanged: (value) {
                              setState(() {
                                _isAccepted = value ?? false;
                              });
                            },
                            activeColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      final doc = LegalDocuments.byId('terms');
                                      if (doc != null) {
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => LegalDocumentReaderScreen(document: doc),
                                        ));
                                      }
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      final doc = LegalDocuments.byId('privacy');
                                      if (doc != null) {
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => LegalDocumentReaderScreen(document: doc),
                                        ));
                                      }
                                    },
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isAccepted
                      ? () async {
                          await ref.read(legalAcceptedProvider.notifier).acceptLegal();
                          if (!await ConsentGateService.hasPromptedForConsent() && context.mounted) {
                            await GotchaaConsentModal.show(context);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Continue to App',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              Text(
                'By continuing, you confirm you are at least 13 years old.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
}
