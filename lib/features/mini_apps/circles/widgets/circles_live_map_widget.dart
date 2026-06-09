import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/theme/app_colors.dart';
import '../models/circle_model.dart';
import '../services/circles_live_location_service.dart';
import 'glassmorphic_card.dart';

class CirclesLiveMapWidget extends StatefulWidget {

  const CirclesLiveMapWidget({
    required this.circleId, required this.circle, super.key,
  });
  final String circleId;
  final CircleModel circle;

  @override
  State<CirclesLiveMapWidget> createState() => _CirclesLiveMapWidgetState();
}

class _CirclesLiveMapWidgetState extends State<CirclesLiveMapWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 30, end: 70).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLatLng = widget.circle.locationLatLng != null;
    final centerLatLng = hasLatLng 
        ? ll.LatLng(widget.circle.locationLatLng!.latitude, widget.circle.locationLatLng!.longitude)
        : const ll.LatLng(28.6139, 77.2090); // Default to Delhi coords if none

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: CirclesLiveLocationService.instance.listenToLiveLocations(widget.circleId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final locations = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: GlassmorphicCard(
            borderRadius: 24,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE RADAR MAP • ${locations.length} SHARING',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // OpenStreetMap FlutterMap Box
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => FlutterMap(
                            options: MapOptions(
                              initialCenter: centerLatLng,
                              initialZoom: 16,
                              maxZoom: 18,
                              minZoom: 12,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.gotchaa.app',
                                tileBuilder: (context, tileWidget, tile) {
                                  // Apply dark theme matrix filter to match Gen Z dark styling beautifully
                                  return ColorFiltered(
                                    colorFilter: const ColorFilter.matrix([
                                      -0.9, 0, 0, 0, 255,
                                      0, -0.9, 0, 0, 255,
                                      0, 0, -0.9, 0, 255,
                                      0, 0, 0, 1, 0,
                                    ]),
                                    child: tileWidget,
                                  );
                                },
                              ),
                              
                              // Pulsing radius layer around the host's pinned meetup point
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: centerLatLng,
                                    radius: _pulseAnimation.value,
                                    useRadiusInMeter: true,
                                    color: AppColors.primaryGlow.withOpacity(0.15),
                                    borderColor: AppColors.primaryGlow.withOpacity(0.5),
                                    borderStrokeWidth: 2,
                                  ),
                                  CircleMarker(
                                    point: centerLatLng,
                                    radius: 10,
                                    useRadiusInMeter: true,
                                    color: AppColors.primaryGlow,
                                  ),
                                ],
                              ),

                              // Marker layer for all live sharing members
                              MarkerLayer(
                                markers: locations.map((loc) {
                                  final isOffline = loc['isOffline'] as bool;
                                  final mins = loc['minutesAgo'] as int;
                                  final double lat = loc['latitude'] as double;
                                  final double lng = loc['longitude'] as double;
                                  final locLatLng = ll.LatLng(lat, lng);

                                  return Marker(
                                    point: locLatLng,
                                    width: 60,
                                    height: 70,
                                    child: AnimatedOpacity(
                                      opacity: isOffline ? 0.35 : 1.0,
                                      duration: const Duration(milliseconds: 500),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isOffline ? Colors.grey : AppColors.primaryGlow,
                                                width: 2.2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primaryGlow.withOpacity(0.3),
                                                  blurRadius: 6,
                                                  spreadRadius: 2,
                                                )
                                              ]
                                            ),
                                            child: CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Colors.white10,
                                              backgroundImage: (loc['userAvatar'] as String).isNotEmpty
                                                  ? NetworkImage(loc['userAvatar'] as String)
                                                  : null,
                                              child: (loc['userAvatar'] as String).isEmpty
                                                  ? const Icon(Icons.person, size: 16, color: Colors.white)
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black87,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.white12, width: 0.5),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: Text(
                                              '${loc['userName']} ($mins m)',
                                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          )
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
