import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../services/domain/models/service_model.dart';
import '../../../services/presentation/screens/web_browser_screen.dart';
import '../../../services/providers/services_provider.dart';
import '../../circles/screens/circles_feed_screen.dart';
import '../../vibetalk/screens/vibetalk_main_screen.dart';

class NativeMiniApp {

  const NativeMiniApp({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.screen,
    required this.color,
  });
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Widget screen;
  final Color color;
}

final nativeMiniApps = [
  const NativeMiniApp(id: 'vibetalk', name: 'VibeTalk', description: 'Global Video Matching', icon: Icons.video_camera_front_rounded, screen: VibeTalkMainScreen(), color: AppColors.electricBlue),
  const NativeMiniApp(id: 'circles', name: 'Circles', description: 'Social Discovery & Meetups', icon: Icons.groups_rounded, screen: CirclesFeedScreen(), color: AppColors.vibrantPurple),
];

class GotchaaMiniAppsScreen extends ConsumerStatefulWidget {
  const GotchaaMiniAppsScreen({super.key});

  @override
  ConsumerState<GotchaaMiniAppsScreen> createState() => _GotchaaMiniAppsScreenState();
}

class _GotchaaMiniAppsScreenState extends ConsumerState<GotchaaMiniAppsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openService(GotchaaService service) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => GotchaaWebBrowserScreen(service: service)),
    );
  }

  void _openNativeApp(NativeMiniApp app) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => app.screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final category = ref.watch(servicesSelectedCategoryProvider);

    final filteredNativeApps = nativeMiniApps.where((app) {
      if (_searchQuery.isEmpty) return true;
      return app.name.toLowerCase().contains(_searchQuery) || 
             app.description.toLowerCase().contains(_searchQuery);
    }).toList();

    final filteredServices = services.where((service) {
      final matchesCategory = category == ServiceCategory.all || service.category == category;
      final matchesQuery = _searchQuery.isEmpty || 
                           service.name.toLowerCase().contains(_searchQuery) || 
                           service.description.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        title: Text('Mini Apps', style: GoogleFonts.outfit(color: context.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search apps & services...',
                hintStyle: TextStyle(color: context.textSecondary),
                prefixIcon: Icon(Icons.search, color: context.textSecondary),
                filled: true,
                fillColor: context.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Apps & Services', style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: ServiceCategory.values.length,
                    itemBuilder: (context, index) {
                      final cat = ServiceCategory.values[index];
                      final isSelected = cat == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            cat.name.substring(0, 1).toUpperCase() + cat.name.substring(1),
                            style: GoogleFonts.outfit(
                              color: isSelected ? Colors.white : context.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(servicesSelectedCategoryProvider.notifier).state = cat;
                            }
                          },
                          backgroundColor: context.surface,
                          selectedColor: AppColors.electricBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: (category == ServiceCategory.all ? filteredNativeApps.length : 0) + filteredServices.length,
                  itemBuilder: (context, index) {
                    final showNative = category == ServiceCategory.all;
                    final isNative = showNative && index < filteredNativeApps.length;
                    
                    if (isNative) {
                      final app = filteredNativeApps[index];
                      return GestureDetector(
                        onTap: () => _openNativeApp(app),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: app.color.withOpacity(0.3), width: 2),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: app.color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(app.icon, color: app.color, size: 30),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                app.name,
                                style: GoogleFonts.outfit(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                app.description,
                                style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      final serviceIndex = showNative ? index - filteredNativeApps.length : index;
                      final service = filteredServices[serviceIndex];
                      return GestureDetector(
                        onTap: () => _openService(service),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: service.brandColor.withOpacity(0.3), width: 2),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: service.brandColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.public_rounded, color: service.brandColor, size: 30),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                service.name,
                                style: GoogleFonts.outfit(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                service.description,
                                style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
