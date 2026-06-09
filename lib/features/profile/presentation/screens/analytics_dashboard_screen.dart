import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/analytics_providers.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

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
              Text(
                context.tr('analytics_overview_7d'),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _OverviewGrid(data: data),
              const SizedBox(height: 32),
              Text(
                context.tr('analytics_views_trend'),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: _ViewsLineChart(history: data.viewsHistory),
              ),
              const SizedBox(height: 32),
              Text(
                context.tr('analytics_follower_growth'),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _FollowerBarChart(),
              ),
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
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.data});
  final CreatorAnalyticsData data;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      context,
                      context.tr('analytics_stat_views'),
                      '👁️',
                      data.totalViews,
                      23,
                      true)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                      context,
                      context.tr('analytics_stat_likes'),
                      '❤️',
                      data.totalLikes,
                      15,
                      true)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      context,
                      context.tr('profile_followers'),
                      '👥',
                      data.followersChange,
                      8,
                      true)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                      context,
                      context.tr('analytics_stat_shares'),
                      '🔗',
                      89,
                      -5,
                      false)),
            ],
          ),
        ],
      );

  Widget _buildStatCard(BuildContext context, String title, String emoji,
          int value, int change, bool isPositive) =>
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
                Text(emoji, style: const TextStyle(fontSize: 16)),
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
              _formatNumber(value),
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  '${change.abs()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}

class _ViewsLineChart extends StatelessWidget {
  const _ViewsLineChart({required this.history});
  final List<double> history;

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];
    for (int i = 0; i < history.length && i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), history[i]));
    }

    if (spots.isEmpty) {
      spots = [
        const FlSpot(0, 0),
        const FlSpot(1, 10),
        const FlSpot(2, 5),
        const FlSpot(3, 20),
        const FlSpot(4, 15),
        const FlSpot(5, 30),
        const FlSpot(6, 25)
      ];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.divider, width: 1),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  const days = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun'
                  ];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      days[value.toInt() % 7],
                      style: GoogleFonts.outfit(
                          color: context.textSecondary, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: const LinearGradient(
                  colors: [Colors.purpleAccent, Colors.blueAccent]),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.purpleAccent.withOpacity(0.3),
                    Colors.blueAccent.withOpacity(0)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots
                  .map((spot) => LineTooltipItem(
                        context.tr('analytics_views_count',
                            namedArgs: {'count': spot.y.toInt().toString()}),
                        GoogleFonts.outfit(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}

class _FollowerBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.divider, width: 1),
        ),
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(
                  x: 0,
                  barRods: [BarChartRodData(toY: 10, color: Colors.green)]),
              BarChartGroupData(
                  x: 1, barRods: [BarChartRodData(toY: -5, color: Colors.red)]),
              BarChartGroupData(
                  x: 2,
                  barRods: [BarChartRodData(toY: 15, color: Colors.green)]),
              BarChartGroupData(
                  x: 3,
                  barRods: [BarChartRodData(toY: 8, color: Colors.green)]),
              BarChartGroupData(
                  x: 4, barRods: [BarChartRodData(toY: -2, color: Colors.red)]),
              BarChartGroupData(
                  x: 5,
                  barRods: [BarChartRodData(toY: 20, color: Colors.green)]),
              BarChartGroupData(
                  x: 6,
                  barRods: [BarChartRodData(toY: 25, color: Colors.green)]),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 800.ms);
}
