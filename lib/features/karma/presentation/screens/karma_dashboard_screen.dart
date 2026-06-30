import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/security/secure_screen.dart';
import '../../../../core/theme/app_colors.dart';

class KarmaDashboardScreen extends ConsumerWidget {
  const KarmaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return SecureScreen(
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          title: Text(context.tr('karma_aura_name'),
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return Center(
                  child: Text(context.tr('error_something_wrong'),
                      style: const TextStyle(color: Colors.white)));
            }
            final isUnverified = profile.isVerified == false;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildAuraCircle(180,
                            AppColors.electricBlue.withOpacity(0.3), 5.seconds),
                        _buildAuraCircle(
                            140,
                            AppColors.auraGradient.colors[0].withOpacity(0.4),
                            3.seconds),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.auraGradient,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isUnverified)
                                  ImageFiltered(
                                    imageFilter:
                                        ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Text('${profile.karma}',
                                        style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold)),
                                  )
                                else
                                  Text('${profile.karma}',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold)),
                                Text(context.tr('karma_label'),
                                    style: GoogleFonts.outfit(
                                        color: Colors.white70, fontSize: 14)),
                                if (isUnverified)
                                  const Icon(Icons.lock_rounded,
                                      color: Colors.white60, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  _buildInfoCard(context.tr('karma_aura_title'),
                      context.tr('karma_aura_desc')),
                  const SizedBox(height: 30),
                  _buildTaskList(context),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isUnverified) {
                          _showLockedFeatureNotice(context, ref);
                          return;
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUnverified
                            ? AppColors.electricBlue.withOpacity(0.3)
                            : AppColors.electricBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isUnverified) ...[
                            const Icon(Icons.lock_rounded,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            context.tr('karma_redeem_btn'),
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white)),
          error: (e, st) => Center(
              child: Text('Error: $e',
                  style: const TextStyle(color: Colors.white))),
        ),
      ),
    );
  }

  Widget _buildAuraCircle(double size, Color color, Duration duration) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ).animate(onPlay: (c) => c.repeat()).rotate(duration: duration).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: Duration(milliseconds: duration.inMilliseconds ~/ 2),
          curve: Curves.easeInOut);

  Widget _buildInfoCard(String title, String desc) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 8),
            Text(desc,
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14)),
          ],
        ),
      );

  Widget _buildTaskList(BuildContext context) => Column(
        children: [
          _buildTaskItem(context.tr('karma_task_daily_post'), '+50 K', true),
          _buildTaskItem(context.tr('karma_task_verify'), '+100 K', false),
          _buildTaskItem(context.tr('karma_task_give_tips'), '+25 K', true),
          _buildTaskItem(context.tr('karma_task_share'), '+30 K', false),
        ],
      );

  Widget _buildTaskItem(String title, String points, bool isDone) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isDone ? 0.02 : 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: isDone ? Colors.green : Colors.white38,
                  size: 20,
                ),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: isDone ? Colors.white38 : Colors.white,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
            Text(points,
                style: GoogleFonts.outfit(
                    color: AppColors.auraGradient.colors[1],
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  void _showLockedFeatureNotice(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded,
                color: AppColors.electricBlue, size: 24),
            const SizedBox(width: 12),
            Text(
              'Unlock Karma Rewards',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Redeeming Karma scores for exclusive rewards requires account verification. Enter an invite code to proceed!',
          style: GoogleFonts.inter(color: Colors.grey[400], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Maybe later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final profile =
                  ref.read(currentUserProfileProvider).asData?.value;
              final uid = profile?.uid;
              if (uid != null) {
                await ref.read(firestoreRepositoryProvider).setLimitedAccess(
                      uid: uid,
                      isLimited: false,
                    );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Enter Invite Code',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
