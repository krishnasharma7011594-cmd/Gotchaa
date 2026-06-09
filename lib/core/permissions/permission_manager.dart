import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permission_denied_dialog.dart';
import 'permission_rationale_dialog.dart';

class PermissionManager {
  static Future<bool> requestCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showSettingsDialog(
        context,
        'Camera Permission Required',
        'You have permanently denied camera access. Please enable it in settings to use this feature.',
      );
      return false;
    }

    final bool userAgreed = await _showRationale(
      context,
      title: 'Camera Access',
      description: 'GOTCHAA uses your camera for AR filters, Vybz content creation, and profile photos. Your camera is only active when you choose to use these features.',
      icon: Icons.camera_alt,
    );

    if (userAgreed) {
      status = await Permission.camera.request();
      return status.isGranted;
    }

    return false;
  }

  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showSettingsDialog(
        context,
        'Microphone Permission Required',
        'You have permanently denied microphone access. Please enable it in settings to use this feature.',
      );
      return false;
    }

    final bool userAgreed = await _showRationale(
      context,
      title: 'Microphone Access',
      description: 'GOTCHAA uses your microphone for voice messages, voice chat, and video calls. Audio is never recorded without your knowledge.',
      icon: Icons.mic,
    );

    if (userAgreed) {
      status = await Permission.microphone.request();
      return status.isGranted;
    }

    return false;
  }

  static Future<bool> requestLocationPermission(BuildContext context) async {
    var status = await Permission.location.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showSettingsDialog(
        context,
        'Location Permission Required',
        'You have permanently denied location access. Please enable approximate location in settings to use this feature.',
      );
      return false;
    }

    final bool userAgreed = await _showRationale(
      context,
      title: 'Location Access',
      description: 'GOTCHAA uses your approximate (coarse) location to help you connect with people nearby at a city level. We never track your precise GPS coordinates.',
      icon: Icons.location_on,
    );

    if (userAgreed) {
      status = await Permission.location.request();
      return status.isGranted;
    }

    return false;
  }

  static Future<bool> _showRationale(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) async {
    bool result = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PermissionRationaleDialog(
        title: title,
        description: description,
        icon: icon,
        onAllow: () {
          result = true;
          Navigator.pop(context);
        },
        onDeny: () {
          result = false;
          Navigator.pop(context);
        },
      ),
    );
    return result;
  }

  static void _showSettingsDialog(
    BuildContext context,
    String title,
    String description,
  ) {
    showDialog(
      context: context,
      builder: (context) => PermissionDeniedDialog(
        title: title,
        description: description,
      ),
    );
  }
}
