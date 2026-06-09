import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'filter_manager.dart';

class FilterSelectorWidget extends StatefulWidget {
  const FilterSelectorWidget({super.key});

  @override
  State<FilterSelectorWidget> createState() => _FilterSelectorWidgetState();
}

class _FilterSelectorWidgetState extends State<FilterSelectorWidget> {
  final PageController _pageController = PageController(viewportFraction: 0.22);
  final FilterManager manager = FilterManager();
  
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        final filters = manager.filteredFilters;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: FilterCategory.values.map((cat) {
                  final isSelected = manager.selectedCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      manager.setCategory(cat);
                      setState(() => _currentIndex = 0);
                      _pageController.jumpToPage(0);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Colors.white : Colors.white24),
                      ),
                      child: Text(
                        _getCategoryName(cat),
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Intensity Slider
            if (manager.activeColorGrade != null || 
                manager.activeParticle != null || 
                manager.activeBackground != null || 
                manager.activeViral != null || 
                manager.activeFaceFilter != null)
              SizedBox(
                width: 200,
                child: Slider(
                  value: manager.globalIntensity,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                  onChanged: manager.setIntensity,
                ),
              ),
            
            // Filter Name Label
            if (filters.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  filters[_currentIndex].name,
                  style: GoogleFonts.outfit(
                    color: Colors.white, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    shadows: [const Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                ),
              ),

            // Carousel
            if (filters.isNotEmpty)
              SizedBox(
                height: 100,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: filters.length,
                  onPageChanged: (idx) {
                    setState(() => _currentIndex = idx);
                    manager.applyFilter(filters[idx]);
                  },
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    final isSelected = _currentIndex == index;
                    final double scale = isSelected ? 1.0 : 0.75;

                    return TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 250),
                      tween: Tween<double>(begin: scale, end: scale),
                      curve: Curves.easeOutBack,
                      builder: (context, val, child) => Transform.scale(
                          scale: val,
                          child: GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent, 
                                  width: 3
                                ),
                                boxShadow: [
                                  if (isSelected) 
                                    BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                                ]
                              ),
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Container(
                                    color: Colors.white.withOpacity(0.1),
                                    child: Image.asset(
                                      filter.iconAsset,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    );
                  },
                ),
              ),
          ],
        );
      }
    );

  String _getCategoryName(FilterCategory cat) {
    switch (cat) {
      case FilterCategory.colorGrade: return 'Colors';
      case FilterCategory.faceAR: return 'Face';
      case FilterCategory.particle: return 'Effects';
      case FilterCategory.background: return 'Scenes';
      case FilterCategory.motion: return 'Motion';
      case FilterCategory.viral: return 'Viral';
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
