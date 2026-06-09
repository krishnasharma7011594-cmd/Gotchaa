import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/screens/main_shell.dart';

class ProfilePictureUploadScreen extends ConsumerStatefulWidget {
  const ProfilePictureUploadScreen({super.key});

  @override
  ConsumerState<ProfilePictureUploadScreen> createState() => _ProfilePictureUploadScreenState();
}

class _ProfilePictureUploadScreenState extends ConsumerState<ProfilePictureUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageFile = image;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _handleFinish() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      String? photoUrl;
      if (_imageFile != null) {
        final storageRepo = ref.read(storageRepositoryProvider);
        photoUrl = await storageRepo.uploadImage(_imageFile!, user.uid);
      }

      if (photoUrl != null) {
        // Update Firestore profile
        final firestoreRepo = ref.read(firestoreRepositoryProvider);
        final profile = await firestoreRepo.getUserProfile(user.uid);
        if (profile != null) {
          final updatedProfile = profile.copyWith(photoUrl: photoUrl);
          await firestoreRepo.createUserProfile(updatedProfile); // set logic handles update
        }
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('error_prefix', args: [e.toString()]))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(height: 40),
              Text(
                context.tr('pfp_upload_title'),
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 12),
              Text(
                context.tr('pfp_upload_subtitle'),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 60),
              
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: _imageBytes != null 
                        ? ClipOval(child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                        : Icon(Icons.person_outline_rounded, size: 80, color: Colors.grey.shade400),
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.electricBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
              ),

              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _handleFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isUploading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _imageFile != null ? context.tr('pfp_finish') : context.tr('pfp_skip'),
                        style: GoogleFonts.outfit(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white,
                        ),
                      ),
                ),
              ).animate().fadeIn(delay: 600.ms),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
}
