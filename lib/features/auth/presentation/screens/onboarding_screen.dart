import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingItems = [
    OnboardingData(
      title: 'Connect Globally',
      description:
          'Experience next-gen chat with real-time on-device translation and connect with anyone, anywhere.',
      icon: Icons.chat_bubble_rounded,
      color: AppColors.electricBlue,
    ),
    OnboardingData(
      title: 'Create Your Vybz',
      description:
          'Share your moments in short video format. Express yourself with smart features and trending tags.',
      icon: Icons.play_circle_filled_rounded,
      color: AppColors.primaryGlow,
    ),
    OnboardingData(
      title: 'Mini App Universe',
      description:
          'Discover an ecosystem of mini-apps, games, and utilities right inside your social app.',
      icon: Icons.grid_view_rounded,
      color: Colors.purpleAccent,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.outfit(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemCount: _onboardingItems.length,
                  itemBuilder: (context, index) {
                    final item = _onboardingItems[index];
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              size: 100,
                              color: item.color,
                            ),
                          )
                              .animate(key: ValueKey(index))
                              .scale(duration: 600.ms, curve: Curves.elasticOut)
                              .fadeIn(),
                          const SizedBox(height: 50),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          )
                              .animate(key: ValueKey('title$index'))
                              .fadeIn(delay: 200.ms)
                              .slideY(begin: 0.2),
                          const SizedBox(height: 20),
                          Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          )
                              .animate(key: ValueKey('desc$index'))
                              .fadeIn(delay: 400.ms)
                              .slideY(begin: 0.1),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        _onboardingItems.length,
                        (index) => AnimatedContainer(
                          duration: 300.ms,
                          margin: const EdgeInsets.only(right: 8),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.electricBlue
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_currentPage < _onboardingItems.length - 1) {
                          _pageController.nextPage(
                              duration: 500.ms, curve: Curves.easeInOut);
                        } else {
                          _finishOnboarding();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

class OnboardingData {
  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}
