import 'package:flutter/material.dart';

class GeoDisclaimerBanner extends StatefulWidget {
  const GeoDisclaimerBanner({super.key});

  // Static variable to persist dismissal state across the session
  static bool _dismissed = false;

  @override
  State<GeoDisclaimerBanner> createState() => _GeoDisclaimerBannerState();
}

class _GeoDisclaimerBannerState extends State<GeoDisclaimerBanner> {
  @override
  Widget build(BuildContext context) {
    if (GeoDisclaimerBanner._dismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.black),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Some content is not available in your region due to local regulations.',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              setState(() {
                GeoDisclaimerBanner._dismissed = true;
              });
            },
          ),
        ],
      ),
    );
  }
}
