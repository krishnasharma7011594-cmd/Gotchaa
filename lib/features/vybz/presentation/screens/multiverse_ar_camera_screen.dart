import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import '../../../../core/models/user_profile.dart';
import '../../../../core/models/vybz_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';

class MultiverseARCameraScreen extends ConsumerStatefulWidget {
  const MultiverseARCameraScreen({super.key});

  @override
  ConsumerState<MultiverseARCameraScreen> createState() =>
      _MultiverseARCameraScreenState();
}

class _MultiverseARCameraScreenState
    extends ConsumerState<MultiverseARCameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  final ImagePicker _picker = ImagePicker();
  String _activeMode = 'STORY'; // POST, STORY, REEL, LIVE

  // Multiverse Styles
  final List<String> _multiverseStyles = [
    'Glow Up',
    'Dark Mode',
    'Anime',
    'Royal',
    'Cyber'
  ];
  int _activeStyleIndex = 0;

  // Animations
  late AnimationController _shutterController;

  @override
  void initState() {
    super.initState();
    _shutterController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Find front camera for AR face filters
        final frontCamera = _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => _cameras.first);

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: true,
        );

        final controller = _cameraController;
        if (controller != null) {
          await controller.initialize();
          if (mounted) {
            setState(() {
              _isCameraInitialized = true;
            });
          }
        }
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _shutterController.dispose();
    super.dispose();
  }

  void _switchStyle(int index) {
    if (_activeStyleIndex == index) return;
    setState(() {
      _activeStyleIndex = index;
    });
    // Trigger transition haptics/sounds here
  }

  Future<void> _toggleRecording() async {
    final profile = ref.read(currentUserProfileProvider).asData?.value;
    if (profile?.isLimitedUser ?? false) {
      _showLimitedAccessNotice(context);
      return;
    }

    if (_isRecording) {
      setState(() {
        _isRecording = false;
      });
      _shutterController.stop();
      _shutterController.reset();

      try {
        final XFile? videoFile = await _cameraController?.stopVideoRecording();
        if (videoFile != null) {
          _processAndUploadVybz(videoFile, profile);
        }
      } catch (e) {}
    } else {
      try {
        await _cameraController?.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
        _shutterController.repeat(reverse: true);
      } catch (e) {}
    }
  }

  Future<void> _pickFromGallery() async {
    final profile = ref.read(currentUserProfileProvider).asData?.value;
    if (profile?.isLimitedUser ?? false) {
      _showLimitedAccessNotice(context);
      return;
    }

    try {
      final XFile? media = await _picker.pickMedia();
      if (media != null) {
        if (media.path.endsWith('.mp4') || media.path.endsWith('.mov')) {
          _processAndUploadVybz(media, profile);
        } else {
          _processAndUploadImage(media, profile);
        }
      }
    } catch (e) {}
  }

  Future<void> _processAndUploadImage(XFile file, UserProfile? profile) async {
    if (profile == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLoadingOverlay('Uploading Photo...'),
    );

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
          'vybz/${profile.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(
          File(file.path), SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await storageRef.getDownloadURL();

      final vybz = VybzModel(
        id: '',
        creatorId: profile.uid,
        creatorUsername: profile.username,
        creatorPhoto: profile.photoUrl ?? '',
        videoUrl: downloadUrl, // Reusing field for simplicity in MVP
        caption: 'Shared from my gallery! 📸',
        likesCount: 0,
        tips: 0,
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreRepositoryProvider).postVybz(vybz);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Close camera
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo shared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Widget _buildLoadingOverlay(String message) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primaryGlow),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Optimizing for the Multiverse',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Future<void> _processAndUploadVybz(XFile file, UserProfile? profile) async {
    if (profile == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLoadingOverlay('Compressing & Uploading...'),
    );

    try {
      // 1. Compress Video
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false, // Keep the original just in case
        includeAudio: true,
      );

      final File fileToUpload = mediaInfo?.file ?? File(file.path);

      // 2. Upload to Storage
      final storageRef = FirebaseStorage.instance.ref().child(
          'vybz/${profile.uid}/${DateTime.now().millisecondsSinceEpoch}.mp4');
      await storageRef.putFile(
          fileToUpload, SettableMetadata(contentType: 'video/mp4'));
      final downloadUrl = await storageRef.getDownloadURL();

      // Cleanup
      await VideoCompress.deleteAllCache();

      final vybz = VybzModel(
        id: '',
        creatorId: profile.uid,
        creatorUsername: profile.username,
        creatorPhoto: profile.photoUrl ?? '',
        videoUrl: downloadUrl,
        caption:
            'Exploring the ${_multiverseStyles[_activeStyleIndex]} Multiverse! ✨',
        likesCount: 0,
        tips: 0,
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreRepositoryProvider).postVybz(vybz);

      if (mounted) {
        Navigator.pop(context); // Close uploading dialog
        Navigator.pop(context); // Close camera screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vybz successfully posted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post Vybz: $e')),
        );
      }
    }
  }

  void _showLimitedAccessNotice(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Recording Restricted',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'AR recording and posting are restricted for limited users. Enter an invite code to unlock!',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uid = ref.read(currentUserProvider)?.uid;
              if (uid != null) {
                await ref.read(firestoreRepositoryProvider).setLimitedAccess(
                      uid: uid,
                      isLimited: false,
                    );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Camera View or Mock AR View
            if (_isCameraInitialized && _cameraController != null)
              Transform.scale(
                scale: _cameraController!.value.isInitialized
                    ? _cameraController!.value.aspectRatio *
                        MediaQuery.of(context).size.aspectRatio
                    : 1.0,
                child: Center(
                  child: CameraPreview(_cameraController!),
                ),
              )
            else
              Container(
                // Mock View if camera fails or is loading
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.darkBg,
                      _getStyleColor().withOpacity(0.3),
                    ],
                  ),
                ),
                child: const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryGlow),
                ),
              ),

            // AR Effects Overlay Simulation
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                    color: _getStyleColor().withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 20,
                  )
                ]),
              ),
            ),

            // 2. Top Bar (Controls)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppColors.primaryGlow, size: 20),
                        const SizedBox(width: 8),
                        Text('Multiverse Mirror',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ).animate().fade().slideY(begin: -0.5),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios,
                        color: Colors.white, size: 28),
                    onPressed: () {
                      // Switch camera logic
                    },
                  ),
                ],
              ),
            ),

            // 3. Interactive Controls Hints
            Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text('Blink to switch version',
                              style: GoogleFonts.outfit(
                                  color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('Smile to transform',
                              style: GoogleFonts.outfit(
                                  color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true))
                    .fadeIn(duration: 1.seconds)
                    .then(delay: 2.seconds)
                    .fadeOut(duration: 1.seconds),
              ),
            ),

            // 4. Multiverse Selector Carousel
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  itemCount: _multiverseStyles.length,
                  itemBuilder: (context, index) {
                    final isActive = _activeStyleIndex == index;
                    return GestureDetector(
                      onTap: () => _switchStyle(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: isActive ? 80 : 60,
                        height: isActive ? 80 : 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive
                                ? _getStyleColor()
                                : Colors.white.withOpacity(0.3),
                            width: isActive ? 3 : 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                      color: _getStyleColor().withOpacity(0.5),
                                      blurRadius: 15,
                                      spreadRadius: 5)
                                ]
                              : [],
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _getStyleColor(index).withOpacity(0.8),
                                Colors.black54,
                              ]),
                        ),
                        child: Center(
                          child: Text(
                            _multiverseStyles[index].split(' ').first,
                            style: GoogleFonts.outfit(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                              fontSize: isActive ? 12 : 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 5. Shutter Area & Gallery
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery Icon
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: const Icon(Icons.photo_library,
                          color: Colors.white, size: 24),
                    ),
                  ),

                  // Shutter Button
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: AnimatedBuilder(
                        animation: _shutterController,
                        builder: (context, child) => Container(
                              width: 80 + (_shutterController.value * 10),
                              height: 80 + (_shutterController.value * 10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _isRecording
                                        ? AppColors.error
                                        : Colors.white,
                                    width: 4),
                                boxShadow: _isRecording
                                    ? [
                                        BoxShadow(
                                            color: AppColors.error
                                                .withOpacity(0.6),
                                            blurRadius: 20,
                                            spreadRadius: 5)
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: _isRecording ? 30 : 65,
                                  height: _isRecording ? 30 : 65,
                                  decoration: BoxDecoration(
                                    color: _isRecording
                                        ? AppColors.error
                                        : AppColors.error.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(
                                        _isRecording ? 8 : 40),
                                  ),
                                ),
                              ),
                            )),
                  ),

                  // Flip Camera
                  GestureDetector(
                    onTap: () {
                      // Logic to flip camera
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flip_camera_ios,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            // 6. Instagram Style Mode Selector
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  ),
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: ['POST', 'STORY', 'REEL', 'LIVE'].map((mode) {
                    final isSelected = _activeMode == mode;
                    return GestureDetector(
                      onTap: () => setState(() => _activeMode = mode),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            mode,
                            style: GoogleFonts.outfit(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );

  Color _getStyleColor([int? index]) {
    final styleIndex = index ?? _activeStyleIndex;
    switch (styleIndex) {
      case 0:
        return AppColors.karmaAura; // Glow Up
      case 1:
        return Colors.deepPurple; // Dark Mode
      case 2:
        return Colors.pinkAccent; // Anime
      case 3:
        return Colors.amber; // Royal
      case 4:
        return AppColors.primaryGlow; // Cyber
      default:
        return Colors.white;
    }
  }
}
