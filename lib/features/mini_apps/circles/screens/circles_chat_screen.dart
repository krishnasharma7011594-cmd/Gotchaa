import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/circle_message.dart';
import '../providers/circles_chat_provider.dart';
import '../providers/circles_onboarding_provider.dart';
import '../widgets/glassmorphic_card.dart';

import '../models/circle_model.dart';
import 'checkin_qr_screen.dart';
import 'checkin_scanner_screen.dart';
import '../services/circles_live_location_service.dart';
import '../widgets/circles_live_map_widget.dart';

class CirclesChatScreen extends ConsumerStatefulWidget {
  final String circleId;
  final String circleTitle;

  const CirclesChatScreen({
    super.key,
    required this.circleId,
    required this.circleTitle,
  });

  @override
  ConsumerState<CirclesChatScreen> createState() => _CirclesChatScreenState();
}

class _CirclesChatScreenState extends ConsumerState<CirclesChatScreen> with WidgetsBindingObserver {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  CircleModel? _circle;
  bool _hasCheckedIn = false;
  bool _shareLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCircleAndCheckInStatus();
  }

  Future<void> _loadCircleAndCheckInStatus() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('circles').doc(widget.circleId).get();
      if (doc.exists && mounted) {
        setState(() {
          _circle = CircleModel.fromMap(doc.data()!, doc.id);
        });
      }

      // Check if user is checked in
      final service = ref.read(circlesFirestoreServiceProvider);
      final checkinSnap = await FirebaseFirestore.instance
          .collection('circles')
          .doc(widget.circleId)
          .collection('checkins')
          .doc(service.currentUserId)
          .get();
      
      if (mounted) {
        setState(() {
          _hasCheckedIn = checkinSnap.exists;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Stop sharing immediately in background to conserve battery and cost (Cost Protection)
      if (_shareLocation) {
        CirclesLiveLocationService.instance.stopSharing(widget.circleId);
      }
    } else if (state == AppLifecycleState.resumed) {
      // Re-enable if toggled on
      if (_shareLocation && _circle != null) {
        CirclesLiveLocationService.instance.startSharing(widget.circleId, _circle!).catchError((_) {
          setState(() => _shareLocation = false);
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CirclesLiveLocationService.instance.disposeListeners(widget.circleId);
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    ref.read(circlesChatProvider(widget.circleId).notifier).sendMessage(
      widget.circleId,
      _msgController.text.trim(),
    );
    _msgController.clear();
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _pinMeetupLocation() {
    // Hosts can pin event coordinate details (Connaught Place coordinates)
    ref.read(circlesChatProvider(widget.circleId).notifier).pinLocation(
      widget.circleId,
      'Central Park Cafe, Outer Circle',
      28.6139,
      77.2090,
      'Neon Blue Glow',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📍 Meetup location pinned! Visible to all members.')),
    );
  }

  void _showSafetyOptions(CircleMessage msg) {
    final service = ref.read(circlesFirestoreServiceProvider);
    final isMe = msg.senderId == service.currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.bg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Safety & Moderation Options',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Report Button
            ListTile(
              leading: const Icon(Icons.flag_rounded, color: AppColors.karmaOrange),
              title: const Text('Report Message / Behavior', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.of(context).pop();
                await service.reportItem(
                  itemType: 'message',
                  itemId: msg.messageId,
                  reportedUserId: msg.senderId,
                  reason: 'Offensive language / breaking rules',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🛡️ Report submitted. Gotchaa safety moderators will review this.')),
                );
              },
            ),

            // Block Button (if not me)
            if (!isMe)
              ListTile(
                leading: const Icon(Icons.block_rounded, color: AppColors.error),
                title: Text('Block ${msg.senderName}', style: const TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.of(context).pop();
                  await service.blockUser(msg.senderId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('🛡️ Blocked ${msg.senderName}. Restarting chat view...')),
                  );
                },
              ),
            
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(circlesChatProvider(widget.circleId));
    final service = ref.read(circlesFirestoreServiceProvider);
    final isHost = _circle != null && _circle!.hostId == service.currentUserId;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.circleTitle, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Temporary Group Chat', style: GoogleFonts.inter(color: context.textSecondary, fontSize: 11)),
          ],
        ),
        actions: [
          if (_circle != null) ...[
            if (isHost)
              IconButton(
                icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryGlow),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CheckInQrScreen(circle: _circle!)),
                  );
                },
                tooltip: 'Generate Check-in QR',
              )
            else
              IconButton(
                icon: const Icon(Icons.camera_alt_rounded, color: Colors.greenAccent),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CheckInScannerScreen(circle: _circle!)),
                  );
                },
                tooltip: 'Check In',
              ),
          ],
          IconButton(
            icon: const Icon(Icons.pin_drop_rounded, color: AppColors.primaryGlow),
            onPressed: _pinMeetupLocation,
            tooltip: 'Pin Meetup Location',
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat warnings
            Container(
              color: AppColors.karmaOrange.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.security, color: AppColors.karmaOrange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All group chat messages expire 24 hours after the meetup event ends.',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            if (_hasCheckedIn && _circle != null && CirclesLiveLocationService.instance.isEventWindowActive(_circle!)) ...[
              // Safety Warning Banner
              if (_shareLocation)
                Container(
                  color: Colors.green.withOpacity(0.15),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your location is being shared with circle members',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Share Toggle Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: GlassmorphicCard(
                  borderRadius: 16,
                  child: SwitchListTile(
                    value: _shareLocation,
                    title: Text(
                      'Live Location Radar',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Share your coordinate coordinates with other checked-in attendees.',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 10),
                    ),
                    activeColor: AppColors.primaryGlow,
                    onChanged: (val) async {
                      try {
                        if (val) {
                          await CirclesLiveLocationService.instance.startSharing(widget.circleId, _circle!);
                          setState(() => _shareLocation = true);
                        } else {
                          await CirclesLiveLocationService.instance.stopSharing(widget.circleId);
                          setState(() => _shareLocation = false);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sharing Error: $e')));
                      }
                    },
                  ),
                ),
              ),

              // Live Location Map Radar widget
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CirclesLiveMapWidget(circleId: widget.circleId, circle: _circle!),
              ),
            ],

            if (chatState.isThrottled)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '⚠️ FireStore cost protection active. Throttling reads.',
                  style: GoogleFonts.outfit(color: AppColors.error, fontSize: 11),
                ),
              ),

            // Messages log
            Expanded(
              child: chatState.messages.isEmpty
                  ? Center(
                      child: Text(
                        'Say hello! This circle\'s chat is empty.',
                        style: GoogleFonts.outfit(color: context.textSecondary, fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        final isMe = msg.senderId == service.currentUserId;

                        if (msg.isPinned && msg.pinLocation != null) {
                          // Display beautiful custom pinned layout card
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: GlassmorphicCard(
                              borderRadius: 16,
                              blur: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.push_pin_rounded, color: AppColors.primaryGlow, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'PINNED MEETUP LOCATION',
                                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      msg.pinLocation!['title'] ?? '',
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Coordinates: (${msg.pinLocation!['lat']}, ${msg.pinLocation!['lng']}) • Style: ${msg.pinLocation!['style']}',
                                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white12,
                                    backgroundImage: msg.senderAvatar.isNotEmpty ? NetworkImage(msg.senderAvatar) : null,
                                    child: msg.senderAvatar.isEmpty ? const Icon(Icons.person, size: 16, color: Colors.white) : null,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: GestureDetector(
                                    onLongPress: () => _showSafetyOptions(msg),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isMe ? AppColors.electricBlue : context.surface,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: Radius.circular(isMe ? 16 : 0),
                                          bottomRight: Radius.circular(isMe ? 0 : 16),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (!isMe)
                                            Text(
                                              msg.senderName,
                                              style: GoogleFonts.outfit(color: AppColors.primaryGlow, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          Text(
                                            msg.text,
                                            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('hh:mm a').format(msg.timestamp),
                                            style: TextStyle(color: Colors.white54, fontSize: 9),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Message bar input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: context.textSecondary),
                        filled: true,
                        fillColor: context.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.electricBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
