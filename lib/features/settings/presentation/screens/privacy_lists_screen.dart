import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/profile_providers.dart';
import '../../../../core/theme/app_colors.dart';
import 'edit_custom_list_screen.dart';
import 'friend_list_screen.dart';
import 'ghost_list_screen.dart';

class PrivacyListsScreen extends ConsumerWidget {
  const PrivacyListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider).asData?.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F9FB),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Privacy Lists',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('System Lists', isDark),
            const SizedBox(height: 12),
            _listTile(
              context,
              title: 'Friends List',
              subtitle: 'Share posts only with these people',
              icon: Icons.people_rounded,
              color: Colors.blue,
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FriendListScreen()),
              ),
            ),
            _listTile(
              context,
              title: 'Ghost List',
              subtitle: 'Hide posts from these people',
              icon: Icons.visibility_off_rounded,
              color: Colors.purple,
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const GhostListScreen()),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionHeader('Custom Lists', isDark),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EditCustomListScreen()),
                  ),
                  icon: const Icon(Icons.add_rounded,
                      size: 20, color: AppColors.electricBlue),
                  label: Text(
                    'Create',
                    style: GoogleFonts.outfit(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (userProfile?.customPrivacyLists.isEmpty ?? true)
              _emptyState(isDark)
            else
              ...userProfile!.customPrivacyLists.map((list) => _listTile(
                    context,
                    title: list.name,
                    subtitle: '${list.uids.length} members',
                    icon: Icons.list_alt_rounded,
                    color: AppColors.electricBlue,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              EditCustomListScreen(list: list)),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) => Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      );

  Widget _listTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade400, size: 24),
              ],
            ),
          ),
        ),
      );

  Widget _emptyState(bool isDark) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.list_rounded,
                  size: 48, color: Colors.grey.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                'No custom lists created',
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'Organize your friends into custom groups for selective sharing.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      );
}
