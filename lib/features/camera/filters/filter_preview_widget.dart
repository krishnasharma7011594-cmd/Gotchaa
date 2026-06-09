import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../create/presentation/widgets/ar_overlays_widget.dart';
import 'filter_manager.dart';

class FilterPreviewWidget extends StatefulWidget {
  const FilterPreviewWidget({super.key, this.controller});
  final CameraController? controller;

  @override
  State<FilterPreviewWidget> createState() => _FilterPreviewWidgetState();
}

class _FilterPreviewWidgetState extends State<FilterPreviewWidget> {
  late PageController _pageController;
  int _currentIndex = 0;
  final FilterManager _manager = FilterManager();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.22, initialPage: 0);
    _manager.addListener(_handleManagerUpdate);
  }

  void _handleManagerUpdate() {
    // If the category changes, reset the index to 0
    // We check if the current filters contain the selected filter, else reset.
    final filters = _manager.filteredFilters;
    if (_currentIndex >= filters.length) {
      if (mounted) {
        setState(() => _currentIndex = 0);
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _manager.removeListener(_handleManagerUpdate);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        final filters = _manager.filteredFilters;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category Tabs
            _buildCategoryTabs(),
            const SizedBox(height: 10),
            
            // Preview Carousel
            SizedBox(
              height: 100,
              child: PageView.builder(
                controller: _pageController,
                itemCount: filters.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  _manager.applyFilter(filters[index]);
                },
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = _currentIndex == index;
                  
                  return AnimatedScale(
                    scale: isSelected ? 1.2 : 0.85,
                    duration: const Duration(milliseconds: 200),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildThumbnail(filter, isSelected),
                          const SizedBox(height: 6),
                          Text(
                            filter.name,
                            style: GoogleFonts.outfit(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );

  Widget _buildThumbnail(FilterDefinition filter, bool isSelected) => Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.blueAccent : Colors.white24,
          width: isSelected ? 3 : 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
        ] : [],
      ),
      child: ClipOval(
        child: isSelected ? _buildLivePreview(filter) : _buildStaticPreview(filter),
      ),
    );

  Widget _buildStaticPreview(FilterDefinition filter) {
    // Mode A: Static Preview
    if (filter.previewAsset != null) {
        return Image.asset(
          filter.previewAsset!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(filter),
        );
    }
    return _buildFallback(filter);
  }

  Widget _buildLivePreview(FilterDefinition filter) {
    // Mode B: Live Preview (for selected filter only)
    if (widget.controller == null || !widget.controller!.value.isInitialized) {
      return _buildStaticPreview(filter);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Low-res Camera Preview
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 100, // Small size for performance
            child: CameraPreview(widget.controller!),
          ),
        ),
        // Apply Filter Overlay
        AROverlaysWidget(
          filter: filter,
          intensity: _manager.globalIntensity,
        ),
      ],
    );
  }

  Widget _buildFallback(FilterDefinition filter) => Container(
      color: Colors.grey[900],
      child: Center(
        child: Image.asset(filter.iconAsset, width: 30, height: 30),
      ),
    );

  Widget _buildCategoryTabs() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: FilterCategory.values.map((cat) {
          final isSelected = _manager.selectedCategory == cat;
          return GestureDetector(
            onTap: () {
              _manager.setCategory(cat);
              setState(() => _currentIndex = 0);
              _pageController.jumpToPage(0);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat.name.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
}
