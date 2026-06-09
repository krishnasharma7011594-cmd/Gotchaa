import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class VoiceFilterSheet extends StatefulWidget {
  const VoiceFilterSheet({super.key});

  @override
  State<VoiceFilterSheet> createState() => _VoiceFilterSheetState();
}

class _VoiceFilterSheetState extends State<VoiceFilterSheet> {
  String selectedFilter = 'Natural';
  final List<Map<String, dynamic>> filters = [
    {'name': 'Natural', 'icon': Icons.mic_none_rounded},
    {'name': 'Deep', 'icon': Icons.graphic_eq_rounded},
    {'name': 'Robot', 'icon': Icons.smart_toy_rounded},
    {'name': 'Love', 'icon': Icons.favorite_rounded},
    {'name': 'Whisper', 'icon': Icons.air_rounded},
    {'name': 'Hero', 'icon': Icons.bolt_rounded},
  ];

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Voice Filter Studio',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suggested: "Deep" for your tone',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.electricBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 30),
          
          // Waveform Placeholder
          SizedBox(
            height: 80,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(30, (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 4,
                  height: (index % 5 == 0 ? 40.0 : index % 3 == 0 ? 20.0 : 30.0),
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .scaleY(begin: 0.5, end: 1.5, duration: (500 + (index * 20)).ms)),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Filter Selector
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = selectedFilter == filter['name'];
                return GestureDetector(
                  onTap: () => setState(() => selectedFilter = filter['name']),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 15),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: 300.ms,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.electricBlue : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            boxShadow: isSelected ? [
                              BoxShadow(color: AppColors.electricBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                            ] : null,
                          ),
                          child: Icon(filter['icon'], color: isSelected ? Colors.white : Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          filter['name'],
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.electricBlue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Apply and Send',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
}
