import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import 'legal_consent_gate_screen.dart';

/// Splash screen: shows brand animation then routes to LegalConsentGateScreen
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LegalConsentGateScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Pulsing glow
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.electricBlue.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: const Duration(seconds: 2),
              ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Image.asset(
                    'assets/logo/gotchaa_logo_white.png',
                    fit: BoxFit.contain,
                  ),
                )
                    .animate()
                    .fadeIn(duration: const Duration(milliseconds: 600))
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      curve: Curves.elasticOut,
                    )
                    .shimmer(
                      delay: const Duration(seconds: 1),
                      duration: const Duration(milliseconds: 1500),
                    ),

                const SizedBox(height: 24),

                Text(
                  'GOTCHAA',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 300))
                    .slideY(begin: 0.2),

                const SizedBox(height: 8),

                Text(
                  'The Social Super App',
                  style: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
              ],
            ),
          ),

          // Version
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v1.0.4',
                style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12),
              ),
            ).animate().fadeIn(delay: const Duration(seconds: 1)),
          ),
        ],
      ),
    );
}
