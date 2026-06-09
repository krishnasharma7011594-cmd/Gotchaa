import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/models/age_tier.dart';
import '../../../../core/providers/age_provider.dart';
import '../../../../core/theme/app_colors.dart';

class AgeVerificationScreen extends ConsumerStatefulWidget {
  const AgeVerificationScreen({super.key});

  @override
  ConsumerState<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends ConsumerState<AgeVerificationScreen> {
  int _selectedDay = 1;
  int _selectedMonthIndex = 0; // 0 = January
  late int _selectedYear;
  
  bool _isSaving = false;
  bool _parentEmailSent = false;
  bool _isCheckingStatus = false;
  final TextEditingController _parentEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  late final int _currentYear;
  late final int _minYear;
  late final int _maxYear;

  @override
  void initState() {
    super.initState();
    _currentYear = DateTime.now().year;
    _minYear = _currentYear - 100;
    _maxYear = _currentYear;
    _selectedYear = _currentYear - 20; // Default to 20 years ago
  }
  
  @override
  void dispose() {
    _parentEmailController.dispose();
    super.dispose();
  }

  int get _daysInMonth {
    // Return days in the currently selected month and year
    final nextMonth = DateTime(_selectedYear, _selectedMonthIndex + 2, 0);
    return nextMonth.day;
  }

  DateTime get _selectedDate {
    final maxDays = _daysInMonth;
    final day = _selectedDay > maxDays ? maxDays : _selectedDay;
    return DateTime(_selectedYear, _selectedMonthIndex + 1, day);
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _onConfirm() async {
    setState(() => _isSaving = true);
    try {
      final dob = _selectedDate;
      await ref.read(ageProvider.notifier).setDateOfBirth(dob);
      final ageStatus = ref.read(ageProvider);
      
      if (mounted) {
        if (ageStatus.tier == AgeTier.under13Blocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Under 13 block applied. Safety first!'),
              backgroundColor: AppColors.error,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('age_verification_success') ?? 'Age verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('age_verification_error') ?? 'Failed to verify age. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitParentalEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      await ref.read(ageProvider.notifier).submitParentalConsent(_parentEmailController.text.trim());
      setState(() {
        _parentEmailSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parental consent request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit parental email. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _checkStatus() async {
    setState(() => _isCheckingStatus = true);
    try {
      final approved = await ref.read(ageProvider.notifier).checkParentalConsentStatus();
      if (mounted) {
        if (approved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Parental consent approved! Welcome to GOTCHAA!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Consent is still pending parent approval.'),
              backgroundColor: AppColors.karmaOrange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error checking status. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ageStatus = ref.watch(ageProvider);
    final calculatedAge = _calculateAge(_selectedDate);

    // If completely blocked under 13, show the safety screen with parental consent flow
    if (ageStatus.tier == AgeTier.under13Blocked) {
      return _buildBlockedScreen(isDark);
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [const Color(0xFF070708), const Color(0xFF121214)]
                : [Colors.white, const Color(0xFFF0F4F8)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(),
                      
                      // Branded Shield/Verification Header
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.electricBlue.withOpacity(0.15),
                                AppColors.vibrantPurple.withOpacity(0.15),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.electricBlue.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ]
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: AppColors.electricBlue,
                            size: 64,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          context.tr('age_verification_title') ?? 'Age Verification',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            context.tr('age_verification_subtitle') ?? 
                            'Select your date of birth. This helps us customize your safety experience and compliant settings.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              color: isDark ? Colors.white70 : Colors.black54,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Premium Scrollable Cupertino Wheels Container
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 300),
                        child: Container(
                          height: 200,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                )
                            ],
                          ),
                          child: Row(
                            children: [
                              // Month Wheel
                              Expanded(
                                flex: 3,
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(
                                    initialItem: _selectedMonthIndex,
                                  ),
                                  itemExtent: 40,
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      _selectedMonthIndex = index;
                                      // Dynamic clamp day
                                      final maxDays = _daysInMonth;
                                      if (_selectedDay > maxDays) {
                                        _selectedDay = maxDays;
                                      }
                                    });
                                  },
                                  children: _months.map((month) => Center(
                                    child: Text(
                                      month,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ),
                              // Day Wheel
                              Expanded(
                                flex: 2,
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(
                                    initialItem: _selectedDay - 1,
                                  ),
                                  itemExtent: 40,
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      _selectedDay = index + 1;
                                    });
                                  },
                                  children: List.generate(_daysInMonth, (index) => Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )),
                                ),
                              ),
                              // Year Wheel
                              Expanded(
                                flex: 2,
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(
                                    initialItem: _selectedYear - _minYear,
                                  ),
                                  itemExtent: 40,
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      _selectedYear = _minYear + index;
                                      // Dynamic clamp day
                                      final maxDays = _daysInMonth;
                                      if (_selectedDay > maxDays) {
                                        _selectedDay = maxDays;
                                      }
                                    });
                                  },
                                  children: List.generate(_maxYear - _minYear + 1, (index) => Center(
                                    child: Text(
                                      '${_minYear + index}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Calculated dynamic status preview
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: calculatedAge < 13
                                ? AppColors.error.withOpacity(0.1)
                                : (calculatedAge < 18 
                                    ? AppColors.karmaOrange.withOpacity(0.1)
                                    : AppColors.electricBlue.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                calculatedAge < 13 
                                    ? Icons.warning_rounded 
                                    : (calculatedAge < 18 ? Icons.child_care_rounded : Icons.check_circle_rounded),
                                size: 20,
                                color: calculatedAge < 13
                                    ? AppColors.error
                                    : (calculatedAge < 18 ? AppColors.karmaOrange : AppColors.electricBlue),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Age: $calculatedAge • ${_getTierString(calculatedAge)}',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: calculatedAge < 13
                                      ? AppColors.error
                                      : (calculatedAge < 18 ? AppColors.karmaOrange : AppColors.electricBlue),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          context.tr('age_verification_note') ?? 
                          'Once confirmed, your age status cannot be changed without customer support to protect minors.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      const SizedBox(height: 24),
                      
                      // Action Confirm Button
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 500),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _onConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.electricBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _isSaving
                                ? const CupertinoActivityIndicator(color: Colors.white)
                                : Text(
                                    context.tr('age_verification_confirm') ?? 'Confirm Birthdate',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String _getTierString(int age) {
    if (age < 13) return 'Under 13 (Blocked)';
    if (age <= 15) return 'Junior Mode (13-15)';
    if (age <= 17) return 'Teen Mode (16-17)';
    return 'Full Access (18+)';
  }

  Widget _buildBlockedScreen(bool isDark) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [const Color(0xFF0F0404), const Color(0xFF1C0909)]
                : [const Color(0xFFFFF5F5), const Color(0xFFFFE3E3)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.gpp_bad_rounded,
                          color: AppColors.error,
                          size: 72,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        'Access Restricted',
                        style: GoogleFonts.outfit(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          'GOTCHAA is not available for users under 13. We care about keeping young people safe online.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // COPPA Parental Consent section
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                      child: Card(
                        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.family_restroom_rounded,
                                    color: AppColors.electricBlue,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Parental Consent Flow',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Under COPPA guidelines, a parent or legal guardian must confirm your registration to unlock a safe, limited account.',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (!_parentEmailSent) ...[
                                Text(
                                  "Parent's Email Address",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.black.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _parentEmailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: GoogleFonts.outfit(
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'parent@example.com',
                                    hintStyle: GoogleFonts.outfit(
                                      color: isDark ? Colors.white30 : Colors.black38,
                                    ),
                                    filled: true,
                                    fillColor: isDark ? Colors.black.withOpacity(0.25) : Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter parent\'s email';
                                    }
                                    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                    if (!regex.hasMatch(value.trim())) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _submitParentalEmail,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.electricBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isSaving
                                        ? const CupertinoActivityIndicator(color: Colors.white)
                                        : Text(
                                            'Send Consent Request',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.electricBlue.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.electricBlue.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.mark_email_read_rounded,
                                        color: AppColors.electricBlue,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Request Sent!',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'We sent an email to ${_parentEmailController.text.trim()}. Please ask them to approve your request.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: isDark ? Colors.white70 : Colors.black54,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: _isCheckingStatus ? null : _checkStatus,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.electricBlue,
                                      side: const BorderSide(color: AppColors.electricBlue),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isCheckingStatus
                                        ? const CupertinoActivityIndicator(color: AppColors.electricBlue)
                                        : Text(
                                            'Check Approval Status',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _parentEmailSent = false;
                                      });
                                    },
                                    child: Text(
                                      'Change Email Address',
                                      style: GoogleFonts.outfit(
                                        color: isDark ? Colors.white54 : Colors.black54,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
