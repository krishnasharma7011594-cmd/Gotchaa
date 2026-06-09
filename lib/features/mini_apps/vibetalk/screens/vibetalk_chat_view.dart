import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shake_report_listener.dart';
import '../../../../features/reporting/report_dialog.dart';
import '../../../../features/safety/emergency_safety_service.dart';
import '../models/vibe_message.dart';
import '../providers/vibetalk_providers.dart';
import '../services/vibetalk_webrtc_service.dart';
import '../widgets/vibetalk_game_menu.dart';
import '../widgets/vibetalk_game_overlay.dart';

class VibeTalkChatView extends ConsumerStatefulWidget {
  const VibeTalkChatView({super.key});

  @override
  ConsumerState<VibeTalkChatView> createState() => _VibeTalkChatViewState();
}

class _VibeTalkChatViewState extends ConsumerState<VibeTalkChatView> {
  final TextEditingController _msgController = TextEditingController();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _renderersInitialized = false;

  // Translation State
  final Map<String, String> _translations = {};
  final Set<String> _translatingSet = {};

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    
    // Safety check: if mounted, set initialized flag first before attaching streams
    if (mounted) {
      setState(() {
        _renderersInitialized = true;
      });
    }

    // Now safely attach streams
    Future.microtask(() {
      final rtcService = ref.read(vibeWebRTCServiceProvider);
      if (rtcService.localStream != null) {
        _localRenderer.srcObject = rtcService.localStream;
      }
      if (rtcService.remoteStream != null) {
        _remoteRenderer.srcObject = rtcService.remoteStream;
      }
      rtcService.onRemoteStreamAdd = (stream) {
        if (mounted) {
          setState(() {
            _remoteRenderer.srcObject = stream;
          });
        }
      };
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _showReportDialog() {
    final state = ref.read(vibeTalkProvider);
    ref.read(vibeTalkProvider.notifier).endChat();
    showReportBottomSheet(
      context,
      reportedUserId: state.anonymousUsername ?? 'unknown',
      contentType: 'vibetalk',
      contentId: state.roomId ?? 'unknown',
    );
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    if (EmergencySafetyService.instance.checkSafeWord(text)) {
      ref.read(vibeTalkProvider.notifier).endChat();
      EmergencySafetyService.instance.sendSilentSos(
        context: 'vibetalk_safe_word',
        roomId: ref.read(vibeTalkProvider).roomId,
      );
      _msgController.clear();
      return;
    }
    ref.read(vibeTalkProvider.notifier).sendMessage(text);
    AnalyticsService.logMessageSent(type: 'vibetalk');
    _msgController.clear();
  }

  void _emergencyExit() {
    ref.read(vibeTalkProvider.notifier).endChat();
    EmergencySafetyService.instance.sendSilentSos(context: 'vibetalk_emergency_exit');
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _translateMessage(VibeMessage msg) async {
    if (msg.isSystemMessage) return;
    if (_translations.containsKey(msg.id) || _translatingSet.contains(msg.id)) return;

    final svc = ref.read(translationServiceProvider);
    
    _translatingSet.add(msg.id);
    if (mounted) setState(() {});

    try {
      final source = await svc.detectLanguage(msg.text);
      if (source == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not detect language')),
          );
        }
        return;
      }
      
      final target = svc.preferredLanguage;
      if (source == target) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Already in ${target.name}')),
          );
        }
        return;
      }

      if (!await svc.isModelDownloaded(source)) {
        await svc.downloadModel(source);
      }
      if (!await svc.isModelDownloaded(target)) {
        await svc.downloadModel(target);
      }

      final translated = await svc.translateText(msg.text, source, target);
      if (!mounted) return;
      setState(() {
        _translations[msg.id] = translated;
      });
    } finally {
      _translatingSet.remove(msg.id);
      if (mounted) setState(() {});
    }
  }

  void _showMessageOptions(VibeMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!msg.isSystemMessage && !_translations.containsKey(msg.id))
              ListTile(
                leading: Icon(Icons.translate, color: Theme.of(context).colorScheme.primary),
                title: const Text('Translate Message'),
                onTap: () {
                  Navigator.pop(context);
                  _translateMessage(msg);
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colors.blue),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: msg.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vibeTalkProvider);
    final messagesStream = ref.watch(vibeMessagesProvider);

    final connected = !state.partnerDisconnected && state.roomId != null;
    return ShakeReportListener(
      enabled: connected,
      onShake: () {
        EmergencySafetyService.instance.submitShakeReport(
          roomId: state.roomId ?? 'unknown',
          partnerId: state.anonymousUsername,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency report sent. Help is on the way.')),
        );
      },
      child: Column(
      children: [
        // Top Banner for Disconnect
        if (state.partnerDisconnected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
            child: Text(
              context.tr('vibetalk_stranger_disconnected'),
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          )
         else
          Container(
             width: double.infinity,
             padding: const EdgeInsets.symmetric(vertical: 8),
             color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
             child: Column(
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     // Removed lock icon
                     const SizedBox(width: 4),
                     Text(
                       '${context.tr('vibetalk_talking_anonymously')} @${state.anonymousUsername}',
                       style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold),
                     ),
                   ],
                 ),
                 StreamBuilder<VibeIceState>(
                   stream: ref.read(vibeWebRTCServiceProvider).iceStateStream,
                   builder: (context, snapshot) {
                     final iceState = snapshot.data;
                     if (iceState == null) return const SizedBox.shrink();
                     Color statusColor = Colors.grey;
                     String statusText = 'Connecting...';
                     
                     switch (iceState) {
                       case VibeIceState.checking:
                         statusColor = Colors.orange;
                         statusText = 'Checking Connection...';
                         break;
                       case VibeIceState.connected:
                         statusColor = Colors.green;
                         statusText = 'Connected';
                         break;
                       case VibeIceState.reconnecting:
                         statusColor = Colors.orange;
                         statusText = 'Reconnecting...';
                         break;
                       case VibeIceState.failed:
                         statusColor = Colors.red;
                         statusText = 'Connection Failed';
                         break;
                       case VibeIceState.disconnected:
                         statusColor = Colors.red;
                         statusText = 'Disconnected';
                         break;
                     }
                     
                     return Padding(
                       padding: const EdgeInsets.only(top: 4),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Container(
                             width: 8,
                             height: 8,
                             decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                           ),
                           const SizedBox(width: 6),
                           Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                         ],
                       ),
                     );
                   },
                 ),
               ],
             ),
          ),

        // Chat Space
        Expanded(
          child: messagesStream.when(
            data: (messages) {
              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.tr('vibetalk_say_hi'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => showVibeTalkGameMenu(context, ref),
                        icon: const Icon(Icons.sports_esports_rounded),
                        label: Text(context.tr('vibetalk_play_icebreaker')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Stack(
                children: [
                  if (state.isVideo && _renderersInitialized)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          color: Colors.black,
                          child: Stack(
                            children: [
                              RTCVideoView(
                                _remoteRenderer,
                                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                width: 100,
                                height: 140,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.black,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: RTCVideoView(
                                      _localRenderer,
                                      mirror: true,
                                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Wrap ListView in a container with semi-transparent background if video is active
                  Container(
                    color: state.isVideo ? Colors.black.withValues(alpha: 0.3) : Colors.transparent,
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == state.currentUserId;

                        if (msg.isSystemMessage) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: context.textPrimary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  msg.text,
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: GestureDetector(
                            onLongPress: () => _showMessageOptions(msg),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? Theme.of(context).colorScheme.primary : context.surface,
                                borderRadius: BorderRadius.circular(20).copyWith(
                                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                                  bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      color: isMe ? Theme.of(context).colorScheme.onPrimary : context.textPrimary,
                                    ),
                                  ),
                                  if (_translations.containsKey(msg.id)) ...[
                                    const SizedBox(height: 4),
                                    Divider(color: (isMe ? Colors.white : context.textPrimary).withValues(alpha: 0.2), height: 1),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.g_translate, size: 10, color: (isMe ? Colors.white70 : Theme.of(context).colorScheme.primary).withValues(alpha: 0.8)),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _translations[msg.id]!,
                                            style: TextStyle(
                                              color: (isMe ? Colors.white70 : context.textPrimary).withValues(alpha: 0.8),
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const VibeTalkGameOverlay(),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text(context.tr('error_prefix', args: [e.toString()]))),
          ),
        ),

        // Bottom Voice & Text Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: context.surface,
            border: Border(top: BorderSide(color: context.divider.withValues(alpha: 0.1))),
          ),
          child: SafeArea(
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Audio Visualizers
                if (!state.partnerDisconnected)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _AudioVisualizer(
                          label: 'You',
                          stream: ref.read(vibeWebRTCServiceProvider).localAudioLevelStream,
                          isMuted: state.isMuted,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        _AudioVisualizer(
                          label: 'Partner',
                          stream: ref.read(vibeWebRTCServiceProvider).remoteAudioLevelStream,
                          isMuted: false, // Partner's mute state is handled by their stream
                          color: context.accent,
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _emergencyExit,
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.red,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.15),
                        padding: const EdgeInsets.all(12),
                      ),
                      tooltip: 'Emergency exit',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        ref.read(vibeTalkProvider.notifier).endChat();
                      },
                      icon: const Icon(Icons.call_end),
                      color: Theme.of(context).colorScheme.error,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Permanent Red Flag Report Button
                    IconButton(
                      onPressed: _showReportDialog,
                      icon: const Icon(Icons.flag_rounded),
                      color: Colors.red,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(12),
                      ),
                      tooltip: 'Report session',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        ref.read(vibeTalkProvider.notifier).toggleMute();
                      },
                      icon: Icon(state.isMuted ? Icons.mic_off : Icons.mic),
                      color: state.isMuted ? context.textSecondary : Theme.of(context).colorScheme.primary,
                      style: IconButton.styleFrom(
                        backgroundColor: (state.isMuted ? context.textSecondary : Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Game Menu Button
                    IconButton(
                      onPressed: state.partnerDisconnected ? null : () {
                        showVibeTalkGameMenu(context, ref);
                      },
                      icon: const Icon(Icons.sports_esports_rounded),
                      color: context.accent,
                      style: IconButton.styleFrom(
                        backgroundColor: context.accent.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Text Field
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        enabled: !state.partnerDisconnected,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: context.tr('vibetalk_type_message'),
                          hintStyle: TextStyle(color: context.textHint),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: context.bg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Send Button
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: state.partnerDisconnected ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }
}

class _AudioVisualizer extends StatelessWidget {

  const _AudioVisualizer({
    required this.label,
    required this.stream,
    required this.isMuted,
    required this.color,
  });
  final String label;
  final Stream<double> stream;
  final bool isMuted;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
      children: [
        StreamBuilder<double>(
          stream: stream,
          builder: (context, snapshot) {
            final level = isMuted ? 0.0 : (snapshot.data ?? 0.0);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                final height = 4.0 + (level * 30.0 * (1.0 - (index - 2).abs() / 3.0));
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 3,
                  height: height.clamp(4.0, 30.0),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: index == 2 ? 1.0 : 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: context.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
}
