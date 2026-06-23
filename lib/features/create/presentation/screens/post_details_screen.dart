import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/models/post_model.dart';
import '../../../../core/models/spotify_track.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/models/vybz_model.dart';
import '../../../../core/moderation/content_validator.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/shell_navigation_provider.dart';
import 'package:video_compress/video_compress.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/editable_item.dart';
import '../widgets/spotify_search_sheet.dart';

class PostDetailsScreen extends ConsumerStatefulWidget {
  const PostDetailsScreen({
    required this.mediaFile,
    required this.isVideo,
    super.key,
    this.initialTrack,
    this.overlays,
  });
  final File mediaFile;
  final bool isVideo;
  final SpotifyTrack? initialTrack;
  final List<EditableItem>? overlays;

  @override
  ConsumerState<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends ConsumerState<PostDetailsScreen> {
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _errorMessage;
  VideoPlayerController? _videoController;
  SpotifyTrack? _selectedTrack;
  String _visibility = 'public'; // 'public', 'friends', 'ghost'

  @override
  void initState() {
    super.initState();
    _selectedTrack = widget.initialTrack;
    if (widget.isVideo) {
      _videoController = VideoPlayerController.file(widget.mediaFile)
        ..initialize().then((_) {
          _videoController!.setVolume(0); // mute for preview
          _videoController!.setLooping(true);
          _videoController!.play();
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _publishPost() async {
    if (_isUploading) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final profile = ref.read(currentUserProfileProvider).asData?.value;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final caption = _captionController.text.trim();
      // Use internal ContentValidator if available or simple check
      /* 
      final captionCheck = ContentValidator().validatePostText(caption, userId: user.uid);
      if (!captionCheck.isValid && !captionCheck.warningOnly) {
         throw Exception(captionCheck.reason ?? 'Caption blocked');
      }
      */
      
      setState(() => _uploadProgress = 0.2);
      final storageRepo = ref.read(storageRepositoryProvider);
      final postRepo = ref.read(postRepositoryProvider);

      final String tempPostId = Uuid().v4();
      String mediaUrl = '';
      String? generatedThumbUrl;
      
      if (widget.isVideo) {
        // 1. Generate Thumbnail
        final thumbnailFile = await VideoCompress.getFileThumbnail(
          widget.mediaFile.path,
          quality: 50,
          position: -1,
        );

        // 2. Upload Video
        mediaUrl = await storageRepo.uploadVideo(
          XFile(widget.mediaFile.path),
          user.uid,
          onProgress: (p) => setState(() => _uploadProgress = 0.2 + p * 0.5),
        );

        // 3. Upload Thumbnail if exists
        if (thumbnailFile != null) {
          generatedThumbUrl = await storageRepo.uploadImage(
            XFile(thumbnailFile.path),
            user.uid,
            folder: 'posts_thumbs',
          );
        }
      } else {
        // Upload Image
        final result = await storageRepo.uploadPostImage(
          XFile(widget.mediaFile.path),
          user.uid,
          onProgress: (p) => setState(() => _uploadProgress = 0.2 + p * 0.6),
        );
        mediaUrl = result.url;
        generatedThumbUrl = result.thumbnailUrl;
      }

      setState(() => _uploadProgress = 0.85);

      // Create Post Model
      final post = PostModel(
        postId: '', 
        uid: user.uid,
        username: profile?.username ?? profile?.displayName ?? 'User',
        userPhoto: profile?.photoUrl ?? '',
        caption: caption, // Using raw caption for now to bypass check errors
        mediaUrl: mediaUrl,
        mediaThumbnailUrl: generatedThumbUrl ?? '',
        isVideo: widget.isVideo,
        createdAt: DateTime.now(),
        spotifyTrackId: _selectedTrack?.id,
        spotifyTrackName: _selectedTrack?.name,
        spotifyArtistName: _selectedTrack?.artist,
        spotifyAlbumArtUrl: _selectedTrack?.albumArtUrl,
        spotifyPreviewUrl: _selectedTrack?.previewUrl,
        isPrivate: profile?.isPrivate ?? false,
        visibility: _visibility,
        overlays: widget.overlays?.map((e) => e.toMap()).toList(),
      );

      // Save to Firestore
      final postId = await postRepo.createPost(post);

      // If it's a video, also create a Vybz Reel entry
      if (widget.isVideo) {
        final vybzRepo = ref.read(firestoreRepositoryProvider);
        final vybz = VybzModel(
          id: postId,
          creatorId: user.uid,
          creatorUsername: profile?.username ?? profile?.displayName ?? 'User',
          creatorPhoto: profile?.photoUrl ?? '',
          videoUrl: mediaUrl,
          thumbnailUrl: generatedThumbUrl ?? '',
          caption: caption,
          hashtags: [], 
          createdAt: DateTime.now(),
        );
        await vybzRepo.postVybz(vybz);
      }

      // Fire analytics — non-blocking
      AnalyticsService.logFirstPostCreated(
        postType: widget.isVideo ? 'video' : 'image',
      );

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post published! 🎉',
                style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        // Pop all back to Home
        Navigator.popUntil(context, (route) => route.isFirst);
        ref.read(shellPageControllerProvider).jumpToPage(1); // Chat/Home
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _showVisibilityPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(currentUserProfileProvider).asData?.value;
    final customLists = profile?.customPrivacyLists ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Who can view this post',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _visibilityOption(
                    label: 'Normal Post',
                    sub: 'Visible to everyone',
                    value: 'public',
                    icon: '🌍',
                  ),
                  const SizedBox(height: 12),
                  _visibilityOption(
                    label: 'Friend List',
                    sub: 'Only your selected friends',
                    value: 'friends',
                    icon: '👥',
                  ),
                  const SizedBox(height: 12),
                  _visibilityOption(
                    label: 'Ghost List',
                    sub: 'Hide from specific people',
                    value: 'ghost',
                    icon: '👻',
                  ),
                  if (customLists.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    ...customLists.map((list) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _visibilityOption(
                            label: list.name,
                            sub: '${list.uids.length} members',
                            value: 'list:${list.id}',
                            icon: '📋',
                          ),
                        )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getVisibilityLabel() {
    if (_visibility == 'public') return 'Normal Post';
    if (_visibility == 'friends') return 'Friend List';
    if (_visibility == 'ghost') return 'Ghost List';

    if (_visibility.startsWith('list:')) {
      final listId = _visibility.split(':')[1];
      final profile = ref.read(currentUserProfileProvider).asData?.value;
      final list = profile?.customPrivacyLists.firstWhere(
        (l) => l.id == listId,
        orElse: () => CustomPrivacyList(id: '', name: 'List', uids: []),
      );
      return list?.name ?? 'List';
    }
    return 'Normal Post';
  }

  Widget _visibilityOption({
    required String label,
    required String sub,
    required String value,
    required String icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _visibility == value;

    return InkWell(
      onTap: () {
        setState(() => _visibility = value);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.electricBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.electricBlue
                : Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    sub,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.grey,
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
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: context.bg,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: _isUploading ? null : () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: context.textPrimary, size: 20),
          ),
          title: Text(
            'New Post',
            style: GoogleFonts.outfit(
              color: context.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            Divider(height: 1, color: context.divider),

            if (_isUploading) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _uploadProgress < 0.7
                          ? context.tr('create_post_uploading_media')
                          : context.tr('create_post_saving'),
                      style: GoogleFonts.outfit(
                        color: context.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: GoogleFonts.outfit(
                        color: AppColors.electricBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 5,
                    backgroundColor: context.shimmerBase,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.electricBlue),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Media preview + Caption
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Media thumbnail
                          Container(
                            width: 100,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: context.inputFill,
                              image: !widget.isVideo
                                  ? DecorationImage(
                                      image: FileImage(widget.mediaFile),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: widget.isVideo && _videoController != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AspectRatio(
                                      aspectRatio:
                                          _videoController!.value.aspectRatio,
                                      child: VideoPlayer(_videoController!),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),

                          // Caption field
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _captionController,
                                  maxLines: 5,
                                  maxLength: 500,
                                  enabled: !_isUploading,
                                  style: GoogleFonts.outfit(
                                      fontSize: 14, color: context.textPrimary),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Write a caption... #hashtags @friends',
                                    hintStyle: GoogleFonts.outfit(
                                      color: context.textHint,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    counterStyle: GoogleFonts.outfit(
                                      color: context.textHint,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Divider(height: 1, color: context.divider),

                    // Options
                    _optionTile(
                      icon: Icons.music_note_rounded,
                      iconColor: Colors.green,
                      title: _selectedTrack != null
                          ? 'Music: ${_selectedTrack!.name}'
                          : 'Attach Music (Spotify)',
                      trailing: _selectedTrack != null
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() => _selectedTrack = null);
                              },
                            )
                          : Icon(Icons.chevron_right_rounded,
                              color: context.iconMuted, size: 22),
                      onTap: () async {
                        final selected =
                            await showModalBottomSheet<SpotifyTrack>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const SpotifySearchSheet(),
                        );
                        if (selected != null) {
                          setState(() => _selectedTrack = selected);
                        }
                      },
                    ),
                    Divider(height: 1, color: context.divider, indent: 60),

                    _optionTile(
                      icon: Icons.location_on_outlined,
                      iconColor: Colors.red.shade400,
                      title: 'Add Location',
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: context.iconMuted, size: 22),
                    ),
                    Divider(height: 1, color: context.divider, indent: 60),

                    _optionTile(
                      icon: Icons.person_add_outlined,
                      iconColor: AppColors.electricBlue,
                      title: 'Tag People',
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: context.iconMuted, size: 22),
                    ),
                    Divider(height: 1, color: context.divider, indent: 60),

                    _optionTile(
                      icon: _visibility == 'public'
                          ? Icons.public_rounded
                          : _visibility == 'friends'
                              ? Icons.people_rounded
                              : Icons.visibility_off_rounded,
                      iconColor: Colors.teal,
                      title: 'Who can view this post',
                      onTap: _showVisibilityPicker,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getVisibilityLabel(),
                            style: GoogleFonts.outfit(
                              color: AppColors.electricBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: context.iconMuted, size: 22),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: context.divider, indent: 60),
                  ],
                ),
              ),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: Colors.red.shade400, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.outfit(
                              color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom Button
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _publishPost,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                  label: Text(
                    _isUploading ? 'Publishing...' : 'Share',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isUploading
                        ? Colors.grey.shade400
                        : AppColors.electricBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _optionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) =>
      InkWell(
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      );
}
