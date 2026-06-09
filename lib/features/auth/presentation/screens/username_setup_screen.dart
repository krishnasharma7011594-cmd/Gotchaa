import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'profile_picture_upload_screen.dart';

class UsernameSetupScreen extends ConsumerStatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  ConsumerState<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends ConsumerState<UsernameSetupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isAvailable = false;
  bool _isChecking = false;
  String? _errorMessage;
  List<String> _suggestions = [];
  Timer? _debounce;

  @override
  void dispose() {
    _usernameController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Quick local validation before hitting DB
    final service = ref.read(usernameServiceProvider);
    final error = service.validateUsername(val);
    
    if (error != null) {
      setState(() {
        _errorMessage = error;
        _isAvailable = false;
        _isChecking = false;
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isChecking = true;
      _isAvailable = false;
      _suggestions = [];
    });

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      await _checkAvailability(val);
    });
  }

  Future<void> _checkAvailability(String username) async {
    final service = ref.read(usernameServiceProvider);
    
    try {
      final available = await service.isUsernameAvailable(username);
      
      if (!mounted || _usernameController.text != username) return;

      if (available) {
        setState(() {
          _isAvailable = true;
          _isChecking = false;
        });
      } else {
        // Taken! Generate suggestions
        final suggestions = await service.generateSuggestions(username);
        
        if (!mounted || _usernameController.text != username) return;
        
        setState(() {
          _isAvailable = false;
          _isChecking = false;
          _errorMessage = 'Username already taken.';
          _suggestions = suggestions;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _errorMessage = 'Error checking username.';
        });
      }
    }
  }

  void _generateRandom() {
    final service = ref.read(usernameServiceProvider);
    final randomName = service.generateAnonymousUsername();
    _usernameController.text = randomName;
    _onUsernameChanged(randomName);
  }

  Future<void> _handleNext() async {
    final username = _usernameController.text.trim().toLowerCase();
    if (username.isEmpty || !_isAvailable) return;

    final authRepository = ref.read(authRepositoryProvider);
    try {
      await authRepository.completeProfileSetup(
        username: username,
        displayName: username,
      );
      AnalyticsService.logProfileCompleted();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePictureUploadScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Basic dynamic feedback colors
    Color borderColor = Colors.transparent;
    if (_usernameController.text.isNotEmpty) {
      if (_isChecking) {
        borderColor = AppColors.electricBlue;
      } else if (_isAvailable) {
        borderColor = Colors.green;
      } else if (_errorMessage != null) {
        borderColor = Colors.red;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: _generateRandom,
            child: Text(
              'Skip & Auto-generate',
              style: GoogleFonts.outfit(color: AppColors.electricBlue, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Create your\nusername',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  height: 1.1,
                  color: Colors.black,
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 12),
              Text(
                'This will be your unique identity on Gotchaa.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 40),
              
              // Input Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Row(
                  children: [
                    Text(
                      '@',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _usernameController,
                        focusNode: _focusNode,
                        onChanged: _onUsernameChanged,
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
                        decoration: const InputDecoration(
                          hintText: 'username',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    if (_isChecking)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.electricBlue),
                      )
                    else if (_isAvailable)
                      const Icon(Icons.check_circle_rounded, color: Colors.green)
                    else if (_errorMessage != null && !_isAvailable && _usernameController.text.isNotEmpty)
                      const Icon(Icons.cancel_rounded, color: Colors.red),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
              
              const SizedBox(height: 10),

              // Status / Error message
              if (_isAvailable && _usernameController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    'Username is available!',
                    style: GoogleFonts.outfit(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ).animate().fadeIn()
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.outfit(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ).animate().fadeIn(),

              const SizedBox(height: 24),

              // Suggestions Block
              if (_suggestions.isNotEmpty) ...[
                Text(
                  'Suggestions:',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ).animate().fadeIn(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _suggestions.map((sug) => ActionChip(
                    label: Text('@$sug', style: GoogleFonts.outfit(color: AppColors.electricBlue, fontWeight: FontWeight.bold)),
                    backgroundColor: AppColors.electricBlue.withValues(alpha: 0.1),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () {
                      _usernameController.text = sug;
                      _onUsernameChanged(sug);
                    },
                  )).toList(),
                ).animate().fadeIn(),
              ],

              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isAvailable ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Confirm and Next',
                    style: GoogleFonts.outfit(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: _isAvailable ? Colors.white : Colors.grey.shade500
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
