import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';

class GotchaaLikesScreen extends ConsumerStatefulWidget {
  const GotchaaLikesScreen({
    required this.contentId,
    required this.contentType,
    this.parentId,
    super.key,
  });

  final String contentId;
  final String contentType;
  final String? parentId;

  @override
  ConsumerState<GotchaaLikesScreen> createState() => _GotchaaLikesScreenState();
}

class _GotchaaLikesScreenState extends ConsumerState<GotchaaLikesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _likers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLikers();
  }

  Future<void> _fetchLikers() async {
    try {
      final socialRepo = ref.read(socialRepositoryProvider);
      final results = await socialRepo.getLikers(
        widget.contentId,
        widget.contentType,
        parentId: widget.parentId,
      );
      if (mounted) {
        setState(() {
          _likers = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        title: Text(
          'Likes',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.iconPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _likers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border_rounded, size: 64, color: context.iconSecondary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No likes yet',
                            style: GoogleFonts.outfit(color: context.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _likers.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (context, index) {
                        final liker = _likers[index];
                        return _LikerTile(liker: liker);
                      },
                    ),
    );
  }
}

class _LikerTile extends StatelessWidget {
  const _LikerTile({required this.liker});
  final Map<String, dynamic> liker;

  @override
  Widget build(BuildContext context) {
    final uid = liker['uid'] as String;
    final photoUrl = liker['photoUrl'] as String? ?? '';
    final displayName = liker['displayName'] as String? ?? 'User';

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(uid: uid),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: context.shimmerBase,
        backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
        child: photoUrl.isEmpty
            ? Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        displayName,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: context.textPrimary,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.electricBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'View',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
