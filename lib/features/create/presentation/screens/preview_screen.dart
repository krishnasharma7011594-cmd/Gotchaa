import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/models/spotify_track.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../camera/filters/filter_manager.dart';
import '../models/editable_item.dart';
import '../widgets/ar_overlays_widget.dart';
import '../widgets/editable_item_widget.dart';
import '../widgets/spotify_search_sheet.dart';
import '../widgets/sticker_picker_sheet.dart';
import '../widgets/text_editor_modal.dart';
import '../widgets/user_search_sheet.dart';
import 'post_details_screen.dart';

class PreviewScreen extends StatefulWidget {

  const PreviewScreen({
    required this.file, required this.isVideo, required this.appliedFilter, super.key,
    this.colorMatrix,
    this.isFrontCamera = false,
  });
  final File file;
  final bool isVideo;
  final FilterDefinition? appliedFilter;
  final List<double>? colorMatrix;
  final bool isFrontCamera;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  VideoPlayerController? _videoController;
  final List<EditableItem> _items = [];
  String? _selectedItemId;
  SpotifyTrack? _selectedTrack;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _uuid = const Uuid();
  bool _isDragging = false;
  bool _isOverTrash = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _videoController = VideoPlayerController.file(widget.file)
        ..initialize().then((_) {
          _videoController!.setLooping(true);
          _videoController!.play();
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _addItem(EditableItemType type, dynamic value) {
    setState(() {
      final id = _uuid.v4();
      final size = MediaQuery.of(context).size;
      final newItem = EditableItem(
        id: id,
        type: type,
        value: value,
        position: Offset(size.width / 2, size.height / 2),
      );
      _items.add(newItem);
      _selectedItemId = id;
    });
  }

  void _onUpdateItem(EditableItem updatedItem) {
    setState(() {
      final index = _items.indexWhere((i) => i.id == updatedItem.id);
      if (index != -1) {
        _items[index] = updatedItem;

        if (_isDragging) {
          final size = MediaQuery.of(context).size;
          // Trash position: Bottom Center
          final trashPos = Offset(size.width / 2, size.height - 100);
          final dist = (updatedItem.position - trashPos).distance;
          
          if (dist < 80 && !_isOverTrash) {
            _isOverTrash = true;
            HapticFeedback.mediumImpact();
          } else if (dist >= 80 && _isOverTrash) {
            _isOverTrash = false;
          }
        }
      }
    });
  }

  void _onAddText({EditableItem? existingItem}) async {
    final result = await showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'TextEditor',
      pageBuilder: (context, _, __) => TextEditorModal(
        initialText: existingItem?.value,
        initialColor: existingItem?.color,
      ),
    );

    if (result != null && result['text'].toString().isNotEmpty) {
      if (existingItem != null) {
        _onUpdateItem(existingItem.copyWith(
          value: result['text'],
          color: result['color'],
        ));
      } else {
        _addItem(EditableItemType.text, result['text']);
        setState(() {
          _items.last.color = result['color'] as Color;
        });
      }
    }
  }

  void _onAddSticker() async {
    final sticker = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const StickerPickerSheet(),
    );

    if (sticker != null) {
      _addItem(EditableItemType.sticker, sticker);
    }
  }

  void _onAddTag() async {
    final user = await showModalBottomSheet<UserProfile>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const UserSearchSheet(),
    );

    if (user != null) {
      _addItem(EditableItemType.tag, user.username);
    }
  }

  void _onAddMusic() async {
    final track = await showModalBottomSheet<SpotifyTrack>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SpotifySearchSheet(),
    );

    if (track != null) {
      setState(() => _selectedTrack = track);
      if (track.previewUrl != null) {
        await _audioPlayer.stop();
        await _audioPlayer.setLoopMode(LoopMode.one);
        await _audioPlayer.setUrl(track.previewUrl!);
        await _audioPlayer.play();
      }
    }
  }

  void _onNext() {
    _audioPlayer.stop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailsScreen(
          mediaFile: widget.file,
          isVideo: widget.isVideo,
          initialTrack: _selectedTrack,
          overlays: _items,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _selectedItemId = null),
        child: Stack(
          fit: StackFit.expand,
        children: [
          // 1. Media Preview with Matrix Overlay
          Center(
            child: Transform.scale(
              scaleX: widget.isFrontCamera ? -1.0 : 1.0,
              alignment: Alignment.center,
              child: ColorFiltered(
                colorFilter: widget.colorMatrix != null 
                    ? ColorFilter.matrix(widget.colorMatrix!)
                    : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                child: widget.isVideo
                    ? (_videoController != null && _videoController!.value.isInitialized)
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : const CircularProgressIndicator(color: AppColors.electricBlue)
                    : Image.file(widget.file, fit: BoxFit.cover),
              ),
            ),
          ),
          
          if (widget.appliedFilter != null)
             SizedBox.expand(child: AROverlaysWidget(filter: widget.appliedFilter!, intensity: 1)),

          // 2. Editable Items Overlays
          ..._items.map((item) => EditableItemWidget(
                item: item,
                isSelected: _selectedItemId == item.id,
                onTap: () {
                  setState(() {
                    _selectedItemId = item.id;
                    final idx = _items.indexOf(item);
                    if (idx != -1) {
                      _items.add(_items.removeAt(idx));
                    }
                  });
                },
                onDoubleTap: () {
                  if (item.type == EditableItemType.text) {
                    _onAddText(existingItem: item);
                  }
                },
                onDelete: () => setState(() => _items.removeWhere((i) => i.id == item.id)),
                onUpdate: _onUpdateItem,
                onDragStart: () => setState(() => _isDragging = true),
                onDragEnd: () {
                  if (_isOverTrash) {
                    setState(() {
                      _items.removeWhere((i) => i.id == _selectedItemId);
                      _selectedItemId = null;
                    });
                    HapticFeedback.heavyImpact();
                  }
                  setState(() {
                    _isDragging = false;
                    _isOverTrash = false;
                  });
                },
              )),

          // 2.1 Alignment Guides
          if (_isDragging && _selectedItemId != null) ...[
            _buildAlignmentGuides(),
          ],

          // 3. Instagram-like Trash Zone
          if (_isDragging)
            _buildTrashZone(),

          // 3. Instagram-like Text Toolbar (only if text item selected)
          if (_selectedItemId != null)
             _buildTextEditingToolbar(),

          // 4. Selected Music Indicator (Top)
          if (_selectedTrack != null)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.music_note_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedTrack!.name} • ${_selectedTrack!.artist}',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _audioPlayer.stop();
                          setState(() => _selectedTrack = null);
                        },
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top Back Button
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),

          Positioned(
            top: 100,
            right: 20,
            child: Column(
              children: [
                _buildSidebarItem(Icons.music_note_rounded, 'Music', onTap: () {
                  HapticFeedback.selectionClick();
                  _onAddMusic();
                }),
                const SizedBox(height: 24),
                _buildSidebarItem(Icons.text_fields_rounded, 'Text', onTap: () {
                  HapticFeedback.selectionClick();
                  _onAddText();
                }),
                const SizedBox(height: 24),
                _buildSidebarItem(Icons.emoji_emotions_rounded, 'Stickers', onTap: () {
                  HapticFeedback.selectionClick();
                  _onAddSticker();
                }),
                const SizedBox(height: 24),
                _buildSidebarItem(Icons.person_add_rounded, 'Tag', onTap: () {
                  HapticFeedback.selectionClick();
                  _onAddTag();
                }),
                const SizedBox(height: 24),
                if (widget.isVideo)
                  _buildSidebarItem(Icons.cut_rounded, 'Trim'),
              ],
            ),
          ),

          // Bottom Bar (Next)
          Positioned(
            bottom: 40,
            right: 20,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _onNext();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricBlue.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Next',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildTrashZone() => Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isOverTrash ? 80 : 60,
              height: _isOverTrash ? 80 : 60,
              decoration: BoxDecoration(
                color: _isOverTrash ? Colors.red.withOpacity(0.8) : Colors.black38,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isOverTrash ? Colors.white : Colors.white24,
                  width: 2,
                ),
              ),
              child: Icon(
                _isOverTrash ? Icons.delete_forever_rounded : Icons.delete_outline_rounded,
                color: Colors.white,
                size: _isOverTrash ? 32 : 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drag here to remove',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ).animate().fadeIn(),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutBack);

  Widget _buildAlignmentGuides() {
    final item = _items.firstWhere((i) => i.id == _selectedItemId);
    final size = MediaQuery.of(context).size;
    final isVerticalCentered = (item.position.dx - size.width / 2).abs() < 2;
    final isHorizontalCentered = (item.position.dy - size.height / 2).abs() < 2;

    return Stack(
      children: [
        if (isVerticalCentered)
          Center(
            child: Container(
              width: 1.5,
              height: size.height,
              color: AppColors.electricBlue.withOpacity(0.5),
            ),
          ),
        if (isHorizontalCentered)
          Center(
            child: Container(
              height: 1.5,
              width: size.width,
              color: AppColors.electricBlue.withOpacity(0.5),
            ),
          ),
      ],
    );
  }

  Widget _buildTextEditingToolbar() {
    final item = _items.firstWhere((i) => i.id == _selectedItemId, orElse: () => _items.first);
    if (item.type != EditableItemType.text) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      left: 20,
      right: 70, // Leave room for sidebar
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildToolbarBtn(
              item.hasBackground ? Icons.font_download_rounded : Icons.font_download_outlined,
              () => _onUpdateItem(item.copyWith(hasBackground: !item.hasBackground)),
            ),
            _buildToolbarBtn(
              item.textAlign == TextAlign.left ? Icons.format_align_left :
              item.textAlign == TextAlign.center ? Icons.format_align_center : Icons.format_align_right,
              () {
                final next = item.textAlign == TextAlign.left 
                    ? TextAlign.center 
                    : item.textAlign == TextAlign.center ? TextAlign.right : TextAlign.left;
                _onUpdateItem(item.copyWith(textAlign: next));
              },
            ),
            // Color Cycle Button
            GestureDetector(
              onTap: () {
                final colors = [Colors.white, Colors.black, Colors.red, Colors.yellow, Colors.blue, Colors.green];
                final currentIdx = colors.indexOf(item.color ?? Colors.white);
                final next = colors[(currentIdx + 1) % colors.length];
                _onUpdateItem(item.copyWith(color: next));
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: item.color ?? Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
            // Font Size Slider
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: item.fontSize,
                  min: 12,
                  max: 72,
                  activeColor: AppColors.electricBlue,
                  onChanged: (val) => _onUpdateItem(item.copyWith(fontSize: val)),
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: -0.2),
    );
  }

  Widget _buildToolbarBtn(IconData icon, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: 22),
    );

  Widget _buildSidebarItem(IconData icon, String label, {VoidCallback? onTap}) => GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
}
