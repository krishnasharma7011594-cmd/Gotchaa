import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/circle_model.dart';
import '../services/circles_checkin_service.dart';
import '../widgets/glassmorphic_card.dart';

class CheckInQrScreen extends StatefulWidget {

  const CheckInQrScreen({
    required this.circle, super.key,
  });
  final CircleModel circle;

  @override
  State<CheckInQrScreen> createState() => _CheckInQrScreenState();
}

class _CheckInQrScreenState extends State<CheckInQrScreen> {
  String _token = '';
  int _secondsLeft = 1800; // 30 minutes expiration timer

  @override
  void initState() {
    super.initState();
    _generateToken();
    _startTimer();
  }

  void _generateToken() {
    final token = CirclesCheckInService.instance.generateQrToken(
      circleId: widget.circle.id,
      eventDate: widget.circle.eventDate,
      hostId: widget.circle.hostId,
    );
    setState(() => _token = token);
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        }
      });
      return _secondsLeft > 0;
    });
  }

  String _formatTime(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        title: Text('Check-In QR Code', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Let your members scan this code to verify their attendance!',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Custom Glass QR display
              Center(
                child: GlassmorphicCard(
                  borderRadius: 28,
                  blur: 15,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(12),
                          child: QrImageView(
                            data: _token,
                            version: QrVersions.auto,
                            size: 200,
                            gapless: false,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer, color: AppColors.karmaOrange, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'QR Code Expires in: ${_formatTime(_secondsLeft)}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _secondsLeft = 1800;
                    _generateToken();
                  });
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Regenerate Token', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
}
