import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'profile_setup_screen.dart';

class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  State<InterestSelectionScreen> createState() =>
      _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  final List<String> _selectedInterests = [];

  final List<Map<String, dynamic>> _interests = [
    {'name': 'Tech', 'icon': Icons.bolt},
    {'name': 'Gaming', 'icon': Icons.sports_esports},
    {'name': 'Crypto', 'icon': Icons.currency_bitcoin},
    {'name': 'Music', 'icon': Icons.music_note},
    {'name': 'Relationships', 'icon': Icons.favorite},
    {'name': 'Fitness', 'icon': Icons.fitness_center},
    {'name': 'Memes', 'icon': Icons.emoji_emotions},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Finance', 'icon': Icons.account_balance_wallet},
    {'name': 'Travel', 'icon': Icons.flight},
    {'name': 'Fashion', 'icon': Icons.checkroom},
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Movies', 'icon': Icons.movie},
    {'name': 'Startups', 'icon': Icons.rocket_launch},
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      leading: const BackButton(color: Colors.black),
      elevation: 0,
      backgroundColor: Colors.white,
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personalize your Vybz',
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select at least 3 interests to help personalize your feed.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _interests.map((interest) {
                    final isSelected = _selectedInterests.contains(
                      interest['name'],
                    );
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedInterests.remove(interest['name']);
                          } else {
                            _selectedInterests.add(interest['name']);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              interest['icon'],
                              size: 18,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              interest['name'],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _selectedInterests.length < 3
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileSetupScreen(),
                        ),
                      );
                    },
              child: Text('Continue (${_selectedInterests.length}/3)'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
