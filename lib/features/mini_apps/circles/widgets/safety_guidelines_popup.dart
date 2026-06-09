import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'glassmorphic_card.dart';

class SafetyGuidelinesPopup extends StatelessWidget {

  const SafetyGuidelinesPopup({
    required this.onAccepted, super.key,
  });
  final VoidCallback onAccepted;

  @override
  Widget build(BuildContext context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassmorphicCard(
        borderRadius: 28,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.karmaOrange.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.karmaOrange, width: 2),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: AppColors.karmaOrange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Real-World Safety Guidelines',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSafetyItem(
                        Icons.people_alt_rounded,
                        'Meet in Public Spaces',
                        'Always plan your initial meetup in crowded, public venues such as coffee shops, parks, or sports hubs.',
                      ),
                      const SizedBox(height: 12),
                      _buildSafetyItem(
                        Icons.visibility_off_rounded,
                        'Privacy Control',
                        'Exact coordinates are hidden until you are a confirmed member. Never share sensitive personal details.',
                      ),
                      const SizedBox(height: 12),
                      _buildSafetyItem(
                        Icons.gavel_rounded,
                        'Zero Tolerance Policy',
                        'Harassment, offensive behavior, or deceptive profiles will result in an immediate lifetime ban. Utilize blocking and reporting tools.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onAccepted();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'I Understand, Let\'s Go!',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  Widget _buildSafetyItem(IconData icon, String title, String body) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryGlow, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
}
