import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/nation/nation_data.dart';
import '../../../../core/nation/nation_providers.dart';
import '../../../../core/nation/nation_widgets.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../settings/presentation/screens/privacy_policy_screen.dart';
import '../../../settings/presentation/screens/terms_of_service_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUpMode = false;
  bool _obscurePassword = true;
  NationData? _selectedNation;

  @override
  void initState() {
    super.initState();
    // Kick off background nation detection immediately
    Future.microtask(() async {
      final service = ref.read(nationDetectionServiceProvider);
      final nation = await service.detectNation();
      if (mounted && nation != null) {
        setState(() => _selectedNation = nation);
        ref.read(selectedNationProvider.notifier).select(nation);
      }

      // Auto-trigger Demo if requested in URL
      if (kIsWeb) {
        final uri = Uri.base;
        if (uri.queryParameters['demo'] == 'true') {
          _handleDemo();
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    ref.read(authControllerProvider.notifier).resetState();
  }

  // ── Action handlers ───────────────────────────────────────────────────────

  Future<void> _handleEmailAuth() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Require country selection on signup
    if (_isSignUpMode && _selectedNation == null) {
      _showError('Please select your country to continue.');
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final controller = ref.read(authControllerProvider.notifier);

    if (_isSignUpMode) {
      await controller.signUp(email, password, nation: _selectedNation);
      AnalyticsService.logSignUpComplete(method: 'email');
    } else {
      await controller.signIn(email, password);
      AnalyticsService.logLoginSuccess(method: 'email');
    }
    // On success, Firebase auth state changes → AuthGate rebuilds → MainShell.
  }

  Future<void> _handleGoogle() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
    AnalyticsService.logLoginSuccess(method: 'google');
    // On success, Firebase auth state changes → AuthGate rebuilds → MainShell.
  }

  Future<void> _handleApple() async {
    await ref.read(authControllerProvider.notifier).signInWithApple();
    AnalyticsService.logLoginSuccess(method: 'apple');
    // On success, Firebase auth state changes → AuthGate rebuilds → MainShell.
  }

  Future<void> _handleDemo() async {
    await ref.read(authControllerProvider.notifier).signInAnonymously();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    // React to error state
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next is AuthError) _showError(next.message);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Decorative background circles ──────────────────────────────
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.electricBlue.withValues(alpha: 0.08),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 800.ms)
              .scale(begin: const Offset(0.5, 0.5)),

          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGlow.withValues(alpha: 0.05),
              ),
            ),
          ).animate().fadeIn(duration: 1000.ms, delay: 200.ms),

          // ── Main content ───────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    // Logo + Title
                    Image.asset(
                      'assets/logo/gotchaa_logo_white.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                    ).animate().fadeIn().scale(
                          begin: const Offset(0.7, 0.7),
                          curve: Curves.elasticOut,
                        ),

                    const SizedBox(height: 12),

                    Text(
                      'GOTCHAA',
                      style: GoogleFonts.outfit(
                        color: AppColors.black,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.2),

                    Text(
                      _isSignUpMode
                          ? 'Create your account.'
                          : 'The Social Super App.',
                      style: GoogleFonts.outfit(
                        color: Colors.grey.shade600,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 48),

                    // ── Form Card ─────────────────────────────────────────
                    GlassCard(
                      opacity: 0.04,
                      blur: 20,
                      borderRadius: 32,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Email
                            _buildTextField(
                              controller: _emailController,
                              hint: 'Email address',
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(v.trim())) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Country selector — only visible during signup
                            if (_isSignUpMode) ...[
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Your Country',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              CountrySelectorWidget(
                                preselected: _selectedNation,
                                onChanged: (nation) {
                                  setState(() => _selectedNation = nation);
                                  ref
                                      .read(selectedNationProvider.notifier)
                                      .select(nation);
                                },
                              ),
                              const SizedBox(height: 4),
                            ],

                            // Password
                            _buildTextField(
                              controller: _passwordController,
                              hint: 'Password',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              obscure: _obscurePassword,
                              onToggleObscure: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (_isSignUpMode && v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // CTA Button
                            _buildPrimaryButton(
                              label:
                                  _isSignUpMode ? 'Create Account' : 'Sign In',
                              isLoading: isLoading,
                              onPressed: _handleEmailAuth,
                            ),

                            const SizedBox(height: 16),

                            // Toggle mode link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isSignUpMode
                                      ? 'Already have an account? '
                                      : 'New here? ',
                                  style: GoogleFonts.outfit(
                                      color: Colors.grey, fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _isSignUpMode = !_isSignUpMode;
                                            _formKey.currentState?.reset();
                                            ref
                                                .read(authControllerProvider
                                                    .notifier)
                                                .resetState();
                                          });
                                        },
                                  child: Text(
                                    _isSignUpMode
                                        ? 'Sign In'
                                        : 'Create Account',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.electricBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).scaleY(begin: 0.92),

                    const SizedBox(height: 36),

                    // ── Social Sign-In ─────────────────────────────────────
                    Center(
                      child: Text(
                        'Or continue with',
                        style: GoogleFonts.outfit(
                            color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google
                        _buildSocialButton(
                          label: 'Google',
                          icon: _GoogleLogo(),
                          onPressed: isLoading ? null : _handleGoogle,
                        ),
                        const SizedBox(width: 16),

                        // Apple — only show on iOS or macOS
                        if (defaultTargetPlatform == TargetPlatform.iOS ||
                            defaultTargetPlatform == TargetPlatform.macOS)
                          _buildSocialButton(
                            label: 'Apple',
                            icon: const Icon(Icons.apple_rounded,
                                size: 26, color: Colors.black87),
                            onPressed: isLoading ? null : _handleApple,
                          ),
                      ],
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 32),

                    Center(
                      child: TextButton(
                        onPressed: isLoading ? null : _handleDemo,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                        ),
                        child: Text(
                          'Try Demo (No Sign In)',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 800.ms),

                    const SizedBox(height: 30),

                    if (_isSignUpMode)
                      Center(
                          child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                                style: GoogleFonts.outfit(
                                    color: Colors.grey.shade500, fontSize: 12),
                                children: [
                                  const TextSpan(
                                      text:
                                          'By creating an account, you agree to our\n'),
                                  WidgetSpan(
                                      child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const TermsOfServiceScreen()));
                                    },
                                    child: Text('Terms of Service',
                                        style: GoogleFonts.outfit(
                                            color: AppColors.electricBlue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  )),
                                  const TextSpan(text: ' and '),
                                  WidgetSpan(
                                      child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const PrivacyPolicyScreen()));
                                    },
                                    child: Text('Privacy Policy',
                                        style: GoogleFonts.outfit(
                                            color: AppColors.electricBlue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  )),
                                  const TextSpan(text: '.'),
                                ])).animate().fadeIn(delay: 700.ms),
                      )),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // ── Full-screen loading overlay ────────────────────────────────
          if (isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.electricBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Reusable widgets ───────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: isPassword && obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(fontSize: 15),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey.shade100),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide:
                const BorderSide(color: AppColors.electricBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      );

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) =>
      SizedBox(
        width: double.infinity,
        height: 60,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.electricGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.electricBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      );

  Widget _buildSocialButton({
    required String label,
    required Widget icon,
    VoidCallback? onPressed,
  }) =>
      GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
}

/// Simple coloured G logo widget (avoids needing an SVG asset).
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 26,
        height: 26,
        child: CustomPaint(painter: _GoogleLogoPainter()),
      );
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Quadrant arcs
    final colors = [Colors.red, Colors.yellow, Colors.green, Colors.blue];
    final angles = [0.0, 90.0, 180.0, 270.0];
    for (int i = 0; i < 4; i++) {
      final p = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(
        rect,
        _deg(angles[i]),
        _deg(90),
        false,
        p,
      );
    }
  }

  double _deg(double d) => d * 3.14159265 / 180;

  @override
  bool shouldRepaint(_) => false;
}
