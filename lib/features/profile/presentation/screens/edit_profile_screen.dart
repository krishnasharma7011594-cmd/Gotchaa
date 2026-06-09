import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/age_tier.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/providers/age_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({required this.profile, super.key});
  final UserProfile profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;
  String? _usernameError;
  DateTime? _selectedDob;
  String? _selectedLanguage;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Español'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'de', 'name': 'Deutsch'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'zh', 'name': 'Chinese'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'ko', 'name': 'Korean'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _usernameController = TextEditingController(text: widget.profile.username);
    _bioController = TextEditingController(text: widget.profile.bio);
    _selectedDob = widget.profile.birthday;
    _selectedLanguage = widget.profile.language ?? 'en';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ── Pick image from gallery ──────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
      });
    }
  }

  // ── Validate username ────────────────────────────────────────────────

  Future<bool> _validateUsername() async {
    final username = _usernameController.text.trim().toLowerCase();

    if (username.isEmpty) {
      setState(() => _usernameError = null);
      return true; // Username is optional
    }

    if (username.length < 3) {
      setState(() => _usernameError = 'Username must be at least 3 characters');
      return false;
    }

    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      setState(() =>
          _usernameError = 'Only lowercase letters, numbers, underscores');
      return false;
    }

    final profileRepo = ref.read(profileRepositoryProvider);
    final available =
        await profileRepo.isUsernameAvailable(username, widget.profile.uid);

    if (!available) {
      setState(() => _usernameError = 'Username already taken');
      return false;
    }

    setState(() => _usernameError = null);
    return true;
  }

  // ── Save profile ─────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Display name cannot be empty');
      return;
    }

    final bio = _bioController.text.trim();
    if (bio.length > 150) {
      setState(() => _errorMessage = 'Bio must be 150 characters or less');
      return;
    }

    final usernameValid = await _validateUsername();
    if (!usernameValid) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final storageRepo = ref.read(storageRepositoryProvider);
      final uid = widget.profile.uid;
      final newUsername = _usernameController.text.trim().toLowerCase();
      String? photoUrl;

      // Upload profile picture if changed
      if (_selectedImage != null) {
        setState(() => _isUploadingPhoto = true);
        photoUrl = await storageRepo.uploadProfilePicture(
          _selectedImage!,
          uid,
        );
        setState(() => _isUploadingPhoto = false);
      }

      // Update username atomically if changed
      if (newUsername != widget.profile.username) {
        final usernameService = ref.read(usernameServiceProvider);
        await usernameService.updateUsername(
          userId: uid,
          oldUsername: widget.profile.username,
          newUsername: newUsername,
        );
      }

      // Update profile fields
      await profileRepo.updateProfile(
        uid: uid,
        displayName: name,
        username: newUsername,
        bio: bio,
        photoUrl: photoUrl,
        birthday: _selectedDob,
        language: _selectedLanguage,
        ageTier: _selectedDob != null
            ? _calculateAgeTier(_selectedDob!).index
            : widget.profile.ageTier,
        ageVerified: _selectedDob != null || widget.profile.ageVerified,
        hasPickedLanguage: true,
      );

      // Sync local providers
      if (_selectedDob != null) {
        final ageNotifier = ref.read(ageProvider.notifier);
        ageNotifier.verifyAge(_selectedDob!, _calculateAgeTier(_selectedDob!));
      }

      if (_selectedLanguage != null) {
        await ref
            .read(languageProvider.notifier)
            .setLanguage(_selectedLanguage!);
        await ref.read(hasPickedLanguageProvider.notifier).markPicked();
      }

      // Log profile completion if criteria met (username + photo + bio)
      final finalUsername = newUsername;
      final finalPhoto = photoUrl ?? widget.profile.photoUrl;
      final finalBio = bio;

      if (finalUsername.isNotEmpty &&
          finalPhoto.isNotEmpty &&
          finalBio.isNotEmpty) {
        AnalyticsService.logProfileCompleted();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated!',
                style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save: ${e.toString()}';
        _isSaving = false;
        _isUploadingPhoto = false;
      });
    }
  }

  AgeTier _calculateAgeTier(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    if (age < 13) return AgeTier.under13Blocked;
    if (age < 18) return AgeTier.teen;
    return AgeTier.adult;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FB),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black, size: 20),
          ),
          title: Text(
            'Edit Profile',
            style: GoogleFonts.outfit(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Save',
                        style: GoogleFonts.outfit(
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // ── Avatar ──────────────────────────────────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    if (_selectedImageBytes != null)
                      CircleAvatar(
                        radius: 56,
                        backgroundImage: MemoryImage(_selectedImageBytes!),
                      )
                    else
                      CachedNetworkImage(
                        imageUrl: widget.profile.photoUrl,
                        imageBuilder: (context, imageProvider) => CircleAvatar(
                          radius: 56,
                          backgroundImage: imageProvider,
                        ),
                        placeholder: (context, url) => const CircleAvatar(
                          radius: 56,
                          child: BlurHash(hash: 'L5H2EC=pPdpWXVJs00QQV_9H00XY'),
                        ),
                        errorWidget: (context, url, error) => CircleAvatar(
                          radius: 56,
                          backgroundColor: Colors.grey.shade200,
                          child: Icon(Icons.person_rounded,
                              size: 48, color: Colors.grey.shade400),
                        ),
                      ),
                    if (_isUploadingPhoto)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.electricBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'Tap to change photo',
                style: GoogleFonts.outfit(
                  color: AppColors.electricBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 32),

              // ── Display Name field ──────────────────────────────────
              _buildField(
                label: 'Display Name',
                controller: _nameController,
                hint: 'Your display name',
                icon: Icons.person_outline_rounded,
              ),

              const SizedBox(height: 20),

              // ── Username field ──────────────────────────────────────
              _buildField(
                label: 'Username',
                controller: _usernameController,
                hint: 'your_username',
                icon: Icons.alternate_email_rounded,
                error: _usernameError,
                onChanged: (_) {
                  if (_usernameError != null) {
                    setState(() => _usernameError = null);
                  }
                },
              ),

              const SizedBox(height: 20),

              // ── Bio field ───────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bio',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _bioController,
                      maxLines: 4,
                      maxLength: 150,
                      style: GoogleFonts.outfit(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Tell people about yourself…',
                        hintStyle: GoogleFonts.outfit(
                            color: Colors.grey.shade400, fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        counterStyle: GoogleFonts.outfit(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Personal Info Section ───────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Personal Information',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date of Birth
              _buildSelectionTile(
                label: 'Date of Birth',
                value: _selectedDob != null
                    ? DateFormat('MMM dd, yyyy').format(_selectedDob!)
                    : 'Not set',
                icon: Icons.cake_rounded,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDob ?? DateTime(2000),
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDob = picked);
                  }
                },
              ),

              const SizedBox(height: 12),

              // Language
              _buildSelectionTile(
                label: 'App Language',
                value: _languages.firstWhere(
                    (l) => l['code'] == _selectedLanguage,
                    orElse: () => {'name': 'English'})['name']!,
                icon: Icons.language_rounded,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24))),
                    builder: (ctx) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Select Language',
                              style: GoogleFonts.outfit(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _languages.length,
                              itemBuilder: (context, index) {
                                final lang = _languages[index];
                                return ListTile(
                                  title: Text(lang['name']!,
                                      style: GoogleFonts.outfit()),
                                  trailing: _selectedLanguage == lang['code']
                                      ? const Icon(Icons.check_circle,
                                          color: AppColors.electricBlue)
                                      : null,
                                  onTap: () {
                                    setState(
                                        () => _selectedLanguage = lang['code']);
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // ── Error message ───────────────────────────────────────
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: Colors.red.shade400, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.outfit(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      );

  // ── Reusable text field ────────────────────────────────────────────────

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? error,
    ValueChanged<String>? onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    error != null ? Colors.red.shade300 : Colors.grey.shade200,
              ),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.outfit(fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.outfit(
                    color: Colors.grey.shade400, fontSize: 15),
                prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                error,
                style: GoogleFonts.outfit(
                  color: Colors.red.shade400,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      );

  Widget _buildSelectionTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey.shade400, size: 22),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500)),
                  Text(value,
                      style: GoogleFonts.outfit(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey.shade300),
            ],
          ),
        ),
      );
}
