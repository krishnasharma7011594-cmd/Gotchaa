import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../data/models/sound_model.dart';
import '../../data/repositories/music_repository.dart';
import 'sound_composer_screen.dart';
import '../../../../core/models/vybz_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';

class VybzUploadScreen extends ConsumerStatefulWidget {
  const VybzUploadScreen({super.key});

  @override
  ConsumerState<VybzUploadScreen> createState() => _VybzUploadScreenState();
}

class _VybzUploadScreenState extends ConsumerState<VybzUploadScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _videoFile;
  SoundModel? _attachedSound;
  List<String> suggestedHashtags = [];
  bool isAnalyzing = false;
  bool isPosting = false;

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _videoFile = video;
      });
    }
  }

  Future<void> _openSoundComposer() async {
    final sound = await Navigator.push<SoundModel>(
      context,
      MaterialPageRoute(
          builder: (_) => const SoundComposerScreen()),
    );
    if (sound != null && mounted) {
      setState(() => _attachedSound = sound);
    }
  }

  Future<void> _handlePost() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('vybz_select_error'))));
      return;
    }

    setState(() => isPosting = true);

    try {
      // 1. Upload video to Firebase Storage
      final storageRepo = ref.read(storageRepositoryProvider);
      final videoUrl = await storageRepo.uploadVideo(_videoFile!, user.uid);

      // 2. Save metadata to Firestore
      final vybz = VybzModel(
        id: '',
        creatorId: user.uid,
        videoUrl: videoUrl,
        caption: _captionController.text,
        hashtags: suggestedHashtags,
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreRepositoryProvider).postVybz(vybz);

      // Attach AI sound if the user picked one.
      // We fire-and-forget here since the post doc already exists.
      if (_attachedSound != null) {
        try {
          await ref
              .read(musicRepositoryProvider)
              .attachSoundToPost(_attachedSound!.soundId, vybz.id);
        } catch (_) {
          // Non-fatal — the post is already live.
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('vybz_post_success'))));
      }
    } catch (e) {
      if (mounted) {
        setState(() => isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr('error_prefix', args: [e.toString()]))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: Text(context.tr('vybz_upload_title'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          actions: [
            TextButton(
              onPressed: isPosting ? null : _handlePost,
              child: isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(context.tr('vybz_post_button'),
                      style: GoogleFonts.outfit(
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Preview / Picker
              GestureDetector(
                onTap: _pickVideo,
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _videoFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                const Center(
                                    child: Icon(Icons.video_library_rounded,
                                        size: 50, color: Colors.grey)),
                                Container(color: Colors.black26),
                                const Center(
                                    child: Icon(Icons.check_circle,
                                        size: 60, color: Colors.white)),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_rounded,
                                  size: 50, color: Colors.grey),
                              const SizedBox(height: 10),
                              Text(context.tr('vybz_select_video'),
                                  style:
                                      GoogleFonts.outfit(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // ── AI Sound attachment strip ──────────────────────────
              if (_attachedSound != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.electricBlue.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note_rounded,
                          color: AppColors.electricBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _attachedSound!.prompt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                              color: AppColors.electricBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _attachedSound = null),
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.electricBlue, size: 18),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _openSoundComposer,
                  icon: const Icon(Icons.music_note_rounded, size: 18),
                  label: Text('Add Sound',
                      style: GoogleFonts.outfit(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.electricBlue,
                    side: const BorderSide(color: AppColors.electricBlue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              const SizedBox(height: 16),

              Text(context.tr('vybz_caption_label'),
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: _captionController,
                maxLines: 3,
                style: GoogleFonts.outfit(),
                decoration: InputDecoration(
                  hintText: context.tr('vybz_caption_hint'),
                  fillColor: Colors.grey.shade50,
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              if (suggestedHashtags.isNotEmpty) ...[
                Text(context.tr('vybz_suggested_tags'),
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: suggestedHashtags
                      .map((tag) => Chip(
                            label: Text('#$tag',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppColors.electricBlue)),
                            backgroundColor:
                                AppColors.electricBlue.withOpacity(0.1),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      );
}
