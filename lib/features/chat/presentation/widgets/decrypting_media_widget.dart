import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/security/encrypted_media_service.dart';

class DecryptingMediaWidget extends StatefulWidget {
  const DecryptingMediaWidget({
    required this.remoteUrl,
    required this.fileKey,
    required this.nonce,
    required this.fileName,
    required this.builder,
    super.key,
  });
  final String remoteUrl;
  final String fileKey;
  final String nonce;
  final String fileName;
  final Widget Function(File file) builder;

  @override
  State<DecryptingMediaWidget> createState() => _DecryptingMediaWidgetState();
}

class _DecryptingMediaWidgetState extends State<DecryptingMediaWidget> {
  File? _decryptedFile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _decrypt();
  }

  Future<void> _decrypt() async {
    try {
      final service = EncryptedMediaService();
      final file = await service.downloadAndDecrypt(
        widget.remoteUrl,
        widget.fileKey,
        widget.nonce,
        widget.fileName,
      );
      if (mounted) {
        setState(() {
          _decryptedFile = file;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Decryption failed';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 12),
            Text(
              'Decrypting securely...',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ).animate().shimmer();
    }

    if (_error != null) {
      return Icon(Icons.error_outline, color: Colors.red.withOpacity(0.5));
    }

    return widget.builder(_decryptedFile!);
  }
}
