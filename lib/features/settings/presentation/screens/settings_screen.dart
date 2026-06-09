import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/webview/in_app_webview_screen.dart';
import '../../../compliance/dpdpa/data_principal_rights_page.dart';
import '../../../compliance/india/grievance_officer_page.dart';
import 'appearance_screen.dart';
import 'blocked_accounts_screen.dart';
import 'delete_account_screen.dart';
import 'language_settings_screen.dart';
import 'legal_hub_screen.dart';
import 'personal_information_screen.dart';
import 'privacy_lists_screen.dart';
import 'privacy_policy_screen.dart';
import 'privacy_settings_screen.dart';
import 'saved_posts_screen.dart';
import 'security_settings_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _privateAccount = true;
  bool _activityStatus = false;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _initialized = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _syncWithProfile(UserProfile? profile) {
    if (profile != null && !_initialized) {
      _privateAccount = profile.isPrivate ?? false;
      _activityStatus = profile.showActivityStatus ?? true;
      _pushNotifications = profile.pushNotificationsEnabled ?? true;
      _emailNotifications = profile.emailNotificationsEnabled ?? true;
      _initialized = true;
    }
  }

  Future<void> _updatePrivacy(String key, bool value) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;

    try {
      await ref.read(profileRepositoryProvider).updatePrivacySettings(
        uid: uid,
        settings: {key: value},
      );
    } catch (e) {
      
    }
  }

  bool _matchesSearch(String text) {
    if (_searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    ref.watch(languageProvider);
    profileAsync.whenData(_syncWithProfile);

    final themeState = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Adaptive colours ────────────────────────────────────────────────
    final bgColor = isDark ? AppColors.darkBg : const Color(0xFFF8F9FB);
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? AppColors.darkTextSecondary : Colors.grey.shade500;
    final dividerColor = isDark ? AppColors.darkDivider : Colors.grey.shade200;
    final iconSecondary = isDark ? AppColors.darkTextSecondary : Colors.grey.shade700;
    final searchBorder = isDark ? AppColors.darkDivider : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
        ),
        title: Text(
          context.tr('settings'),
          style: GoogleFonts.outfit(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── User card ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: profileAsync.when(
              data: (profile) => _buildUserCard(profile, textPrimary, textSecondary),
              loading: () => _buildUserCardLoading(textSecondary),
              error: (_, __) => _buildUserCard(null, textPrimary, textSecondary),
            ),
          ),

          // ── Search bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: searchBorder, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: GoogleFonts.outfit(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: context.tr('settings_search'),
                        hintStyle: GoogleFonts.outfit(color: textSecondary, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textSecondary, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
              ),
            ),
          ),

          // ── ACCOUNT ───────────────────────────────────────────────────
          _sectionLabel(context.tr('settings_account'), textSecondary),
          _settingsCard(cardColor, [
            if (_matchesSearch(context.tr('settings_personal_info')))
            _settingsTile(
              icon: Icons.person_rounded,
              iconColor: AppColors.electricBlue,
              title: context.tr('settings_personal_info'),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PersonalInformationScreen())),
            ),
            if (_matchesSearch(context.tr('settings_personal_info')))
            _divider(dividerColor),
            if (_matchesSearch(context.tr('settings_security')))
            _settingsTile(
              icon: Icons.shield_rounded,
              iconColor: AppColors.electricBlue,
              title: context.tr('settings_security'),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SecuritySettingsScreen())),
            ),
            if (_matchesSearch(context.tr('settings_security')))
            _divider(dividerColor),
            if (_matchesSearch(context.tr('settings_saved_posts')))
            _settingsTile(
              icon: Icons.bookmark_rounded,
              iconColor: AppColors.electricBlue,
              title: context.tr('settings_saved_posts'),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SavedPostsScreen())),
            ),
            if (_matchesSearch(context.tr('settings_saved_posts')))
            _divider(dividerColor),
            if (_matchesSearch(context.tr('settings_delete_account')))
            _settingsTile(
              icon: Icons.delete_forever_rounded,
              iconColor: AppColors.error,
              title: context.tr('settings_delete_account'),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
            ),
          ]),

          const SizedBox(height: 8),

          // ── APP PREFERENCES ──────────────────────────────────────────
          _sectionLabel(context.tr('settings_app_preferences'), textSecondary),
          _settingsCard(cardColor, [
            // Chat Language
            if (_matchesSearch(context.tr('settings_chat_language')))
            InkWell(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()));
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded,
                        color: AppColors.electricBlue, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(context.tr('settings_chat_language'),
                          style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textPrimary)),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: textSecondary, size: 22),
                  ],
                ),
              ),
            ),

            if (_matchesSearch(context.tr('settings_chat_language')))
            _divider(dividerColor),

            // ── Appearance / Theme ─────────────────────────────────────
            if (_matchesSearch(context.tr('settings_appearance')))
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AppearanceScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.brightness_6_rounded,
                        color: AppColors.electricBlue, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('settings_appearance'),
                              style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary)),
                            Text(
                              _currentThemeLabel(context, themeState.themeMode),
                              style: GoogleFonts.outfit(
                                  fontSize: 12, color: textSecondary),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: textSecondary, size: 22),
                  ],
                ),
              ),
            ),
          ]),

          const SizedBox(height: 8),

          // ── PRIVACY ───────────────────────────────────────────────────
          _sectionLabel(context.tr('settings_privacy'), textSecondary),
          _settingsCard(cardColor, [
            if (_matchesSearch(context.tr('settings_private_account')))
            _settingsTileSwitch(
              icon: Icons.lock_rounded,
              iconColor: iconSecondary,
              title: context.tr('settings_private_account'),
              subtitle: context.tr('settings_private_account_sub'),
              value: _privateAccount,
              onChanged: (v) {
                setState(() => _privateAccount = v);
                _updatePrivacy('isPrivate', v);
              },
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            if (_matchesSearch(context.tr('settings_private_account')))
            _divider(dividerColor),
            if (_matchesSearch(context.tr('settings_activity_status')))
            _settingsTileSwitch(
              icon: Icons.visibility_rounded,
              iconColor: iconSecondary,
              title: context.tr('settings_activity_status'),
              value: _activityStatus,
              onChanged: (v) {
                setState(() => _activityStatus = v);
                _updatePrivacy('showActivityStatus', v);
              },
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _divider(dividerColor),
            if (_matchesSearch(context.tr('settings_blocked_accounts')))
            _settingsTile(
              icon: Icons.block_rounded,
              iconColor: iconSecondary,
              title: context.tr('settings_blocked_accounts'),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => Navigator.push(context, 
                MaterialPageRoute(builder: (_) => const BlockedAccountsScreen())),
            ),
            if (_matchesSearch(context.tr('settings_blocked_accounts')))
            _divider(dividerColor),
            if (_matchesSearch(context.tr('settings_privacy_lists')))
            _settingsTile(
              icon: Icons.list_alt_rounded,
              iconColor: iconSecondary,
              title: context.tr('settings_privacy_lists'),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => Navigator.push(context, 
                MaterialPageRoute(builder: (_) => const PrivacyListsScreen())),
            ),
            if (_matchesSearch('Privacy & Data'))
            _divider(dividerColor),
            if (_matchesSearch('Privacy & Data'))
            _settingsTile(
              icon: Icons.tune_rounded,
              iconColor: AppColors.electricBlue,
              title: 'Privacy & Data',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PrivacySettingsScreen())),
            ),
          ]),

          const SizedBox(height: 8),

          // ── NOTIFICATIONS ─────────────────────────────────────────────
          _sectionLabel(context.tr('settings_notifications'), textSecondary),
          _settingsCard(cardColor, [
            if (_matchesSearch(context.tr('settings_push_notifications')))
            _settingsTileSwitch(
              icon: Icons.notifications_rounded,
              iconColor: AppColors.electricBlue,
              title: context.tr('settings_push_notifications'),
              value: _pushNotifications,
              onChanged: (v) {
                setState(() => _pushNotifications = v);
                _updatePrivacy('pushNotificationsEnabled', v);
              },
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            if (_matchesSearch(context.tr('settings_push_notifications')))
            _divider(dividerColor),
            if (_matchesSearch(context.tr('settings_email_notifications')))
            _settingsTileSwitch(
              icon: Icons.email_rounded,
              iconColor: AppColors.electricBlue,
              title: context.tr('settings_email_notifications'),
              value: _emailNotifications,
              onChanged: (v) {
                setState(() => _emailNotifications = v);
                _updatePrivacy('emailNotificationsEnabled', v);
              },
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ]),

          const SizedBox(height: 8),

          // ── LEGAL ─────────────────────────────────────────────────────
          _sectionLabel('Legal', textSecondary),
          _settingsCard(cardColor, [
            if (_matchesSearch('Legal'))
            _settingsTile(
              icon: Icons.menu_book_rounded,
              iconColor: AppColors.electricBlue,
              title: 'Legal',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LegalHubScreen())),
            ),
          ]),

          const SizedBox(height: 8),

          // ── ABOUT ─────────────────────────────────────────────────────
          _sectionLabel(context.tr('settings_about'), textSecondary),
          _settingsCard(cardColor, [
            if (_matchesSearch(context.tr('settings_privacy_policy')))
            InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.privacy_tip_rounded,
                        color: AppColors.electricBlue, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(context.tr('settings_privacy_policy'),
                          style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textPrimary)),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: textSecondary, size: 22),
                  ],
                ),
              ),
            ),
            if (_matchesSearch(context.tr('settings_privacy_policy')))
            _divider(dividerColor),
            if (_matchesSearch(context.tr('settings_terms')))
            InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.gavel_rounded,
                        color: AppColors.electricBlue, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(context.tr('settings_terms'),
                          style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textPrimary)),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: textSecondary, size: 22),
                  ],
                ),
              ),
            ),
            if (profileAsync.asData?.value != null) ...[
              if ((profileAsync.asData!.value?.nation?['currentCountry'] as String? ?? '').toUpperCase() == 'IN' && _matchesSearch('Grievance Officer')) ...[
                _divider(dividerColor),
                _settingsTile(
                  icon: Icons.gavel_rounded,
                  iconColor: AppColors.electricBlue,
                  title: 'Grievance Officer',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GrievanceOfficerPage())),
                ),
              ],
              if (_matchesSearch('Your Data Rights')) ...[
                _divider(dividerColor),
                _settingsTile(
                  icon: Icons.privacy_tip_rounded,
                  iconColor: AppColors.electricBlue,
                  title: 'Your Data Rights',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DataPrincipalRightsPage())),
                ),
              ],
            ],
          ]),

          const SizedBox(height: 16),

          // ── Help Center ──────────────────────────────────────────────
          if (_matchesSearch(context.tr('settings_help')))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InAppWebViewScreen(
                    url: 'https://gotchaa.app/support',
                    title: 'Help Center',
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline_rounded,
                        color: AppColors.electricBlue, size: 22),
                    const SizedBox(width: 14),
                    Text(
                      context.tr('settings_help'),
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.open_in_new_rounded,
                      color: textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Log Out ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.error.withValues(alpha: 0.15)
                      : const Color(0xFFFDE8E8),
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  context.tr('logout'),
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.error),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Version ──────────────────────────────────────────────────
          Center(
            child: Text(
              'GOTCHAA v1.0.4+10',
              style: GoogleFonts.outfit(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String _currentThemeLabel(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return context.tr('settings_theme_dark');
      case ThemeMode.light:
        return context.tr('settings_theme_light');
      case ThemeMode.system:
        return context.tr('settings_theme_system');
    }
  }

  // ── Dynamic user card ─────────────────────────────────────────────────────
  Widget _buildUserCard(
      UserProfile? profile, Color textPrimary, Color textSecondary) {
    final name = profile?.displayName ?? 'User';
    final handle = profile?.username.isNotEmpty == true
        ? '@${profile?.username}'
        : profile?.email ?? '';
    final photoUrl = profile?.photoUrl ?? '';

    return Row(
      children: [
        CachedNetworkImage(
          imageUrl: photoUrl,
          imageBuilder: (context, imageProvider) => CircleAvatar(
            radius: 32,
            backgroundImage: imageProvider,
          ),
          placeholder: (context, url) => const CircleAvatar(
            radius: 32,
            child: BlurHash(hash: 'L5H2EC=pPdpWXVJs00QQV_9H00XY'),
          ),
          errorWidget: (context, url, error) => CircleAvatar(
            radius: 32,
            backgroundColor: textSecondary.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textSecondary),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
              if (handle.isNotEmpty)
                Text(handle,
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: textSecondary)),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      color: AppColors.electricBlue, size: 16),
                  const SizedBox(width: 4),
                  Text(context.tr('settings_manage_account'),
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.electricBlue)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserCardLoading(Color textSecondary) => Row(
      children: [
        CircleAvatar(
            radius: 32,
            backgroundColor: textSecondary.withValues(alpha: 0.1)),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label, Color textSecondary) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
        child: Text(
          label,
          style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textSecondary,
              letterSpacing: 0.8),
        ),
      );

  Widget _settingsCard(Color cardColor, List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16)),
          child: Column(children: children),
        ),
      );

  Widget _divider(Color color) =>
      Divider(height: 1, thickness: 0.5, indent: 54, color: color);

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color textPrimary,
    required Color textSecondary,
    VoidCallback? onTap,
  }) => InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary)),
            ),
            Icon(Icons.chevron_right_rounded, color: textSecondary, size: 22),
          ],
        ),
      ),
    );

  Widget _settingsTileSwitch({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value, required ValueChanged<bool> onChanged, required Color textPrimary, required Color textSecondary, String? subtitle,
  }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textPrimary)),
                if (subtitle != null)
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: textSecondary)),
              ],
            ),
          ),
          Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.electricBlue),
        ],
      ),
    );
}
