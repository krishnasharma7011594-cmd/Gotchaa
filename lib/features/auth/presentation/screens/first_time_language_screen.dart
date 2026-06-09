import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_colors.dart';

// ── Chat language map (same as LanguageSettingsScreen) ──────────────────────
const Map<String, TranslateLanguage> _chatLanguages = {
  'English': TranslateLanguage.english,
  'Hindi (हिन्दी)': TranslateLanguage.hindi,
  'Spanish (Español)': TranslateLanguage.spanish,
  'French (Français)': TranslateLanguage.french,
  'Arabic (العربية)': TranslateLanguage.arabic,
  'Portuguese (Português)': TranslateLanguage.portuguese,
  'Indonesian (Bahasa Indonesia)': TranslateLanguage.indonesian,
  'Russian (Русский)': TranslateLanguage.russian,
  'German (Deutsch)': TranslateLanguage.german,
  'Chinese (中文)': TranslateLanguage.chinese,
  'Japanese (日本語)': TranslateLanguage.japanese,
  'Korean (한국어)': TranslateLanguage.korean,
};

/// Full-screen language picker shown on first login / sign-up.
/// When the user taps "Get Started", it saves both preferences and marks
/// [hasPickedLanguageProvider] as true so it won't be shown again.
class FirstTimeLanguageScreen extends ConsumerStatefulWidget {
  const FirstTimeLanguageScreen({super.key});

  @override
  ConsumerState<FirstTimeLanguageScreen> createState() =>
      _FirstTimeLanguageScreenState();
}

class _FirstTimeLanguageScreenState
    extends ConsumerState<FirstTimeLanguageScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _step = 0; // 0 = app language, 1 = chat language

  String _selectedUiCode = 'en';
  TranslateLanguage _selectedChat = TranslateLanguage.english;

  final bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Pre-select the current system / saved language
    final savedCode = ref.read(languageProvider).languageCode;
    _selectedUiCode = savedCode;

    // Pre-select chat language to match UI language if possible
    final chatLang = _chatLanguages.values.firstWhere(
      (l) => l.bcpCode == savedCode,
      orElse: () => TranslateLanguage.english,
    );
    _selectedChat = chatLang;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Save both prefs and mark done ────────────────────────────────────────

  Future<void> _finish() async {
    // We don't show the loading overlay immediately to avoid "flicker" 
    // since SharedPreferences is very fast.
    
    try {
      // 1. Save UI language (now background-syncs to Firestore)
      await ref.read(languageProvider.notifier).setLanguage(_selectedUiCode);

      // 2. Save chat language
      final svc = ref.read(translationServiceProvider);
      await svc.setPreferredLanguage(_selectedChat);

      // 3. Try downloading the ML model in background
      _downloadModelQuietly(svc, _selectedChat);

      // 4. Mark language as picked (now background-syncs to Firestore)
      // This will trigger the AuthGate redirection in app_router.dart
      await ref.read(hasPickedLanguageProvider.notifier).markPicked();
    } catch (_) {
      // Fallback
      await ref.read(hasPickedLanguageProvider.notifier).markPicked();
    }
  }

  void _downloadModelQuietly(
      TranslationService svc, TranslateLanguage lang) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);
      if (!isOnline) return;
      final downloaded = await svc.isModelDownloaded(lang);
      if (!downloaded) await svc.downloadModel(lang);
    } catch (_) {}
  }

  void _nextStep() {
    if (_step == 0) {
      setState(() => _step = 1);
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _prevStep() {
    if (_step == 1) {
      setState(() => _step = 0);
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Decorative blobs ─────────────────────────────────────────────
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.electricBlue.withValues(alpha: 0.07),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.4, 0.4)),
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

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top header ─────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step indicator
                      Row(
                        children: [
                          _StepDot(active: _step == 0),
                          const SizedBox(width: 8),
                          _StepDot(active: _step == 1),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 500.ms),
                      const SizedBox(height: 20),
                      // Title
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Column(
                          key: ValueKey(_step),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _step == 0
                                  ? 'Choose your\nlanguage 🌐'
                                  : 'Chat translation\nlanguage 💬',
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _step == 0
                                  ? 'Pick the language for the app interface'
                                  : 'Messages will be translated into this language',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Language list pages ─────────────────────────────────
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _AppLanguagePage(
                        selectedCode: _selectedUiCode,
                        onSelect: (code) =>
                            setState(() => _selectedUiCode = code),
                      ),
                      _ChatLanguagePage(
                        selected: _selectedChat,
                        onSelect: (lang) =>
                            setState(() => _selectedChat = lang),
                      ),
                    ],
                  ),
                ),

                // ── Bottom action bar ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Row(
                    children: [
                      // Back button (only on step 2)
                      if (_step == 1)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _BackBtn(onTap: _prevStep),
                        )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideX(begin: -0.3),

                      // Primary button
                      Expanded(
                        child: _PrimaryButton(
                          label: _step == 0 ? 'Continue' : 'Get Started 🚀',
                          isLoading: _isSaving,
                          onPressed: _nextStep,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms)
                    .slideY(begin: 0.3),
              ],
            ),
          ),

          // ── Loading overlay ──────────────────────────────────────────────
          if (_isSaving)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.electricBlue,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
}

// ── App language page ─────────────────────────────────────────────────────────

class _AppLanguagePage extends StatelessWidget {

  const _AppLanguagePage({
    required this.selectedCode,
    required this.onSelect,
  });
  final String selectedCode;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const langs = AppLocalizationsConfig.languages;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: langs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final lang = langs[i];
        final isSelected = lang.code == selectedCode;
        return _LanguageTile(
          flag: lang.flag,
          nameNative: lang.nameNative,
          nameEn: lang.nameEn,
          isSelected: isSelected,
          onTap: () => onSelect(lang.code),
          index: i,
        );
      },
    );
  }
}

// ── Chat language page ────────────────────────────────────────────────────────

class _ChatLanguagePage extends StatelessWidget {

  const _ChatLanguagePage({
    required this.selected,
    required this.onSelect,
  });
  final TranslateLanguage selected;
  final ValueChanged<TranslateLanguage> onSelect;

  @override
  Widget build(BuildContext context) {
    final entries = _chatLanguages.entries.toList();

    return Column(
      children: [
        // Info banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('🌐', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The model will be downloaded on first use when you have internet.',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.electricBlue,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 8),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final entry = entries[i];
              final isSelected = entry.value == selected;
              return _LanguageTile(
                flag: '',
                nameNative: entry.key,
                nameEn: '',
                isSelected: isSelected,
                onTap: () => onSelect(entry.value),
                index: i,
                showFlag: false,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Shared tile ───────────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {

  const _LanguageTile({
    required this.flag,
    required this.nameNative,
    required this.nameEn,
    required this.isSelected,
    required this.onTap,
    required this.index,
    this.showFlag = true,
  });
  final String flag;
  final String nameNative;
  final String nameEn;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;
  final bool showFlag;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.electricBlue.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.electricBlue
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.electricBlue.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            if (showFlag) ...[
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameNative,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.electricBlue
                          : Colors.black87,
                    ),
                  ),
                  if (nameEn.isNotEmpty)
                    Text(
                      nameEn,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isSelected
                            ? AppColors.electricBlue.withValues(alpha: 0.7)
                            : Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.electricBlue, size: 22,
                      key: ValueKey('check'))
                  : const SizedBox(width: 22, key: ValueKey('empty')),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.15, curve: Curves.easeOut);
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color:
            active ? AppColors.electricBlue : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.black87, size: 20),
      ),
    );
}

class _PrimaryButton extends StatelessWidget {

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        decoration: BoxDecoration(
          gradient: isLoading
              ? const LinearGradient(
                  colors: [Colors.grey, Colors.grey],
                )
              : AppColors.electricGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.electricBlue.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
}
