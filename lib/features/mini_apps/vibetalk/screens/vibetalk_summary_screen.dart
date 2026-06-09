import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/permissions/permission_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/vibetalk_providers.dart';

class VibeTalkSummaryScreen extends ConsumerWidget {
  const VibeTalkSummaryScreen({super.key});

  void _showReportDialog(BuildContext context, WidgetRef ref) {
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
              'Are you sure you want to report this user? This will submit a permanent safety record.',
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

                  // Ensure chat session is ended on notifier
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
                    
                    // Reset to idle view
                    ref.read(vibeTalkProvider.notifier).resetToIdle();

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
  Widget build(BuildContext context, WidgetRef ref) {
    final vibeState = ref.watch(vibeTalkProvider);
    
    final duration = vibeState.lastSessionDuration;
    final durationStr = duration != null 
        ? '${duration.inMinutes}m ${duration.inSeconds % 60}s'
        : '0m 0s';
        
    final gamesPlayed = vibeState.lastSessionGamesPlayed;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.check_circle_outline, size: 100, color: Color(0xFF10B981))
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'Session Ended 🎙️',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Great vibes! You connected with someone new.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary),
            ),
            
            const SizedBox(height: 32),
            
            _StatRow(label: 'Duration', value: durationStr, delay: 200.ms),
            _StatRow(label: 'Games played', value: '$gamesPlayed', delay: 400.ms),
            _StatRow(label: 'Connection', value: 'Excellent', delay: 600.ms),

            const SizedBox(height: 24),
            
            // Premium post-session feedback card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.divider.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Was this match comfortable?',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref.read(vibeTalkProvider.notifier).resetToIdle();
                          },
                          icon: const Icon(Icons.sentiment_very_satisfied_rounded, color: Color(0xFF10B981)),
                          label: const Text('Yes'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showReportDialog(context, ref);
                          },
                          icon: const Icon(Icons.flag_rounded, color: Colors.white),
                          label: const Text('Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),
            
            ElevatedButton(
              onPressed: () async {
                final micGranted = await PermissionManager.requestMicrophonePermission(context);
                if (micGranted) {
                  await ref.read(vibeTalkProvider.notifier).startMatching();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Start New Session 💬', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                ref.read(vibeTalkProvider.notifier).resetToIdle();
                Navigator.pop(context);
              },
              child: Text('Back to Home', style: TextStyle(color: context.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, required this.delay});
  final String label;
  final String value;
  final Duration delay;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.textSecondary)),
          Text(value, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn(delay: delay).slideX();
}
