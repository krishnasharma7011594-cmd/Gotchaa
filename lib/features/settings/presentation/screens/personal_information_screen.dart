import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/security/secure_screen.dart';
import '../../../../core/theme/app_colors.dart';

class PersonalInformationScreen extends ConsumerWidget {
  const PersonalInformationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SecureScreen(
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkBg : Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            context.tr('personal_info_title'),
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
        body: profileAsync.when(
          data: (profile) {
            if (profile == null)
              return Center(child: Text(context.tr('no_profile_found')));

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  context.tr('personal_info_desc'),
                  style: GoogleFonts.outfit(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _buildInfoTile(
                  context,
                  context.tr('personal_info_email'),
                  profile.email.isEmpty
                      ? context.tr('personal_info_not_provided')
                      : profile.email,
                  Icons.email_outlined,
                  onTap: () =>
                      _showEmailEditDialog(context, ref, profile.email),
                ),
                _buildInfoTile(
                  context,
                  context.tr('personal_info_phone'),
                  profile.phoneNumber ??
                      context.tr('personal_info_not_provided'),
                  Icons.phone_android_outlined,
                  onTap: () => _showEditDialog(
                      context,
                      ref,
                      context.tr('personal_info_phone'),
                      profile.phoneNumber ?? '', (val) {
                    ref
                        .read(profileRepositoryProvider)
                        .updatePersonalInfo(uid: profile.uid, phoneNumber: val);
                  }),
                ),
                _buildInfoTile(
                  context,
                  context.tr('personal_info_gender'),
                  profile.gender ?? context.tr('personal_info_not_specified'),
                  Icons.person_outline_rounded,
                  onTap: () => _showGenderPicker(
                      context, ref, profile.uid, profile.gender),
                ),
                _buildInfoTile(
                  context,
                  context.tr('personal_info_birthday'),
                  profile.birthday != null
                      ? DateFormat('MMM dd, yyyy').format(profile.birthday!)
                      : context.tr('personal_info_not_provided'),
                  Icons.cake_outlined,
                  onTap: () => _showDatePicker(
                      context, ref, profile.uid, profile.birthday),
                ),
                const SizedBox(height: 32),
                Text(
                  context.tr('personal_info_ownership'),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('personal_info_ownership_desc'),
                  style: GoogleFonts.outfit(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Text(context.tr('error_prefix', args: [e.toString()]))),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, String label,
      String initialValue, Function(String) onSave) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('personal_info_edit_label', args: [label]),
            style: GoogleFonts.outfit()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
              hintText: context.tr('personal_info_enter_label', args: [label])),
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel'))),
          TextButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(context);
              },
              child: Text(context.tr('save'))),
        ],
      ),
    );
  }

  void _showEmailEditDialog(
      BuildContext context, WidgetRef ref, String currentEmail) {
    final controller = TextEditingController(text: currentEmail);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Email', style: GoogleFonts.outfit()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Updating your email will require you to verify the new email address.',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'New Email'),
              style: GoogleFonts.outfit(),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel'))),
          TextButton(
              onPressed: () async {
                final newEmail = controller.text.trim();
                if (newEmail == currentEmail) {
                  Navigator.pop(context);
                  return;
                }
                try {
                  await ref.read(authRepositoryProvider).updateEmail(newEmail);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Verification email sent to new address.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(context.tr('save'))),
        ],
      ),
    );
  }

  void _showGenderPicker(
      BuildContext context, WidgetRef ref, String uid, String? currentGender) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GenderOption(
              label: context.tr('gender_male'),
              value: 'Male',
              current: currentGender,
              uid: uid,
              ref: ref),
          _GenderOption(
              label: context.tr('gender_female'),
              value: 'Female',
              current: currentGender,
              uid: uid,
              ref: ref),
          _GenderOption(
              label: context.tr('gender_other'),
              value: 'Other',
              current: currentGender,
              uid: uid,
              ref: ref),
          _GenderOption(
              label: context.tr('gender_prefer_not_to_say'),
              value: 'Prefer not to say',
              current: currentGender,
              uid: uid,
              ref: ref),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context, WidgetRef ref, String uid,
      DateTime? currentBirthday) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentBirthday ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      ref
          .read(profileRepositoryProvider)
          .updatePersonalInfo(uid: uid, birthday: date);
    }
  }

  Widget _buildInfoTile(
      BuildContext context, String label, String value, IconData icon,
      {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.electricBlue, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.label,
    required this.value,
    required this.current,
    required this.uid,
    required this.ref,
  });
  final String label;
  final String value;
  final String? current;
  final String uid;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(label, style: GoogleFonts.outfit()),
        onTap: () {
          ref
              .read(profileRepositoryProvider)
              .updatePersonalInfo(uid: uid, gender: value);
          Navigator.pop(context);
        },
        trailing: current == value
            ? const Icon(Icons.check, color: AppColors.electricBlue)
            : null,
      );
}
