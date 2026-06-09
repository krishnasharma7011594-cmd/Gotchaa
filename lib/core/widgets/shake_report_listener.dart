import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../features/safety/emergency_safety_service.dart';

/// Listens for device shake and triggers emergency report callback.
class ShakeReportListener extends StatefulWidget {
  const ShakeReportListener({
    required this.child, required this.enabled, super.key,
    this.onShake,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback? onShake;

  @override
  State<ShakeReportListener> createState() => _ShakeReportListenerState();
}

class _ShakeReportListenerState extends State<ShakeReportListener> {
  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  static const _threshold = 18.0;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _start();
  }

  @override
  void didUpdateWidget(ShakeReportListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      widget.enabled ? _start() : _stop();
    }
  }

  void _start() {
    _sub?.cancel();
    _sub = accelerometerEventStream().listen((e) {
      final magnitude = e.x * e.x + e.y * e.y + e.z * e.z;
      if (magnitude < _threshold * _threshold) return;
      final now = DateTime.now();
      if (now.difference(_lastShake).inMilliseconds < 1200) return;
      _lastShake = now;
      if (widget.onShake != null) {
        widget.onShake!();
      } else {
        EmergencySafetyService.instance.submitShakeReport(roomId: 'shake');
      }
    });
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
