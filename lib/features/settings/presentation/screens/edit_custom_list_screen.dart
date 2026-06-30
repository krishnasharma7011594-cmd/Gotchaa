import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/user_profile.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';

class EditCustomListScreen extends ConsumerStatefulWidget {
  const EditCustomListScreen({super.key, this.list});
  final CustomPrivacyList? list;

  @override
  ConsumerState<EditCustomListScreen> createState() =>
      _EditCustomListScreenState();
}

class _EditCustomListScreenState extends ConsumerState<EditCustomListScreen> {
  late TextEditingController _nameController;
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  List<String> _selectedUids = [];
  List<UserProfile> _selectedUsers = [];
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.list?.name ?? '');
    _selectedUids = List<String>.from(widget.list?.uids ?? []);
    if (_selectedUids.isNotEmpty) {
      _loadSelectedUsers();
    }
  }

  Future<void> _loadSelectedUsers() async {
    setState(() => _isLoading = true);
    final profiles = <UserProfile>[];
    for (final uid in _selectedUids) {
      final profile =
          await ref.read(profileRepositoryProvider).getUserProfile(uid);
      if (profile != null) profiles.add(profile);
    }
    setState(() {
      _selectedUsers = profiles;
      _isLoading = false;
    });
  }

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
      final results =
          await ref.read(firestoreRepositoryProvider).searchUsers(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _saveList() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a list name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid != null) {
      if (widget.list == null) {
        await ref.read(profileRepositoryProvider).createCustomList(
              uid: uid,
              name: name,
              memberUids: _selectedUids,
            );
      } else {
        await ref.read(profileRepositoryProvider).updateCustomList(
              uid: uid,
              listId: widget.list!.id,
              name: name,
              memberUids: _selectedUids,
            );
      }
    }
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  Future<void> _deleteList() async {
    setState(() => _isLoading = true);
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid != null && widget.list != null) {
      await ref.read(profileRepositoryProvider).deleteCustomList(
            uid: uid,
            listId: widget.list!.id,
          );
    }
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F9FB),
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.list == null ? 'Create List' : 'Edit List',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.list != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              onPressed: _showDeleteDialog,
            ),
          TextButton(
            onPressed: _isLoading ? null : _saveList,
            child: Text(
              'Save',
              style: GoogleFonts.outfit(
                color: AppColors.electricBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // List Name Field
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: _nameController,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'List Name (e.g. Family)',
                      hintStyle: GoogleFonts.outfit(
                          color: Colors.grey.withValues(alpha: 0.5)),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.edit_rounded,
                          color: AppColors.electricBlue, size: 20),
                    ),
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _performSearch,
                            style: GoogleFonts.outfit(
                                color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Search people to add...',
                              hintStyle: GoogleFonts.outfit(
                                  color: Colors.grey, fontSize: 14),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: _searchController.text.isNotEmpty
                      ? _buildSearchResults(isDark, currentUser?.uid)
                      : _buildSelectedList(isDark),
                ),
              ],
            ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content:
            const Text('Are you sure you want to delete this privacy list?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteList();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDark, String? currentUid) {
    if (_isSearching) return const Center(child: CircularProgressIndicator());
    if (_searchResults.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        if (user.uid == currentUid) return const SizedBox.shrink();
        final isSelected = _selectedUids.contains(user.uid);

        return _UserTile(
          user: user,
          isDark: isDark,
          trailing: IconButton(
            icon: Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              color: isSelected ? AppColors.electricBlue : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                if (isSelected) {
                  _selectedUids.remove(user.uid);
                  _selectedUsers.removeWhere((u) => u.uid == user.uid);
                } else {
                  _selectedUids.add(user.uid);
                  _selectedUsers.add(user);
                }
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectedList(bool isDark) {
    if (_selectedUsers.isEmpty) {
      return Center(
        child: Text(
          'No members added yet',
          style: GoogleFonts.outfit(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _selectedUsers.length,
      itemBuilder: (context, index) {
        final user = _selectedUsers[index];
        return _UserTile(
          user: user,
          isDark: isDark,
          trailing: TextButton(
            onPressed: () {
              setState(() {
                _selectedUids.remove(user.uid);
                _selectedUsers.removeAt(index);
              });
            },
            child:
                const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile(
      {required this.user, required this.isDark, required this.trailing});
  final UserProfile user;
  final bool isDark;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
          ),
          title: Text(
            user.displayName,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text('@${user.username}',
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
          trailing: trailing,
        ),
      );
}
