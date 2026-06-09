import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/circle_model.dart';
import '../services/circles_checkin_service.dart';
import '../widgets/glassmorphic_card.dart';

class CheckInScannerScreen extends StatefulWidget {
  const CheckInScannerScreen({
    required this.circle,
    super.key,
  });
  final CircleModel circle;

  @override
  State<CheckInScannerScreen> createState() => _CheckInScannerScreenState();
}

class _CheckInScannerScreenState extends State<CheckInScannerScreen> {
  late ConfettiController _confettiController;
  bool _isCheckingProximity = false;
  bool _isWithinRange = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    _checkProximity();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkProximity() async {
    setState(() => _isCheckingProximity = true);
    final inRange =
        await CirclesCheckInService.instance.isWithinProximity(widget.circle);
    setState(() {
      _isWithinRange = inRange;
      _isCheckingProximity = false;
    });
  }

  Future<void> _triggerSimulatedQrScan() async {
    try {
      // Simulate decoding a valid base64 check-in payload
      final fakeToken = CirclesCheckInService.instance.generateQrToken(
        circleId: widget.circle.id,
        eventDate: widget.circle.eventDate,
        hostId: widget.circle.hostId,
      );

      await CirclesCheckInService.instance.processCheckIn(
        circleId: widget.circle.id,
        method: 'qr',
        qrToken: fakeToken,
      );

      setState(() => _success = true);
      _confettiController.play();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                '🎉 QR Code Check-in Verified! You gained +10 Karma points!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification Failed: $e')),
      );
    }
  }

  Future<void> _triggerProximityCheckIn() async {
    try {
      await CirclesCheckInService.instance.processCheckIn(
        circleId: widget.circle.id,
        method: 'proximity',
      );

      setState(() => _success = true);
      _confettiController.play();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                '🎉 Proximity GPS Check-in Verified! You gained +10 Karma points!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: context.bg,
          title: Text('Circle Check-In',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_success) ...[
                      // Success View
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.green, width: 2),
                              ),
                              child: const Icon(Icons.check_circle_rounded,
                                  color: Colors.green, size: 48),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Check-In Complete!',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You have successfully checked in to ${widget.circle.title}. Your trust karma has been updated.',
                              style: GoogleFonts.inter(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Main Viewfinder Simulation
                      Text(
                        'Scan the host\'s QR Code to verify your check-in!',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Viewfinder Box
                      GestureDetector(
                        onTap: _triggerSimulatedQrScan,
                        child: Center(
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.primaryGlow, width: 3),
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.black38,
                            ),
                            child: const Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.qr_code_scanner_rounded,
                                    color: AppColors.primaryGlow, size: 64),
                                Positioned(
                                  bottom: 16,
                                  child: Text(
                                    'Tap Box to Scan QR Code',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Proximity Gps details
                      GlassmorphicCard(
                        borderRadius: 20,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                _isWithinRange
                                    ? Icons.gps_fixed_rounded
                                    : Icons.gps_not_fixed_rounded,
                                color: _isWithinRange
                                    ? Colors.green
                                    : AppColors.karmaOrange,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GPS Proximity (200m Range)',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                    Text(
                                      _isCheckingProximity
                                          ? 'Verifying proximity GPS...'
                                          : _isWithinRange
                                              ? 'You are within the meetup range!'
                                              : 'Too far or coordinates not shared.',
                                      style: GoogleFonts.inter(
                                          color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              if (!_isCheckingProximity && _isWithinRange)
                                ElevatedButton(
                                  onPressed: _triggerProximityCheckIn,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  child: const Text('Check In',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      )
                    ]
                  ],
                ),
              ),

              // Confetti Cannon Overlay
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ],
              ),
            ],
          ),
        ),
      );
}
