import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../data/mini_app_model.dart';

class MiniAppDetailsScreen extends StatelessWidget {
  const MiniAppDetailsScreen({required this.app, super.key});
  final MiniApp app;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero header ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: app.accentColor,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        app.accentColor,
                        app.accentColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Hero(
                      tag: 'mini_app_icon_${app.id}',
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Icon(app.icon, color: Colors.white, size: 48),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                        )
                        .fadeIn(),
                  ),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + category + share
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      app.accentColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  app.categoryLabel,
                                  style: GoogleFonts.outfit(
                                    color: app.accentColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GlassCard(
                          borderRadius: 14,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.share_rounded,
                              size: 20,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideY(begin: 0.05),

                    const SizedBox(height: 24),

                    // Tagline
                    Text(
                      app.tagline,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description
                    Text(
                      'About',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      app.description,
                      style: GoogleFonts.outfit(
                        color: Colors.grey.shade600,
                        height: 1.6,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Features
                    Text(
                      'Features',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    ...app.features.asMap().entries.map((entry) => _FeatureRow(
                          icon: _featureIcons[entry.key % _featureIcons.length],
                          text: entry.value,
                          color: app.accentColor,
                          delay: entry.key * 80,
                        )),

                    const SizedBox(height: 40),

                    // Stats row
                    Row(
                      children: [
                        _StatBubble(
                          label: 'Users',
                          value: '2.4k',
                          color: app.accentColor,
                        ),
                        const SizedBox(width: 12),
                        _StatBubble(
                          label: 'Rating',
                          value: '4.8',
                          color: app.accentColor,
                        ),
                        const SizedBox(width: 12),
                        _StatBubble(
                          label: 'Karma',
                          value: '+15',
                          color: app.accentColor,
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 300)),

                    const SizedBox(height: 40),

                    // Launch button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              app.accentColor,
                              app.accentColor.withValues(alpha: 0.75)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: app.accentColor.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${app.name} coming soon!',
                                  style: GoogleFonts.outfit(),
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.rocket_launch_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Launch ${app.name}',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 400))
                        .slideY(begin: 0.15),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  static const List<IconData> _featureIcons = [
    Icons.bolt_rounded,
    Icons.people_alt_rounded,
    Icons.wallet_rounded,
    Icons.star_rounded,
  ];
}

// ─── Reusable sub-widgets ────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.color,
    required this.delay,
  });
  final IconData icon;
  final String text;
  final Color color;
  final int delay;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: delay))
          .slideX(begin: 0.08);
}

class _StatBubble extends StatelessWidget {
  const _StatBubble({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
}
