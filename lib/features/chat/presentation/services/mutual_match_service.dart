import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

// --- MODELS ---

class SessionMatchState {

  SessionMatchState({
    required this.meWantsToKeep,
    required this.otherWantsToKeep,
    required this.isMutual,
    this.requestedAt,
    this.status,
  });
  final bool meWantsToKeep;
  final bool otherWantsToKeep;
  final bool isMutual;
  final DateTime? requestedAt;
  final String? status;
}

// --- SERVICE ---

class MutualMatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<SessionMatchState> watchSession(String sessionId, String myId) => _firestore.collection('randomSessions').doc(sessionId).snapshots().map((doc) {
      if (!doc.exists) {
        return SessionMatchState(meWantsToKeep: false, otherWantsToKeep: false, isMutual: false);
      }
      final data = doc.data()!;
      final isA = data['userAId'] == myId;
      
      final meWants = isA ? (data['userAWantsToKeep'] ?? false) : (data['userBWantsToKeep'] ?? false);
      final otherWants = isA ? (data['userBWantsToKeep'] ?? false) : (data['userAWantsToKeep'] ?? false);
      final mutual = data['status'] == 'mutualMatch';
      
      return SessionMatchState(
        meWantsToKeep: meWants,
        otherWantsToKeep: otherWants,
        isMutual: mutual,
        requestedAt: isA ? (data['userARequestedAt'] as Timestamp?)?.toDate() : (data['userBRequestedAt'] as Timestamp?)?.toDate(),
        status: data['status'],
      );
    });

  Future<void> requestKeepTalking(String sessionId, String myId) async {
    final docRef = _firestore.collection('randomSessions').doc(sessionId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      final isA = data['userAId'] == myId;
      
      if (isA) {
        transaction.update(docRef, {
          'userAWantsToKeep': true,
          'userARequestedAt': FieldValue.serverTimestamp(),
          'status': data['userBWantsToKeep'] == true ? 'mutualMatch' : 'keepRequested',
          if (data['userBWantsToKeep'] == true) 'mutualMatchAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.update(docRef, {
          'userBWantsToKeep': true,
          'userBRequestedAt': FieldValue.serverTimestamp(),
          'status': data['userAWantsToKeep'] == true ? 'mutualMatch' : 'keepRequested',
          if (data['userAWantsToKeep'] == true) 'mutualMatchAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> declineKeepTalking(String sessionId) async {
    await _firestore.collection('randomSessions').doc(sessionId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }
}

final mutualMatchServiceProvider = Provider((ref) => MutualMatchService());

// --- UI COMPONENTS ---

class KeepTalkingButton extends StatefulWidget {
  
  const KeepTalkingButton({required this.sessionId, required this.onRequested, super.key});
  final String sessionId;
  final VoidCallback onRequested;

  @override
  State<KeepTalkingButton> createState() => _KeepTalkingButtonState();
}

class _KeepTalkingButtonState extends State<KeepTalkingButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.electricBlue.withOpacity(0.3 * _pulseController.value),
                blurRadius: 15 * _pulseController.value,
                spreadRadius: 2 * _pulseController.value,
              ),
            ],
          ),
          child: child,
        ),
      child: ElevatedButton.icon(
        onPressed: widget.onRequested,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 5,
        ),
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
        label: Text(
          'Keep Talking',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
}

class WaitingIndicatorWidget extends StatelessWidget {
  
  const WaitingIndicatorWidget({required this.requestedAt, super.key});
  final DateTime requestedAt;

  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        final elapsed = DateTime.now().difference(requestedAt).inSeconds;
        final remaining = (30 - elapsed).clamp(0, 30);
        final progress = remaining / 30.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2,
                  color: AppColors.electricBlue,
                  backgroundColor: Colors.white10,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Waiting... ${remaining}s',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
}

class KeepTalkingPromptSheet extends StatelessWidget {

  const KeepTalkingPromptSheet({required this.onAccept, required this.onDecline, super.key});
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E), 
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 32),
          const SizedBox(height: 12),
          Text(
            'They want to keep talking!',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'You both match well. Want to continue this conversation permanently?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onDecline,
                  child: Text('Maybe Later', style: GoogleFonts.outfit(color: Colors.white38)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Keep Talking 💬', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutBack, duration: 500.ms);
}

class MutualMatchCelebrationScreen extends StatefulWidget {

  const MutualMatchCelebrationScreen({required this.onComplete, super.key, this.gameName});
  final VoidCallback onComplete;
  final String? gameName;

  @override
  State<MutualMatchCelebrationScreen> createState() => _MutualMatchCelebrationScreenState();
}

class _MutualMatchCelebrationScreenState extends State<MutualMatchCelebrationScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();
    HapticFeedback.heavyImpact();
    
    Timer(const Duration(seconds: 3), widget.onComplete);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_rounded, color: Colors.pink, size: 80)
                    .animate(onPlay: (c) => c.repeat())
                    .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 500.ms, curve: Curves.easeInOut),
                const SizedBox(height: 24),
                Text(
                  'It\'s a Match! 🎉',
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.gameName != null 
                    ? 'You matched after a great game of ${widget.gameName}! 🎮'
                    : 'You both want to keep talking!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 18, color: Colors.white70),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
          ),
        ],
      ),
    );
}

class ProfileRevealAnimation extends StatefulWidget {

  const ProfileRevealAnimation({
    required this.displayName, super.key, 
    this.imageUrl, 
    this.isAnonymous = false
  });
  final String? imageUrl;
  final String displayName;
  final bool isAnonymous;

  @override
  State<ProfileRevealAnimation> createState() => _ProfileRevealAnimationState();
}

class _ProfileRevealAnimationState extends State<ProfileRevealAnimation> {
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _revealed = true);
    });
  }

  @override
  Widget build(BuildContext context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
              child: const Icon(Icons.person, size: 60, color: Colors.white30),
            ),
            if (widget.imageUrl != null)
              AnimatedOpacity(
                opacity: _revealed && !widget.isAnonymous ? 1 : 0,
                duration: 1500.ms,
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl!,
                  imageBuilder: (context, imageProvider) => Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                      border: Border.all(color: AppColors.electricBlue, width: 2),
                    ),
                  ),
                  placeholder: (context, url) => Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    clipBehavior: Clip.antiAlias,
                    child: const BlurHash(hash: 'L5H2EC=pPdpWXVJs00QQV_9H00XY'),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.electricBlue, width: 2),
                    ),
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: 1000.ms,
          child: Text(
            _revealed && !widget.isAnonymous ? widget.displayName : 'Anonymous 👤',
            key: ValueKey(_revealed),
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
}

class RevealedProfileWidget extends StatelessWidget {

  const RevealedProfileWidget({
    required this.displayName, required this.memberSince, super.key, 
    this.photoUrl,
    this.isAnonymous = false,
  });
  final String displayName;
  final String? photoUrl;
  final DateTime memberSince;
  final bool isAnonymous;

  @override
  Widget build(BuildContext context) {
    final monthYear = '${_getMonth(memberSince.month)} ${memberSince.year}';
    
    return Row(
      children: [
        CachedNetworkImage(
          imageUrl: (!isAnonymous && photoUrl != null) ? photoUrl! : '',
          imageBuilder: (context, imageProvider) => CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white10,
            backgroundImage: imageProvider,
          ),
          placeholder: (context, url) => const CircleAvatar(
            radius: 20,
            child: BlurHash(hash: 'L5H2EC=pPdpWXVJs00QQV_9H00XY'),
          ),
          errorWidget: (context, url, error) => const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white10,
            child: Icon(Icons.person, color: Colors.white30),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAnonymous ? 'Gotchaa User 👤' : displayName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Member since $monthYear',
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
            ),
          ],
        ),
      ],
    );
  }

  String _getMonth(int m) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
}

class AnonymousProfileWidget extends StatelessWidget {
  const AnonymousProfileWidget({super.key});

  @override
  Widget build(BuildContext context) => Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white10,
          child: Icon(Icons.person, color: Colors.white30),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Anonymous 👤', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Matched via Random Chat', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
          ],
        ),
      ],
    );
}

class ConnectionMemoryWidget extends StatelessWidget {

  const ConnectionMemoryWidget({required this.metVia, required this.metAt, super.key});
  final String metVia;
  final DateTime metAt;

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(metAt);
    String timeAgo;
    if (diff.inDays > 0) {
      timeAgo = '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      timeAgo = '${diff.inHours} hours ago';
    } else {
      timeAgo = 'just now';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            metVia.contains('video') ? Icons.videocam : (metVia.contains('game') ? Icons.videogame_asset : Icons.chat_bubble),
            size: 14,
            color: AppColors.electricBlue,
          ),
          const SizedBox(width: 6),
          Text(
            'Met via $metVia • $timeAgo',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class ConnectionStatsWidget extends StatelessWidget {

  const ConnectionStatsWidget({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_rounded, color: AppColors.electricBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count connections made',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'through Gotchaa random matching',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
}

class RespondToMatchScreen extends ConsumerWidget {

  const RespondToMatchScreen({required this.sessionId, super.key});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).value?.uid;
    final matchService = ref.watch(mutualMatchServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 64).animate().shimmer(duration: 2.seconds),
              const SizedBox(height: 24),
              Text(
                'Someone wants to keep talking!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'You had a great conversation. Want to add them to your permanent connections?',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (userId != null) {
                      matchService.requestKeepTalking(sessionId, userId);
                      Navigator.pop(context); // Feedback handled by session listener elsewhere
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('YES, KEEP TALKING 💬', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  matchService.declineKeepTalking(sessionId);
                  Navigator.pop(context);
                },
                child: Text('MAYBE LATER', style: GoogleFonts.outfit(color: Colors.white38, letterSpacing: 1.1)),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }
}

