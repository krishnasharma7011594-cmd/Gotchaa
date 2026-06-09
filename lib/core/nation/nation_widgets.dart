import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/nation/nation_data.dart';
import '../../../core/nation/nation_database.dart';
import '../../../core/theme/app_colors.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CountrySelectorWidget — pre-filled, tappable, opens picker
// ══════════════════════════════════════════════════════════════════════════════

class CountrySelectorWidget extends ConsumerWidget {

  const CountrySelectorWidget({
    required this.onChanged, super.key,
    this.preselected,
    this.isRequired = true,
  });
  final NationData? preselected;
  final ValueChanged<NationData> onChanged;
  final bool isRequired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = preselected;

    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<NationData>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CountryPickerBottomSheet(
            initialSelection: selected,
          ),
        );
        if (result != null) onChanged(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected != null
                ? AppColors.electricBlue.withOpacity(0.4)
                : Colors.grey.shade200,
            width: selected != null ? 1.5 : 1,
          ),
          boxShadow: [
            if (selected != null)
              BoxShadow(
                color: AppColors.electricBlue.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // Flag / globe icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected != null
                    ? AppColors.electricBlue.withOpacity(0.08)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                selected?.flag ?? '🌍',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),

            // Country name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected?.countryName ?? 'Select your country',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected != null
                          ? Colors.black87
                          : Colors.grey.shade500,
                    ),
                  ),
                  if (selected != null)
                    Text(
                      selected.continent,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),

            // Change chevron
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.electricBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.electricBlue, size: 18),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CountryPickerBottomSheet — searchable list of all 195 countries
// ══════════════════════════════════════════════════════════════════════════════

class CountryPickerBottomSheet extends StatefulWidget {

  const CountryPickerBottomSheet({super.key, this.initialSelection});
  final NationData? initialSelection;

  @override
  State<CountryPickerBottomSheet> createState() =>
      _CountryPickerBottomSheetState();
}

class _CountryPickerBottomSheetState extends State<CountryPickerBottomSheet> {
  final _searchController = TextEditingController();
  List<NationData> _filtered = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filtered = NationDatabase.all();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    setState(() {
      _query = q;
      if (q.trim().isEmpty) {
        _filtered = NationDatabase.all();
      } else {
        _filtered = NationDatabase.search(q, limit: 60);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle ────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('🌍', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Text(
                  'Select Country',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Search field ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              autofocus: false,
              style: GoogleFonts.outfit(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search country…',
                hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
                prefixIcon:
                    Icon(Icons.search_rounded, color: Colors.grey.shade400),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade100, height: 1),

          // ── Country list ──────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final nation = _filtered[i];
                final isSelected =
                    widget.initialSelection?.countryCode == nation.countryCode;
                return _CountryTile(
                  nation: nation,
                  isSelected: isSelected,
                  onTap: () => Navigator.pop(context, nation),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {

  const _CountryTile({
    required this.nation,
    required this.isSelected,
    required this.onTap,
  });
  final NationData nation;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: isSelected
            ? AppColors.electricBlue.withOpacity(0.05)
            : Colors.transparent,
        child: Row(
          children: [
            Text(nation.flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nation.countryName,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.electricBlue
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    nation.continent,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.electricBlue, size: 20),
          ],
        ),
      ),
    );
}

// ══════════════════════════════════════════════════════════════════════════════
// NationProfileBadge — shown on user profile page
// ══════════════════════════════════════════════════════════════════════════════

class NationProfileBadge extends StatelessWidget {

  const NationProfileBadge({
    super.key,
    this.homeCountryCode,
    this.currentCountryCode,
    this.isTravelling = false,
  });
  final String? homeCountryCode;
  final String? currentCountryCode;
  final bool isTravelling;

  @override
  Widget build(BuildContext context) {
    final home = NationDatabase.fromCode(homeCountryCode);
    final current = NationDatabase.fromCode(currentCountryCode);

    if (home == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ContinentChip(nation: home),
        if (isTravelling && current != null && current.countryCode != home.countryCode) ...[
          const SizedBox(width: 8),
          _TravellingChip(currentNation: current),
        ],
      ],
    );
  }
}

class _ContinentChip extends StatelessWidget {
  const _ContinentChip({required this.nation});
  final NationData nation;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _hexToColor(nation.continentColorHex),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(nation.flag, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '${nation.countryName} • ${nation.continent}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
}

class _TravellingChip extends StatelessWidget {
  const _TravellingChip({required this.currentNation});
  final NationData currentNation;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✈️', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            'In ${currentNation.flag} ${currentNation.countryName}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
}

// ══════════════════════════════════════════════════════════════════════════════
// NationPostBadge — compact badge below username on feed posts
// ══════════════════════════════════════════════════════════════════════════════

class NationPostBadge extends StatelessWidget {

  const NationPostBadge({super.key, this.countryCode});
  final String? countryCode;

  @override
  Widget build(BuildContext context) {
    final nation = NationDatabase.fromCode(countryCode);
    if (nation == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(nation.flag, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          nation.countryName,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// StrangerNationBadge — shown in random text chat header
// ══════════════════════════════════════════════════════════════════════════════

class StrangerNationBadge extends StatelessWidget {

  const StrangerNationBadge({
    required this.displayData, super.key,
    this.myLanguageCode,
    this.theirLanguageCode,
  });
  /// Pass the raw display map from NationVisibilityService.applyPrivacy()
  final Map<String, String> displayData;
  final String? myLanguageCode;
  final String? theirLanguageCode;

  @override
  Widget build(BuildContext context) {
    final flag = displayData['flag'] ?? '🌍';
    final label = displayData['label'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        if (myLanguageCode != null && theirLanguageCode != null)
          _LanguageCompatRow(
            myCode: myLanguageCode!,
            theirCode: theirLanguageCode!,
          ),
      ],
    );
  }
}

class _LanguageCompatRow extends StatelessWidget {
  const _LanguageCompatRow({required this.myCode, required this.theirCode});
  final String myCode;
  final String theirCode;

  @override
  Widget build(BuildContext context) {
    final same = myCode == theirCode;

    // Find language name from any country with that language code
    String langName(String code) {
      final match = NationDatabase.all()
          .where((n) => n.languageCode == code)
          .firstOrNull;
      return match?.primaryLanguage ?? code.toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            same ? Icons.check_circle_rounded : Icons.translate_rounded,
            size: 12,
            color: same ? Colors.greenAccent : Colors.amberAccent,
          ),
          const SizedBox(width: 4),
          Text(
            same
                ? 'You both speak ${langName(myCode)}'
                : 'They speak ${langName(theirCode)}',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: same ? Colors.greenAccent : Colors.amberAccent,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VideoNationOverlay — semi-transparent pill badge on video feed
// ══════════════════════════════════════════════════════════════════════════════

class VideoNationOverlay extends StatefulWidget {

  const VideoNationOverlay({
    super.key,
    this.countryCode,
    this.isMe = false,
  });
  final String? countryCode;
  final bool isMe;

  @override
  State<VideoNationOverlay> createState() => _VideoNationOverlayState();
}

class _VideoNationOverlayState extends State<VideoNationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.value = 1.0;
    // Auto-hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), _hide);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _hide() {
    if (mounted) {
      _ctrl.reverse().then((_) {
      if (mounted) setState(() => _visible = false);
    });
    }
  }

  void _show() {
    setState(() => _visible = true);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 5), _hide);
  }

  @override
  Widget build(BuildContext context) {
    final nation = NationDatabase.fromCode(widget.countryCode);
    if (nation == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _show,
      behavior: HitTestBehavior.translucent,
      child: _visible
          ? FadeTransition(
              opacity: _opacity,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.15), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(nation.flag,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          widget.isMe
                              ? '${nation.countryName} (You)'
                              : nation.countryName,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TravelBannerWidget — shown 3 seconds on login when travelling
// ══════════════════════════════════════════════════════════════════════════════

class TravelBannerWidget extends StatefulWidget {
  const TravelBannerWidget({required this.travelNation, super.key});
  final NationData travelNation;

  @override
  State<TravelBannerWidget> createState() => _TravelBannerWidgetState();
}

class _TravelBannerWidgetState extends State<TravelBannerWidget> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade700,
                  Colors.deepOrange.shade800
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('✈️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Travelling in ${widget.travelNation.countryName}? ${widget.travelNation.flag} Your location has been updated.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white70, size: 18),
                  onPressed: () =>
                      setState(() => _visible = false),
                ),
              ],
            ),
          ).animate().slideY(begin: -1, duration: 400.ms, curve: Curves.easeOut),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Helpers
// ══════════════════════════════════════════════════════════════════════════════

Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
