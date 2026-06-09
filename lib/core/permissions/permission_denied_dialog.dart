import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionDeniedDialog extends StatelessWidget {

  const PermissionDeniedDialog({
    required this.title, required this.description, super.key,
  });
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => AlertDialog(
      backgroundColor: const Color(0xFF0D0D1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Text(
        description,
        style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            openAppSettings();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Open Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
}
