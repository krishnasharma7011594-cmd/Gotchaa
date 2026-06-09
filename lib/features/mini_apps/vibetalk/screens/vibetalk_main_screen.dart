import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/vibetalk_providers.dart';
import 'vibetalk_chat_view.dart';
import 'vibetalk_cooldown_screen.dart';
import 'vibetalk_idle_view.dart';
import 'vibetalk_matching_view.dart';
import 'vibetalk_summary_screen.dart';

class VibeTalkMainScreen extends ConsumerStatefulWidget {
  const VibeTalkMainScreen({super.key});

  @override
  ConsumerState<VibeTalkMainScreen> createState() => _VibeTalkMainScreenState();
}

class _VibeTalkMainScreenState extends ConsumerState<VibeTalkMainScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for match — fire once when status becomes connected
    ref.listenManual(vibeTalkProvider.select((s) => s.status), (prev, next) {
      if (next == VibeTalkStatus.connected && prev != VibeTalkStatus.connected) {
        AnalyticsService.logMatchFound();
      }
    });
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Report User',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to end this chat and report this user? This session will be terminated immediately.',
              style: TextStyle(color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reason for report:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...[
              'Harassment / Bullying',
              'Inappropriate Content / Nudity',
              'Spam / Scam / Phishing',
              'Other Violation'
            ].map((reason) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  
                  final state = ref.read(vibeTalkProvider);
                  final reporterId = state.currentUserId ?? '';
                  final reportedUsername = state.anonymousUsername ?? 'anonymous';
                  final roomId = state.roomId ?? 'unknown';

                  // Terminate WebRTC session immediately
                  await ref.read(vibeTalkProvider.notifier).endChat();

                  try {
                    await FirebaseFirestore.instance.collection('reports').add({
                      'reporterId': reporterId,
                      'reportedUsername': reportedUsername,
                      'roomId': roomId,
                      'reason': reason,
                      'timestamp': FieldValue.serverTimestamp(),
                      'type': 'vibetalk',
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report submitted. Thank you for helping keep our community safe.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    // Silently handle
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(color: context.textPrimary),
                  ),
                ),
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vibeTalkProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(context.tr('mini_app_vibetalk_name'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: context.surface,
        elevation: 0,
        actions: [
          if (state.status == VibeTalkStatus.connected) ...[
            IconButton(
              icon: const Icon(Icons.flag_rounded, color: Colors.red),
              onPressed: () => _showReportDialog(context),
              tooltip: 'Report User',
            ),
            IconButton(
              icon: Icon(Icons.skip_next_rounded, color: Theme.of(context).colorScheme.primary),
              onPressed: () {
                ref.read(vibeTalkProvider.notifier).skipToNext();
              },
              tooltip: context.tr('vibetalk_skip'),
            ),
          ]
        ],
      ),
      body: Column(
        children: [
          // Limited Access Banner
          if (profileAsync.asData?.value?.isVerified == false)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.accent.withOpacity(0.9),
                    context.accent.withOpacity(0.7),
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('vibetalk_limited_access'),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to invite screen
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(context.tr('vibetalk_unlock'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildBody(state),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(VibeTalkState state) {
    if (state.isOnCooldown) {
      return const VibeTalkCooldownScreen();
    }

    return switch (state.status) {
      VibeTalkStatus.idle => const VibeTalkIdleView(),
      VibeTalkStatus.matching => const VibeTalkMatchingView(),
      VibeTalkStatus.connected => const VibeTalkChatView(),
      VibeTalkStatus.disconnected => const VibeTalkSummaryScreen(),
    };
  }
}
