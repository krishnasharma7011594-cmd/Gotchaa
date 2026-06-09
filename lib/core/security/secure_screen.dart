import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// FLAG_SECURE on Android; secure channel on iOS (screenshot notification).
class SecureScreen extends StatefulWidget {
  const SecureScreen({required this.child, super.key, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  static const _channel = MethodChannel('com.gotchaa.app/security');

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _setSecure(true);
  }

  @override
  void didUpdateWidget(SecureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) _setSecure(widget.enabled);
  }

  @override
  void dispose() {
    if (widget.enabled) _setSecure(false);
    super.dispose();
  }

  Future<void> _setSecure(bool on) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('setSecureMode', on);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
