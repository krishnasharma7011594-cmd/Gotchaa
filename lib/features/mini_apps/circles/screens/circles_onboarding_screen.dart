import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/circles_onboarding_provider.dart';

class CirclesOnboardingScreen extends ConsumerStatefulWidget {
  const CirclesOnboardingScreen({super.key});

  @override
  ConsumerState<CirclesOnboardingScreen> createState() => _CirclesOnboardingScreenState();
}

class _CirclesOnboardingScreenState extends ConsumerState<CirclesOnboardingScreen> {
  final List<String> _availableHobbies = [
    'Parties', 'Pickleball', 'Gaming', 'Study Groups', 'Travelers',
    'Language Exchange', 'Music', 'Fitness', 'Startups', 'Anime',
    'Photography', 'Food Meetups'
  ];

  final List<String> _availableVibes = [
    'Casual', 'Networking', 'Gaming', 'Sports', 'Nightlife', 'Study'
  ];

  final List<String> _selectedHobbies = [];
  final List<String> _selectedVibes = [];
  String _selectedCity = 'New Delhi';

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Circles',
                    style: GoogleFonts.outfit(
                      color: AppColors.primaryGlow,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(circlesOnboardingProvider.notifier).skipOnboarding();
                    },
                    child: Text(
                      'Skip',
                      style: GoogleFonts.outfit(color: context.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Let\'s customize your local vibe stream',
                style: GoogleFonts.outfit(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // City
                      Text(
                        'Your Current City',
                        style: GoogleFonts.outfit(
                          color: context.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: context.surface,
                        initialValue: _selectedCity,
                        items: ['New Delhi', 'Mumbai', 'Bangalore', 'New York', 'London']
                            .map((city) => DropdownMenuItem(
                                  value: city,
                                  child: Text(city, style: TextStyle(color: context.textPrimary)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCity = val);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: context.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Hobbies
                      Text(
                        'Pick your main interests',
                        style: GoogleFonts.outfit(
                          color: context.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableHobbies.map((hobby) {
                          final isSelected = _selectedHobbies.contains(hobby);
                          return ChoiceChip(
                            label: Text(hobby),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedHobbies.add(hobby);
                                } else {
                                  _selectedHobbies.remove(hobby);
                                }
                              });
                            },
                            selectedColor: AppColors.electricBlue,
                            backgroundColor: context.surface,
                            labelStyle: GoogleFonts.outfit(
                              color: isSelected ? Colors.white : context.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide.none,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Vibes
                      Text(
                        'Preferred vibe / social environment',
                        style: GoogleFonts.outfit(
                          color: context.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableVibes.map((vibe) {
                          final isSelected = _selectedVibes.contains(vibe);
                          return ChoiceChip(
                            label: Text(vibe),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedVibes.add(vibe);
                                } else {
                                  _selectedVibes.remove(vibe);
                                }
                              });
                            },
                            selectedColor: AppColors.vibrantPurple,
                            backgroundColor: context.surface,
                            labelStyle: GoogleFonts.outfit(
                              color: isSelected ? Colors.white : context.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide.none,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(circlesOnboardingProvider.notifier).saveOnboarding(
                    hobbies: _selectedHobbies,
                    languages: ['English'],
                    vibePreferences: _selectedVibes,
                    preferredCities: [_selectedCity],
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Explore Circles Near Me',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
