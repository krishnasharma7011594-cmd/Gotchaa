import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/service_model.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.service,
    required this.onTap,
    super.key,
    this.isFavourite = false,
    this.onFavouriteToggle,
  });
  final GotchaaService service;
  final VoidCallback onTap;
  final bool isFavourite;
  final VoidCallback? onFavouriteToggle;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: service.brandColor.withOpacity(0.3), width: 2),
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: service.brandColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.public_rounded,
                        color: service.brandColor, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    service.name,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    style:
                        GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (onFavouriteToggle != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onFavouriteToggle,
                    child: Icon(
                      isFavourite ? Icons.favorite : Icons.favorite_border,
                      color: isFavourite ? Colors.red : Colors.white54,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}
