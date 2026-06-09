import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../features/profile/presentation/screens/user_profile_screen.dart';

class ResolveUsernameScreen extends ConsumerStatefulWidget {
  const ResolveUsernameScreen({required this.username, super.key});
  final String username;

  @override
  ConsumerState<ResolveUsernameScreen> createState() =>
      _ResolveUsernameScreenState();
}

class _ResolveUsernameScreenState extends ConsumerState<ResolveUsernameScreen> {
  bool _isLoading = true;
  String? _uid;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolveUsername();
  }

  Future<void> _resolveUsername() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(widget.username)
          .get();

      if (querySnapshot.exists && querySnapshot.data() != null) {
        final uid = querySnapshot.data()!['uid'] as String?;
        if (uid != null && uid.isNotEmpty) {
          if (mounted) {
            setState(() {
              _uid = uid;
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _error = 'User not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error resolving user: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.electricBlue),
        ),
      );
    }

    if (_error != null || _uid == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
        ),
        body: Center(
          child: Text(
            _error ?? 'User not found',
            style: GoogleFonts.outfit(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Success: We resolved the username to a UID.
    // Replace the current Resolve screen with the actual profile screen so it doesn't linger in navigator history.
    return UserProfileScreen(uid: _uid!);
  }
}
