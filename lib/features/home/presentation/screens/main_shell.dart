import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/shell_navigation_provider.dart';
import '../../../../core/services/call_manager.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/widgets/glass_sidebar.dart';
import '../../../explore/presentation/screens/explore_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../vybz/presentation/screens/vybz_feed_screen.dart';
import 'home_feed_screen.dart';

final GlobalKey<ScaffoldState> mainShellScaffoldKey = GlobalKey<ScaffoldState>();

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    // Start listening for calls globally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSecurityAndCalling();
    });
  }

  Future<void> _initSecurityAndCalling() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      // E2EE keys are created lazily per-chat — no global initialization needed.
      // Start checking for incoming calls.
      if (mounted) {
        ref.read(callManagerProvider).startListening(context);
      }
    }
  }

  final List<Widget> _screens = [
    const HomeFeedScreen(),    // 0 – Feed
    const ExploreScreen(),     // 1 – Search / Explore
    const SizedBox.shrink(),   // 2 – Create Placeholder
    const VybzFeedScreen(),    // 3 – Vybz (Video Feed)
    const ProfileScreen(),     // 4 – Profile
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(mainShellTabIndexProvider);
    ref.watch(localeProvider); // Force rebuild when language changes

    return Scaffold(
      key: mainShellScaffoldKey,
      extendBody: true,
      drawer: const GlassSidebar(),
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(selectedIndex),
    );
  }

  Widget _buildBottomNav(int selectedIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161921) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2D3A) : Colors.grey.shade200;
    final activeColor =
        isDark ? const Color(0xFFE9ECF4) : Colors.black;
    final inactiveColor =
        isDark ? const Color(0xFF7A8099) : Colors.grey.shade400;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          if (index == 2) {
            // Open camera/create flow
            return;
          }
          ref.read(mainShellTabIndexProvider.notifier).state = index;
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: activeColor,
        unselectedItemColor: inactiveColor,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: Icon(selectedIndex == 0 ? Icons.home_rounded : Icons.home_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(selectedIndex == 1 ? Icons.explore_rounded : Icons.explore_outlined),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: SizedBox(width: 46),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(selectedIndex == 3 ? Icons.play_circle_filled_rounded : Icons.play_circle_outline_rounded),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(selectedIndex == 4 ? Icons.person_rounded : Icons.person_outline_rounded),
            label: '',
          ),
        ],
      ),
    );
  }
}
