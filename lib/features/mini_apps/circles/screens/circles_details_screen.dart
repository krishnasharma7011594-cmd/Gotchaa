import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/circle_model.dart';
import '../models/circle_join_request.dart';
import '../providers/circles_onboarding_provider.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/trust_badge_widget.dart';
import 'circles_chat_screen.dart';

class CirclesDetailsScreen extends ConsumerStatefulWidget {
  final CircleModel circle;

  const CirclesDetailsScreen({
    super.key,
    required this.circle,
  });

  @override
  ConsumerState<CirclesDetailsScreen> createState() => _CirclesDetailsScreenState();
}

class _CirclesDetailsScreenState extends ConsumerState<CirclesDetailsScreen> {
  final TextEditingController _introController = TextEditingController();
  bool _isRequestSent = false;

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Future<void> _sendJoinRequest() async {
    final service = ref.read(circlesFirestoreServiceProvider);
    
    if (widget.circle.isApprovalRequired) {
      await service.sendJoinRequest(widget.circle.id, _introController.text);
      setState(() => _isRequestSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Join request sent successfully! Host will review your trust metrics.')),
      );
    } else {
      // Direct join
      await FirebaseFirestore.instance.collection('circles').doc(widget.circle.id).update({
        'memberIds': FieldValue.arrayUnion([service.currentUserId])
      });
      // Award direct karma
      await service.updateUserKarma(service.currentUserId, 10);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Joined circle! You gained +10 Participation Karma.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(circlesFirestoreServiceProvider);
    final isHost = widget.circle.hostId == service.currentUserId;
    final isMember = widget.circle.memberIds.contains(service.currentUserId) || isHost;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        title: Text(widget.circle.title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                widget.circle.coverImageUrl.isNotEmpty 
                    ? widget.circle.coverImageUrl 
                    : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.purple.withOpacity(0.2),
                  child: const Icon(Icons.image, color: Colors.white54, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category & City info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    widget.circle.category,
                    style: GoogleFonts.outfit(color: AppColors.primaryGlow, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  widget.circle.city,
                  style: GoogleFonts.inter(color: context.textSecondary, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title & Host Badge
            Text(
              widget.circle.title,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.circle.description,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),

            // Trust Badging
            const TrustBadgeWidget(
              karmaScore: 180,
              attendanceRate: 98.0,
            ),
            const SizedBox(height: 24),

            // Location privacy container
            GlassmorphicCard(
              borderRadius: 20,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isMember ? Icons.location_on : Icons.lock_outline_rounded,
                          color: isMember ? AppColors.primaryGlow : AppColors.karmaOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isMember ? 'Meetup Location Details' : 'Location Locked',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMember 
                          ? '${widget.circle.locationName} (${widget.circle.locationLatLng?.latitude}, ${widget.circle.locationLatLng?.longitude})'
                          : '${widget.circle.locationName} • Delhi (Exact GPS locked until you join.)',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Joined Action / Join form
            if (isMember) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CirclesChatScreen(circleId: widget.circle.id, circleTitle: widget.circle.title),
                    ),
                  );
                },
                icon: const Icon(Icons.forum_rounded, color: Colors.white),
                label: Text('Enter Group Chat', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ] else if (_isRequestSent) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    '⏳ Pending Host Approval',
                    style: GoogleFonts.outfit(color: AppColors.karmaOrange, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ] else ...[
              if (widget.circle.isApprovalRequired) ...[
                Text(
                  'Introduction message',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _introController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tell the host why you want to join...',
                    hintStyle: TextStyle(color: context.textSecondary),
                    filled: true,
                    fillColor: context.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _sendJoinRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vibrantPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  widget.circle.isApprovalRequired ? 'Request to Join Vibe' : 'Join Circle Direct',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],

            // Host view: Join requests lists
            if (isHost) ...[
              const SizedBox(height: 32),
              Text(
                'Pending Join Requests',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<CircleJoinRequest>>(
                stream: service.streamHostRequests(widget.circle.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'No pending join requests.',
                        style: GoogleFonts.inter(color: context.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final req = snapshot.data![index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GlassmorphicCard(
                          blur: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      req.userName,
                                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.karmaOrange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Text(
                                        'Karma: ${req.karmaScore} (${req.trustTier})',
                                        style: GoogleFonts.outfit(color: AppColors.karmaOrange, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (req.introMessage.isNotEmpty)
                                  Text(
                                    '"${req.introMessage}"',
                                    style: GoogleFonts.inter(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 13),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => service.updateJoinRequest(req, false),
                                      child: const Text('Reject', style: TextStyle(color: AppColors.error)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => service.updateJoinRequest(req, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGlow),
                                      child: const Text('Accept', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            ]
          ],
        ),
      ),
    );
  }
}
