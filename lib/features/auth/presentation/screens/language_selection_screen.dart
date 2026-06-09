import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'first_time_language_screen.dart' show FirstTimeLanguageScreen;
import 'interest_selection_screen.dart';
import 'onboarding_screen.dart' show OnboardingScreen;

/// Language selection during the onboarding flow (used by [OnboardingScreen]).
/// Unlike [FirstTimeLanguageScreen], this is part of the auth wizard
/// and simply saves the UI language before continuing.
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  String? _selectedCode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCode = ref.read(languageProvider).languageCode;
  }

  Future<void> _continue() async {
    if (_selectedCode == null) return;
    setState(() => _saving = true);
    await ref.read(languageProvider.notifier).setLanguage(_selectedCode!);
    if (!mounted) return;
    setState(() => _saving = false);
    unawaited(Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InterestSelectionScreen()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const langs = AppLocalizationsConfig.languages;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select your language',
                style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your primary language for the app interface.',
                style: GoogleFonts.outfit(
                    color: Colors.grey.shade500, fontSize: 15),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: langs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final lang = langs[index];
                    final isSelected = _selectedCode == lang.code;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCode = lang.code),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.electricBlue
                                  .withValues(alpha: 0.08)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.electricBlue
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(lang.flag,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.nameNative,
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
                                  Text(
                                    lang.nameEn,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: isSelected
                                          ? AppColors.electricBlue
                                              .withValues(alpha: 0.7)
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.electricBlue, size: 22),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _selectedCode != null
                        ? AppColors.electricGradient
                        : const LinearGradient(
                            colors: [Colors.grey, Colors.grey]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: _selectedCode != null
                        ? [
                            BoxShadow(
                              color: AppColors.electricBlue
                                  .withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            )
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _selectedCode == null || _saving
                        ? null
                        : _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Continue',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
