import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Prompts for a 6-digit authenticator code.
Future<String?> showTwoFactorCodeDialog(BuildContext context) async {
  final controller = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Text('Two-factor code',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold)),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 6,
        style: const TextStyle(
            color: Colors.white, fontSize: 22, letterSpacing: 8),
        decoration: const InputDecoration(
          hintText: '000000',
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Verify'),
        ),
      ],
    ),
  );
  controller.dispose();
  return code;
}
