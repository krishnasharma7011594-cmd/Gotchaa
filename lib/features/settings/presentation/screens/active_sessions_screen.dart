import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';

class ActiveSessionsScreen extends StatelessWidget {
  const ActiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : const Color(0xFFF8F9FB);
    final textPrimary = isDark ? AppColors.darkTextPrimary : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Active Sessions',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Sign in required'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users_private')
                  .doc(uid)
                  .collection('sessions')
                  .orderBy('lastActive', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (docs.isEmpty)
                      Text('No session history yet.',
                          style: GoogleFonts.outfit(color: textPrimary)),
                    ...docs.map((d) {
                      final data = d.data()! as Map<String, dynamic>;
                      final device =
                          data['deviceName'] as String? ?? 'Unknown device';
                      final location = data['location'] as String? ?? 'Unknown';
                      final last = data['lastActive'];
                      final ts =
                          last is Timestamp ? last.toDate() : DateTime.now();
                      final isCurrent = data['isCurrent'] == true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(device,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '$location · ${DateFormat.yMMMd().add_jm().format(ts)}${isCurrent ? ' · This device' : ''}',
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                          trailing: isCurrent
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.logout_rounded,
                                      color: AppColors.error),
                                  onPressed: () =>
                                      _revokeSession(context, d.id),
                                ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => _revokeAllOther(context, uid),
                      child: const Text('Revoke all other sessions'),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _revokeSession(BuildContext context, String sessionId) async {
    try {
      await FirebaseFunctions.instance.httpsCallable('revokeSession').call({
        'sessionId': sessionId,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session revoked')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _revokeAllOther(BuildContext context, String uid) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('revokeAllOtherSessions')
          .call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Other sessions revoked')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }
}
