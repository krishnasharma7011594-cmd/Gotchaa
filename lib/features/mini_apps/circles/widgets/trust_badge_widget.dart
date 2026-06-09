import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class TrustBadgeWidget extends StatelessWidget {
  final int karmaScore;
  final double attendanceRate;
  final bool showLabel;

  const TrustBadgeWidget({
    super.key,
    required this.karmaScore,
    required this.attendanceRate,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    // 0–50: new, 51–200: trusted, 201+: verified
    String tierName;
    Color tierColor;
    IconData tierIcon;

    if (karmaScore >= 201) {
      tierName = 'Verified';
      tierColor = AppColors.primaryGlow;
      tierIcon = Icons.verified_rounded;
    } else if (karmaScore >= 51) {
      tierName = 'Trusted';
      tierColor = AppColors.karmaOrange;
      tierIcon = Icons.stars_rounded;
    } else {
      tierName = 'New';
      tierColor = Colors.tealAccent;
      tierIcon = Icons.explore_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withOpacity(0.4), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tierIcon, color: tierColor, size: 16),
          const SizedBox(width: 4),
          Text(
            '$tierName • Karma: $karmaScore',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (attendanceRate > 0) ...[
            const SizedBox(width: 6),
            Container(
              width: 1,
              height: 12,
              color: Colors.white24,
            ),
            const SizedBox(width: 6),
            Text(
              '${attendanceRate.toStringAsFixed(0)}% Rate',
              style: GoogleFonts.outfit(
                color: AppColors.karmaAura,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
