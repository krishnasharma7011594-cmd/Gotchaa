import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/analytics_providers.dart';

class CreatorAnalyticsScreen extends ConsumerWidget {
  const CreatorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(creatorAnalyticsProvider);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(
          context.tr('analytics_title'),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: context.textPrimary,
          ),
        ),
        backgroundColor: context.bg,
        elevation: 0,
        centerTitle: true,
      ),
      body: analyticsAsync.when(
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header stats
              Text(
                context.tr('analytics_overview'),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard(
                          context,
                          context.tr('analytics_stat_views'),
                          _formatNumber(data.totalViews),
                          '+15%',
                          true)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildStatCard(
                          context,
                          context.tr('analytics_stat_watch_time'),
                          context.tr('analytics_hrs', namedArgs: {
                            'count': data.watchTimeHrs.toString()
                          }),
                          '+22%',
                          true)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard(
                          context,
                          context.tr('analytics_stat_engagements'),
                          _formatNumber(data.totalEngagements),
                          '+5%',
                          true)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildStatCard(
                          context,
                          context.tr('analytics_stat_posts'),
                          '${data.postsCount + data.vybzCount}',
                          '+1.2%',
                          true)),
                ],
              ),
              const SizedBox(height: 32),

              // Views Chart
              Text(
                context.tr('analytics_views_performance'),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildChart(context, data.viewsHistory),
              const SizedBox(height: 32),

              // Demographics Mock
              Text(
                context.tr('analytics_audience'),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildDemographicsMock(context),
              const SizedBox(height: 48),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Text(context.tr('error_prefix', args: [err.toString()]))),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildChart(BuildContext context, List<double> history) {
    // Reuse existing chart UI but with dynamic data
    final labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    // Normalize history for the chart bars
    double max = 0.1;
    for (final v in history) {
      if (v > max) max = v;
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.divider, width: 1),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(history.length, (index) {
                final ratio = history[index] / max;
                return Tooltip(
                  message: '${_formatNumber(history[index].toInt())} Views',
                  child: Container(
                    width: 16,
                    height: 140 * ratio.clamp(0.05, 1.0),
                    decoration: BoxDecoration(
                      gradient: AppColors.electricGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ).animate().scaleY(
                        begin: 0,
                        end: 1,
                        curve: Curves.easeOutBack,
                        duration: 600.ms,
                        delay: (index * 50).ms,
                        alignment: Alignment.bottomCenter,
                      ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
                labels.length,
                (index) => Text(
                      labels[index],
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: context.textSecondary,
                      ),
                    )),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
          String change, bool isPositive) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.divider, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context
                  .tr('analytics_vs_last_month', namedArgs: {'change': change}),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);

  Widget _buildDemographicsMock(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.divider, width: 1),
        ),
        child: Column(
          children: [
            // Gender Split
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.tr('analytics_gender_split'),
                    style: GoogleFonts.outfit(color: context.textSecondary)),
                Text('62% F / 38% M',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 12,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  Expanded(
                      flex: 62, child: Container(color: Colors.pinkAccent)),
                  Expanded(
                      flex: 38,
                      child: Container(color: AppColors.electricBlue)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Age Groups
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.tr('analytics_top_age'),
                    style: GoogleFonts.outfit(color: context.textSecondary)),
                Text('18-24 (45%)',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            _buildAgeBar(context, '13-17', 0.25, Colors.purpleAccent),
            const SizedBox(height: 8),
            _buildAgeBar(context, '18-24', 0.45, AppColors.electricBlue),
            const SizedBox(height: 8),
            _buildAgeBar(context, '25-34', 0.20, Colors.tealAccent),
            const SizedBox(height: 8),
            _buildAgeBar(context, '35+', 0.10, Colors.orangeAccent),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms);

  Widget _buildAgeBar(
          BuildContext context, String label, double percentage, Color color) =>
      Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                  fontSize: 12, color: context.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                LayoutBuilder(
                    builder: (context, constraints) => Container(
                          height: 8,
                          width: constraints.maxWidth * percentage,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ).animate().scaleX(
                            begin: 0,
                            end: 1,
                            duration: 800.ms,
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.centerLeft)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '${(percentage * 100).toInt()}%',
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary),
            ),
          ),
        ],
      );
}
