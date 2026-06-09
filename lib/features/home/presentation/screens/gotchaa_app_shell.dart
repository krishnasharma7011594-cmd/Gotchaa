import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/legal_provider.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/shell_navigation_provider.dart';
import '../../../../core/services/activity_service.dart';
import '../../../../core/services/consent_gate_service.dart';
import '../../../../core/services/offline_queue_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/offline_banner.dart';
import '../../../../core/widgets/glass_sidebar.dart';
import '../../../../core/widgets/restricted_feature.dart';
import '../../../camera/presentation/screens/camera_stream_screen.dart';
import '../../../chat/presentation/screens/chat_home_screen.dart';
import '../../../chat/services/chat_service.dart';
import '../../../compliance/widgets/gotchaa_consent_modal.dart';
import '../../../explore/presentation/screens/explore_screen.dart';
import '../../../mini_apps/presentation/screens/gotchaa_mini_apps_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../vybz/presentation/screens/vybz_feed_screen.dart';
import 'main_shell.dart';

class GotchaaAppShell extends ConsumerStatefulWidget {
  const GotchaaAppShell({super.key});

  @override
  ConsumerState<GotchaaAppShell> createState() => _GotchaaAppShellState();
}

class _GotchaaAppShellState extends ConsumerState<GotchaaAppShell> {
  static bool _consentModalShown = false;

  @override
  void initState() {
    super.initState();
    ref.read(activityServiceProvider).startSession();
    ref.read(offlineQueueProvider).registerHandler(
      OfflineActionType.message,
      (action) async {
        final p = action.payload;
        await ref.read(chatServiceProvider).sendMessage(
          chatId: p['chatId'] as String,
          receiverId: p['receiverId'] as String,
          text: p['text'] as String,
          type: p['type'] as String? ?? 'text',
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(shellPageIndexProvider) == 0 && ref.read(shellPageControllerProvider).hasClients) {
         ref.read(shellPageControllerProvider).jumpToPage(1);
         ref.read(shellPageIndexProvider.notifier).state = 1;
      }
      _maybeShowConsentModal();
    });
  }

  bool _hasLegalAcceptance() {
    if (ref.read(legalAcceptedProvider)) return true;
    final profile = ref.read(currentUserProfileProvider).asData?.value;
    return profile?.termsAcceptedVersion == LegalConfig.termsVersion &&
        profile?.privacyAcceptedVersion == LegalConfig.privacyVersion;
  }

  Future<void> _maybeShowConsentModal() async {
    if (_consentModalShown || !mounted) return;
    if (!_hasLegalAcceptance()) return;
    _consentModalShown = true; // Synchronously guard to prevent concurrent race-condition dialogs
    
    final prompted = await ConsentGateService.hasPromptedForConsent();
    if (prompted) return;
    
    if (mounted) {
      await GotchaaConsentModal.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(legalAcceptedProvider, (_, __) => _maybeShowConsentModal());
    ref.listen(currentUserProfileProvider, (_, __) => _maybeShowConsentModal());
    final horizontalController = ref.watch(shellPageControllerProvider);
    final currentPage = ref.watch(shellPageIndexProvider);
    final profile = ref.watch(currentUserProfileProvider).asData?.value;
    final isUnverified = profile?.isVerified == false;
    final isLimited = profile?.isLimitedUser == true;
    ref.watch(localeProvider);

    return OfflineBanner(
      child: Scaffold(
      key: mainShellScaffoldKey,
      backgroundColor: Colors.black,
      extendBody: true,
      drawer: const GlassSidebar(),
      body: Column(
        children: [
          if (isUnverified && !isLimited) _buildLimitedBanner(),
          if (isLimited) _buildLimitedAccessBanner(),
          Expanded(
            child: PageView(
              controller: horizontalController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                if (ref.read(shellPageIndexProvider) != index) {
                  HapticFeedback.mediumImpact();
                  ref.read(shellPageIndexProvider.notifier).state = index;
                }
              },
              children: const [
                CameraStreamScreen(),
                RestrictedFeature(
                  type: RestrictionType.social,
                  child: ChatHomeScreen(),
                ),
                ExploreScreen(),
                GotchaaMiniAppsScreen(),
                RestrictedFeature(
                  type: RestrictionType.social,
                  child: VybzFeedScreen(),
                ),
                ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(currentPage, isUnverified, isLimited),
    ),
    );
  }

  Widget _buildLimitedAccessBanner() => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.electricBlue, AppColors.electricBlue.withOpacity(0.7)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.explore_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Limited Access Mode: Unlock premium mini-apps with an invite!',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                 // Push to invite code screen if needed, or show dialog
                 _showLockedFeatureNotice(
                   title: 'Full Access',
                   message: 'Enter an invite code to unlock premium exclusive mini-apps and features.',
                 );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(
                'UPGRADE',
                style: TextStyle(color: AppColors.electricBlue, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildLimitedBanner() => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.purpleAccent.withOpacity(0.8)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Unlock full access (Karma, Post, Chat) with an invite code!',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () async {
                final uid = ref.read(authStateProvider).asData?.value?.uid;
                if (uid != null) {
                  await ref.read(firestoreRepositoryProvider).setLimitedAccess(
                        uid: uid,
                        isLimited: false,
                      );
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(
                'UNLOCK',
                style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildBottomNav(int currentPage, bool isUnverified, bool isLimited) {
    // Hide Bottom Nav entirely when on Camera
    if (currentPage == 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161921).withOpacity(0.9) : Colors.white.withOpacity(0.9);
    final borderColor =
        isDark ? const Color(0xFF2A2D3A) : Colors.grey.shade200;
    final activeColor =
        isDark ? const Color(0xFFE9ECF4) : Colors.black;
    final inactiveColor =
        isDark ? const Color(0xFF7A8099) : Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1: Home/Chat
              _buildNavItem(1, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded,
                  context.tr('nav_home'), activeColor, inactiveColor, currentPage),
              // 2: Explore
              _buildNavItem(2, Icons.explore_rounded, Icons.explore_outlined,
                  context.tr('nav_explore'), activeColor, inactiveColor, currentPage),
              
              // 3: Mini Apps
              _buildNavItem(3, Icons.rocket_launch_rounded, Icons.rocket_launch_outlined,
                  'Mini Apps', activeColor, inactiveColor, currentPage),

              // 4: Vybz
              _buildNavItem(4, Icons.play_circle_filled_rounded,
                  Icons.play_circle_outline_rounded, context.tr('vybz_title'),
                  activeColor, inactiveColor, currentPage),
              
              // 5: Profile
              _buildNavItem(5, Icons.person_rounded,
                  Icons.person_outline_rounded, context.tr('nav_profile'),
                  activeColor, inactiveColor, currentPage),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int targetIndex, IconData filledIcon, IconData outlinedIcon, String label,
      Color activeColor, Color inactiveColor, int currentPage) {
    final bool isSelected = currentPage == targetIndex;
    return GestureDetector(
      onTap: () {
        if (currentPage != targetIndex) {
          HapticFeedback.lightImpact();
          ref.read(shellPageControllerProvider).animateToPage(
            targetIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color: isSelected ? activeColor : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.electricBlue,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton(bool isDark, bool isUnverified, bool isLimited) => GestureDetector(
      onTap: () async {
        if (isUnverified && !isLimited) {
          _showLockedFeatureNotice(
            title: 'Start Creating',
            message: 'Unlock content creation by entering an invite code.',
          );
          return;
        }
        HapticFeedback.mediumImpact();
        ref.read(shellPageControllerProvider).animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3366FF), Color(0xFF00C6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3366FF).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );

  void _showLockedFeatureNotice({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.blueAccent, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.grey[400], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe later', style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final uid = ref.read(authStateProvider).asData?.value?.uid;
              if (uid != null) {
                // Setting limited access to false triggers the AuthGate to show InviteCodeScreen
                await ref.read(firestoreRepositoryProvider).setLimitedAccess(
                      uid: uid,
                      isLimited: false,
                    );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Enter Invite Code', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
