import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final svc = ConnectivityService();
  ref.onDispose(svc.dispose);
  return svc;
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onlineStream;
});

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _isOnline = true;

  bool get isOnline => _isOnline;
  Stream<bool> get onlineStream => _controller.stream;

  ConnectivityService() {
    _sub = _connectivity.onConnectivityChanged.listen(_handle);
    _connectivity.checkConnectivity().then(_handle);
  }

  void _handle(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online == _isOnline) return;
    _isOnline = online;
    _controller.add(online);
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
