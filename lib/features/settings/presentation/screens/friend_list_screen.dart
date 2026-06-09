import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/user_profile.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';

class FriendListScreen extends ConsumerStatefulWidget {
  const FriendListScreen({super.key});

  @override
  ConsumerState<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends ConsumerState<FriendListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await ref.read(firestoreRepositoryProvider).searchUsers(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendUsersAsync = ref.watch(friendUsersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F9FB),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Friends List',
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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  const Icon(Icons.search_rounded, color: Colors.grey, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _performSearch,
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search friends to add...',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 15),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _searchController.text.isNotEmpty 
              ? _buildSearchResults(isDark, currentUser?.uid)
              : _buildFriendList(friendUsersAsync, isDark, currentUser?.uid),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDark, String? currentUid) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: GoogleFonts.outfit(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        if (user.uid == currentUid) return const SizedBox.shrink();
        
        return _UserTile(
          user: user,
          isDark: isDark,
          isFriend: ref.watch(currentUserProfileProvider).asData?.value?.friendUids.contains(user.uid) ?? false,
          onAction: () {
            if (currentUid != null) {
              ref.read(profileRepositoryProvider).addToFriendList(
                currentUid: currentUid,
                targetUid: user.uid,
              );
            }
          },
          actionLabel: 'Add',
        );
      },
    );
  }

  Widget _buildFriendList(AsyncValue<List<UserProfile>> friendUsersAsync, bool isDark, String? currentUid) => friendUsersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  'Your Friends List is empty',
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Posts shared with "Friend List" will only be visible to these people.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _UserTile(
              user: user,
              isDark: isDark,
              isFriend: true,
              onAction: () {
                if (currentUid != null) {
                  ref.read(profileRepositoryProvider).removeFromFriendList(
                    currentUid: currentUid,
                    targetUid: user.uid,
                  );
                }
              },
              actionLabel: 'Remove',
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
}

class _UserTile extends StatelessWidget {

  const _UserTile({
    required this.user,
    required this.isDark,
    required this.isFriend,
    required this.onAction,
    required this.actionLabel,
  });
  final UserProfile user;
  final bool isDark;
  final bool isFriend;
  final VoidCallback onAction;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(user.photoUrl),
          radius: 24,
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
        ),
        title: Text(
          user.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          '@${user.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
        ),
        trailing: (isFriend && actionLabel == 'Remove')
            ? TextButton(
                onPressed: onAction,
                child: Text(
                  'Remove',
                  style: GoogleFonts.outfit(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : (!isFriend)
                ? ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      'Add',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
      ),
    );
}
