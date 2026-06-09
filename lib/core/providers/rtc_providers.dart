import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../security/e2ee_service.dart';
import '../services/rtc_service.dart';

final rtcServiceProvider = ChangeNotifierProvider<RTCService>((ref) {
  final e2ee = ref.watch(e2eeServiceProvider);
  final service = RTCService(e2ee);

  // Cleanup on provider dispose
  ref.onDispose(service.dispose);

  return service;
});
