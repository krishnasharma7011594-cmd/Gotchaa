import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/circles_feed_provider.dart';

class CirclesFilterDialog extends ConsumerStatefulWidget {
  const CirclesFilterDialog({super.key});

  @override
  ConsumerState<CirclesFilterDialog> createState() => _CirclesFilterDialogState();
}

class _CirclesFilterDialogState extends ConsumerState<CirclesFilterDialog> {
  final List<String> _categories = [
    'All', 'Parties', 'Pickleball', 'Gaming', 'Study Groups', 'Travelers',
    'Language Exchange', 'Music', 'Fitness', 'Startups', 'Anime', 'Photography'
  ];

  final List<String> _cities = ['All', 'New Delhi', 'Mumbai', 'Bangalore', 'New York', 'London'];

  String _selectedCat = 'All';
  String _selectedCity = 'All';

  @override
  void initState() {
    super.initState();
    final state = ref.read(circlesFeedProvider);
    _selectedCat = state.selectedCategory;
    _selectedCity = state.selectedCity ?? 'All';
  }

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
        color: context.bg.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Activities',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(circlesFeedProvider.notifier).resetFilters();
                  Navigator.of(context).pop();
                },
                child: const Text('Reset All', style: TextStyle(color: AppColors.error)),
              )
            ],
          ),
          const SizedBox(height: 16),
          
          // Category Select
          Text(
            'Category',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCat == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCat = cat);
                    },
                    selectedColor: AppColors.electricBlue,
                    backgroundColor: context.surface,
                    labelStyle: GoogleFonts.outfit(color: Colors.white),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide.none),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // City select
          Text(
            'Target City',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _cities.length,
              itemBuilder: (context, index) {
                final city = _cities[index];
                final isSelected = _selectedCity == city;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(city),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCity = city);
                    },
                    selectedColor: AppColors.vibrantPurple,
                    backgroundColor: context.surface,
                    labelStyle: GoogleFonts.outfit(color: Colors.white),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide.none),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              ref.read(circlesFeedProvider.notifier).updateFilters(
                category: _selectedCat,
                city: _selectedCity == 'All' ? null : _selectedCity,
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              'Apply Filters',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
}
