import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/nation/nation_data.dart';
import '../../../../core/nation/nation_providers.dart';
import '../../../../core/nation/nation_widgets.dart';
import '../../../../core/theme/app_colors.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Match Preferences Screen
// ══════════════════════════════════════════════════════════════════════════════

enum MatchScope { worldwide, continent, country, preferred }

class MatchPreferencesScreen extends ConsumerStatefulWidget {
  const MatchPreferencesScreen({super.key});

  @override
  ConsumerState<MatchPreferencesScreen> createState() =>
      _MatchPreferencesScreenState();
}

class _MatchPreferencesScreenState
    extends ConsumerState<MatchPreferencesScreen> {
  MatchScope _scope = MatchScope.worldwide;
  final List<NationData> _preferredCountries = [];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
          title: Text(
            'Match Preferences',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800, color: Colors.black),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Who do you want to meet?',
                style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black),
              ).animate().fadeIn().slideX(begin: -0.1),
              const SizedBox(height: 6),
              Text(
                'Set how wide your random chat search casts.',
                style: GoogleFonts.outfit(color: Colors.grey.shade500),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 28),

              // ── Scope options ────────────────────────────────────────
              ...[
                _ScopeOption(
                  value: MatchScope.worldwide,
                  group: _scope,
                  icon: '🌍',
                  label: 'Worldwide',
                  subtitle: 'Match with anyone on earth',
                  onChanged: (v) => setState(() => _scope = v!),
                ),
                _ScopeOption(
                  value: MatchScope.continent,
                  group: _scope,
                  icon: '🌎',
                  label: 'Same Continent',
                  subtitle: 'Asia with Asia, Europe with Europe',
                  onChanged: (v) => setState(() => _scope = v!),
                ),
                _ScopeOption(
                  value: MatchScope.country,
                  group: _scope,
                  icon: '🏠',
                  label: 'Same Country',
                  subtitle: 'Only match within your home country',
                  onChanged: (v) => setState(() => _scope = v!),
                ),
                _ScopeOption(
                  value: MatchScope.preferred,
                  group: _scope,
                  icon: '⭐',
                  label: 'Preferred Countries',
                  subtitle: 'Pick up to 5 countries',
                  onChanged: (v) => setState(() => _scope = v!),
                ),
              ].animate(interval: 80.ms).fadeIn().slideX(begin: 0.05),

              // ── Preferred country picker (only when relevant) ─────────
              if (_scope == MatchScope.preferred) ...[
                const SizedBox(height: 20),
                _buildPreferredSection(),
              ],

              const SizedBox(height: 36),

              // ── Save button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.electricGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      'Save Preferences',
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      );

  Widget _buildPreferredSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Match me with people from:',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 12),

          // Selected chips
          if (_preferredCountries.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _preferredCountries
                  .map((n) => _NationChip(
                        nation: n,
                        onRemove: () =>
                            setState(() => _preferredCountries.remove(n)),
                      ))
                  .toList(),
            ),

          const SizedBox(height: 12),

          if (_preferredCountries.length < 5)
            OutlinedButton.icon(
              onPressed: _addPreferredCountry,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Add Country',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.electricBlue,
                side: const BorderSide(color: AppColors.electricBlue),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      );

  Future<void> _addPreferredCountry() async {
    final result = await showModalBottomSheet<NationData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CountryPickerBottomSheet(),
    );
    if (result != null &&
        !_preferredCountries.any((n) => n.countryCode == result.countryCode)) {
      setState(() => _preferredCountries.add(result));
    }
  }

  void _save() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Match preferences saved!',
            style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: AppColors.electricBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.value,
    required this.group,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onChanged,
  });
  final MatchScope value;
  final MatchScope group;
  final String icon;
  final String label;
  final String subtitle;
  final ValueChanged<MatchScope?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.electricBlue.withOpacity(0.05)
              : Colors.white,
          border: Border.all(
            color: selected ? AppColors.electricBlue : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.electricBlue
                              : Colors.black87)),
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Radio<MatchScope>(
              value: value,
              groupValue: group,
              onChanged: onChanged,
              activeColor: AppColors.electricBlue,
            ),
          ],
        ),
      ),
    );
  }
}

class _NationChip extends StatelessWidget {
  const _NationChip({required this.nation, required this.onRemove});
  final NationData nation;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Text(nation.flag, style: const TextStyle(fontSize: 14)),
        label: Text(nation.countryName,
            style:
                GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
        deleteIcon: const Icon(Icons.close_rounded, size: 14),
        onDeleted: onRemove,
        backgroundColor: AppColors.electricBlue.withOpacity(0.08),
        deleteIconColor: Colors.grey,
        side: BorderSide(color: AppColors.electricBlue.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// Nation Privacy Settings Screen
// ══════════════════════════════════════════════════════════════════════════════

class NationPrivacySettingsScreen extends StatefulWidget {
  const NationPrivacySettingsScreen({
    required this.onChanged,
    super.key,
    this.initial = NationVisibility.country,
  });
  final NationVisibility initial;
  final ValueChanged<NationVisibility> onChanged;

  @override
  State<NationPrivacySettingsScreen> createState() =>
      _NationPrivacySettingsScreenState();
}

class _NationPrivacySettingsScreenState
    extends State<NationPrivacySettingsScreen> {
  late NationVisibility _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
          title: Text(
            'My Location Privacy',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800, color: Colors.black),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What strangers see',
                style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black),
              ).animate().fadeIn(),
              const SizedBox(height: 6),
              Text(
                'Applies only to random chat. Friends always see your full country.',
                style: GoogleFonts.outfit(
                    color: Colors.grey.shade500, fontSize: 14),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 28),
              _PrivacyOption(
                value: NationVisibility.country,
                group: _selected,
                icon: '🇮🇳',
                label: 'Show my country',
                example: 'Strangers see: 🇮🇳 India',
                onChanged: _onSelect,
              ).animate().fadeIn(delay: 150.ms),
              _PrivacyOption(
                value: NationVisibility.continent,
                group: _selected,
                icon: '🌏',
                label: 'Show my continent only',
                example: 'Strangers see: 🌏 Asia',
                onChanged: _onSelect,
              ).animate().fadeIn(delay: 200.ms),
              _PrivacyOption(
                value: NationVisibility.private,
                group: _selected,
                icon: '🌍',
                label: 'Keep location private',
                example: 'Strangers see: 🌍 Somewhere on Earth',
                onChanged: _onSelect,
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.electricGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onChanged(_selected);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text('Save',
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      );

  void _onSelect(NationVisibility v) => setState(() => _selected = v);
}

class _PrivacyOption extends StatelessWidget {
  const _PrivacyOption({
    required this.value,
    required this.group,
    required this.icon,
    required this.label,
    required this.example,
    required this.onChanged,
  });
  final NationVisibility value;
  final NationVisibility group;
  final String icon;
  final String label;
  final String example;
  final ValueChanged<NationVisibility> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.electricBlue.withOpacity(0.05)
              : Colors.white,
          border: Border.all(
            color: selected ? AppColors.electricBlue : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.electricBlue
                              : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(example,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Radio<NationVisibility>(
              value: value,
              groupValue: group,
              onChanged: (v) => onChanged(v!),
              activeColor: AppColors.electricBlue,
            ),
          ],
        ),
      ),
    );
  }
}
