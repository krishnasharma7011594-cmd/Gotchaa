import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/theme/app_colors.dart';
import 'user_profile_screen.dart';

class FollowListScreen extends ConsumerWidget {

  const FollowListScreen({
    required this.uid, required this.username, required this.showFollowers, super.key,
  });
  final String uid;
  final String username;
  final bool showFollowers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(
      showFollowers ? userFollowersProvider(uid) : userFollowingProvider(uid),
    );

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: Text(
          showFollowers ? context.tr('profile_followers') : context.tr('profile_following'),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: listAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    showFollowers ? Icons.person_add_rounded : Icons.people_outline_rounded,
                    size: 64,
                    color: AppColors.darkTextSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    showFollowers ? context.tr('follow_no_followers') : context.tr('follow_no_following'),
                    style: GoogleFonts.outfit(
                      color: AppColors.darkTextSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserTile(context, user);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(context.tr('error_prefix', args: [err.toString()]))),
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, UserProfile user) => ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(uid: user.uid),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CachedNetworkImage(
        imageUrl: user.photoUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.darkSurface,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => const CircleAvatar(
          radius: 26,
          child: BlurHash(hash: 'L5H2EC=pPdpWXVJs00QQV_9H00XY'),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.darkSurface,
          child: Text(
            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      title: Text(
        user.username.isNotEmpty ? user.username : user.displayName,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
      ),
      subtitle: Text(
        user.displayName,
        style: GoogleFonts.outfit(
          color: AppColors.darkTextSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkDivider),
        ),
        child: Text(
          context.tr('view'),
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextPrimary,
          ),
        ),
      ),
    );
}
