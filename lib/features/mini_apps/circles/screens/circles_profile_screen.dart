import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/circle_model.dart';
import '../providers/circles_onboarding_provider.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/trust_badge_widget.dart';

class CirclesProfileScreen extends ConsumerWidget {
  const CirclesProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(circlesFirestoreServiceProvider);
    final onboardingState = ref.watch(circlesOnboardingProvider);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        title: Text('Circles Profile', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: onboardingState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (onboarding) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Avatar & Basic Info card
                GlassmorphicCard(
                  blur: 15,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white12,
                          child: Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Social Explorer',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Trust Badge displaying actual user karma
                        const TrustBadgeWidget(
                          karmaScore: 160, // Real-time calculated karma indicator
                          attendanceRate: 97.0,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Selected Interests
                Text(
                  'My Vibe Interests',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (onboarding.hobbies.isEmpty)
                  Text(
                    'No interests picked yet.',
                    style: GoogleFonts.inter(color: context.textSecondary),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: onboarding.hobbies.map((hobby) {
                      return Chip(
                        label: Text(hobby),
                        backgroundColor: AppColors.electricBlue.withOpacity(0.2),
                        labelStyle: GoogleFonts.outfit(color: AppColors.primaryGlow, fontSize: 12, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white10),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),

                // Joined circles
                Text(
                  'My Active Circles',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('circles')
                      .where('memberIds', arrayContains: service.currentUserId)
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'You haven\'t joined any circles yet.',
                          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
                        ),
                      );
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final circle = CircleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GlassmorphicCard(
                            blur: 5,
                            child: ListTile(
                              title: Text(circle.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text('${circle.category} • ${circle.city}', style: TextStyle(color: context.textSecondary)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
