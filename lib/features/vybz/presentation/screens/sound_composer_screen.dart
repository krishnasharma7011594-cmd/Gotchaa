// lib/features/vybz/presentation/screens/sound_composer_screen.dart
//
// Reached from VybzUploadScreen. Lets the user either:
//  • Generate a new AI music clip (Lyria 3) from a text prompt, OR
//  • Browse and reuse any public sound from the shared library.
//
// On success it pops with the chosen [SoundModel] so the upload screen
// can display a preview and later call attachSoundToPost().

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/services/audio_focus_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/sound_model.dart';
import '../../data/repositories/music_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────

final _tabIndexProvider = StateProvider<int>((ref) => 0); // 0=Generate 1=Library
final _promptProvider = StateProvider<String>((ref) => '');
final _generatingProvider = StateProvider<bool>((ref) => false);
final _generatedSoundProvider = StateProvider<SoundModel?>((ref) => null);
final _generateErrorProvider = StateProvider<String?>((ref) => null);

final _librarySortProvider = StateProvider<String>((ref) => 'trending');
final _libraryProvider = FutureProvider.autoDispose
    .family<List<SoundModel>, String>((ref, sort) async {
  return ref.watch(musicRepositoryProvider).listLibrary(sort: sort);
});

// ── Screen ─────────────────────────────────────────────────────────────────

class SoundComposerScreen extends ConsumerStatefulWidget {
  const SoundComposerScreen({super.key, this.draftPostId});

  /// If a draft post already exists, we attach to it directly from the
  /// Library tab. Otherwise attachment is deferred to the upload screen.
  final String? draftPostId;

  @override
  ConsumerState<SoundComposerScreen> createState() =>
      _SoundComposerScreenState();
}

class _SoundComposerScreenState extends ConsumerState<SoundComposerScreen> {
  final TextEditingController _promptCtrl = TextEditingController();
  final AudioPlayer _player = AudioPlayer();
  String? _currentlyPlayingId;

  @override
  void dispose() {
    _promptCtrl.dispose();
    _player.dispose();
    ref.read(audioFocusManagerProvider).releaseAudioFocus('sound_composer');
    super.dispose();
  }

  // ── Playback ────────────────────────────────────────────────────────────

  Future<void> _togglePlay(SoundModel sound) async {
    final focusMgr = ref.read(audioFocusManagerProvider);

    if (_currentlyPlayingId == sound.soundId && _player.playing) {
      await _player.pause();
      await focusMgr.releaseAudioFocus('sound_composer');
      setState(() => _currentlyPlayingId = null);
      return;
    }

    final url = sound.playbackUrl;
    if (url == null || url.isEmpty) return;

    await focusMgr.requestAudioFocus('sound_composer', AudioRequester.vybz);

    // If BRO or another higher-priority source takes focus, stop automatically.
    focusMgr.focusOwnerStream.listen((owner) {
      if (owner != AudioRequester.vybz && _player.playing) {
        _player.pause();
        if (mounted) setState(() => _currentlyPlayingId = null);
      }
    });

    await _player.setUrl(url);
    await _player.play();
    if (mounted) setState(() => _currentlyPlayingId = sound.soundId);
  }

  // ── Generate ────────────────────────────────────────────────────────────

  Future<void> _generate() async {
    final prompt = ref.read(_promptProvider);
    if (prompt.trim().isEmpty) return;

    ref.read(_generateErrorProvider.notifier).state = null;
    ref.read(_generatingProvider.notifier).state = true;
    ref.read(_generatedSoundProvider.notifier).state = null;

    try {
      final sound =
          await ref.read(musicRepositoryProvider).generateSound(prompt.trim());
      if (mounted) {
        ref.read(_generatedSoundProvider.notifier).state = sound;
      }
    } on Exception catch (e) {
      final raw = e.toString();
      String message;
      if (raw.contains('resource-exhausted') || raw.contains('limit')) {
        message =
            '🎵 Daily limit reached (5/day). Browse the Library to reuse a sound!';
      } else if (raw.contains('permission-denied')) {
        message = 'Age verification required. Only 18+ users can generate AI music.';
      } else if (raw.contains('unauthenticated')) {
        message = 'Please sign in again to generate music.';
      } else if (raw.contains('internal') || raw.contains('unavailable')) {
        message = 'AI music service is temporarily unavailable. Try again in a moment.';
      } else {
        message = 'Generation failed: $raw';
      }
      if (mounted) ref.read(_generateErrorProvider.notifier).state = message;
    } finally {
      if (mounted) ref.read(_generatingProvider.notifier).state = false;
    }
  }

  // ── Attach & pop ────────────────────────────────────────────────────────

  Future<void> _useSound(SoundModel sound) async {
    if (widget.draftPostId != null) {
      try {
        await ref
            .read(musicRepositoryProvider)
            .attachSoundToPost(sound.soundId, widget.draftPostId!);
      } on Exception catch (_) {
        // Non-fatal; caller can retry attachment during final post.
      }
    }
    if (mounted) Navigator.pop(context, sound);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tabIdx = ref.watch(_tabIndexProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E16),
        elevation: 0,
        title: Text('Add Sound',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _SegmentedTabs(
            selectedIndex: tabIdx,
            onChanged: (i) => ref.read(_tabIndexProvider.notifier).state = i,
          ),
        ),
      ),
      body: tabIdx == 0 ? const _GenerateTab() : const _LibraryTab(),
    );
  }
}

// ── Segmented Control ─────────────────────────────────────────────────────

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs(
      {required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            _tab('Generate', 0),
            _tab('Library', 1),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, int idx) => Expanded(
        child: GestureDetector(
          onTap: () => onChanged(idx),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: selectedIndex == idx
                  ? AppColors.electricBlue
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color:
                    selectedIndex == idx ? Colors.white : Colors.white54,
                fontWeight: selectedIndex == idx
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
}

// ── Generate Tab ──────────────────────────────────────────────────────────

class _GenerateTab extends ConsumerStatefulWidget {
  const _GenerateTab();

  @override
  ConsumerState<_GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends ConsumerState<_GenerateTab> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGenerating = ref.watch(_generatingProvider);
    final generatedSound = ref.watch(_generatedSoundProvider);
    final error = ref.watch(_generateErrorProvider);
    final charCount = ref.watch(_promptProvider).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Describe your sound',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Describe a mood, genre, tempo, or instruments. Max 300 chars.',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Prompt field
          TextField(
            controller: _ctrl,
            maxLines: 5,
            maxLength: 300,
            style: GoogleFonts.outfit(color: Colors.white),
            onChanged: (v) =>
                ref.read(_promptProvider.notifier).state = v,
            decoration: InputDecoration(
              hintText:
                  'e.g. "Upbeat lo-fi hip hop with soft piano and rain sounds"',
              hintStyle: GoogleFonts.outfit(color: Colors.white30),
              fillColor: Colors.white10,
              filled: true,
              counterStyle:
                  GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isGenerating || charCount == 0 ? null : () {
                final state =
                    context.findAncestorStateOfType<_SoundComposerScreenState>();
                state?._generate();
              },
              icon: isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                isGenerating ? 'Generating…' : 'Generate',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          // Error message
          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade700),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(error,
                          style: GoogleFonts.outfit(
                              color: Colors.redAccent, fontSize: 13))),
                ],
              ),
            ),
          ],

          // Generated sound card
          if (generatedSound != null) ...[
            const SizedBox(height: 24),
            _SoundCard(
              sound: generatedSound,
              actionLabel: 'Attach to post',
              onAction: () {
                final state = context
                    .findAncestorStateOfType<_SoundComposerScreenState>();
                state?._useSound(generatedSound);
              },
              onTryAgain: () {
                ref.read(_generatedSoundProvider.notifier).state = null;
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ── Library Tab ───────────────────────────────────────────────────────────

class _LibraryTab extends ConsumerWidget {
  const _LibraryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(_librarySortProvider);
    final libraryAsync = ref.watch(_libraryProvider(sort));

    return Column(
      children: [
        // Trending / Recent toggle
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              _sortChip(ref, 'trending', 'Trending 🔥', sort),
              const SizedBox(width: 10),
              _sortChip(ref, 'recent', 'Recent', sort),
            ],
          ),
        ),

        // Sound list
        Expanded(
          child: libraryAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.electricBlue)),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load library.\nCheck your connection and try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.white54),
                ),
              ),
            ),
            data: (sounds) {
              if (sounds.isEmpty) {
                return Center(
                  child: Text('No sounds yet. Be the first to generate one!',
                      style: GoogleFonts.outfit(color: Colors.white54)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: sounds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _SoundCard(
                  sound: sounds[i],
                  actionLabel: 'Use this sound',
                  onAction: () {
                    final state = context
                        .findAncestorStateOfType<_SoundComposerScreenState>();
                    state?._useSound(sounds[i]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sortChip(
      WidgetRef ref, String value, String label, String current) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => ref.read(_librarySortProvider.notifier).state = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.electricBlue : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                color: selected ? Colors.white : Colors.white54,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }
}

// ── Shared Sound Card ─────────────────────────────────────────────────────

class _SoundCard extends ConsumerStatefulWidget {
  const _SoundCard({
    required this.sound,
    required this.actionLabel,
    required this.onAction,
    this.onTryAgain,
  });

  final SoundModel sound;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onTryAgain;

  @override
  ConsumerState<_SoundCard> createState() => _SoundCardState();
}

class _SoundCardState extends ConsumerState<_SoundCard> {
  bool _isPlaying = false;
  final AudioPlayer _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    ref.read(audioFocusManagerProvider).releaseAudioFocus('card_${widget.sound.soundId}');
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final focusMgr = ref.read(audioFocusManagerProvider);
    final url = widget.sound.playbackUrl;
    if (url == null) return;

    if (_isPlaying) {
      await _player.pause();
      await focusMgr.releaseAudioFocus('card_${widget.sound.soundId}');
      setState(() => _isPlaying = false);
    } else {
      await focusMgr.requestAudioFocus(
          'card_${widget.sound.soundId}', AudioRequester.vybz);

      // Pause if a higher-priority source (BRO) takes over
      focusMgr.focusOwnerStream.listen((owner) {
        if (owner != AudioRequester.vybz && _isPlaying) {
          _player.pause();
          if (mounted) setState(() => _isPlaying = false);
        }
      });

      await _player.setUrl(url);
      await _player.play();
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sound = widget.sound;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: sound.playbackUrl != null ? _togglePlay : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.electricBlue),
                  ),
                  child: Icon(
                    _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: AppColors.electricBlue,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sound.prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sound.durationSec}s • ${sound.usageCount} uses',
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Music note waveform icon
              const Icon(Icons.graphic_eq_rounded,
                  color: AppColors.electricBlue, size: 28),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(widget.actionLabel,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              if (widget.onTryAgain != null) ...[
                const SizedBox(width: 10),
                TextButton(
                  onPressed: widget.onTryAgain,
                  child: Text('Try again',
                      style: GoogleFonts.outfit(
                          color: Colors.white54, fontSize: 13)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
