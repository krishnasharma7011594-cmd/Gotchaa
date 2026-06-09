import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'connectivity_service.dart';

final offlineQueueProvider = Provider<OfflineQueueService>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  final queue = OfflineQueueService(connectivity);
  ref.onDispose(queue.dispose);
  return queue;
});

// ---------------------------------------------------------------------------
// Action Types
// ---------------------------------------------------------------------------

enum OfflineActionType { message, like, post }

class OfflineAction {
  OfflineAction({
    required this.type,
    required this.payload,
    required this.createdAt,
    String? id,
    this.retries = 0,
    this.nextRetryAt,
  }) : id = id ?? const Uuid().v4();

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
        id: json['id'] as String?,
        type: OfflineActionType.values.byName(json['type'] as String),
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        retries: json['retries'] as int? ?? 0,
        nextRetryAt: json['nextRetryAt'] != null
            ? DateTime.tryParse(json['nextRetryAt'] as String)
            : null,
      );

  final String id;
  final OfflineActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retries;

  /// Earliest UTC time at which this action may be retried.
  /// Null means "eligible immediately".
  DateTime? nextRetryAt;

  bool get isEligible {
    if (nextRetryAt == null) return true;
    return DateTime.now().isAfter(nextRetryAt!);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retries': retries,
        'nextRetryAt': nextRetryAt?.toIso8601String(),
      };

  /// Increment retries and compute next eligible time using exponential backoff.
  /// Backoff: 2^retries seconds, capped at 5 minutes.
  void recordFailure() {
    retries += 1;
    final backoffSeconds = min(pow(2, retries).toInt(), 300);
    nextRetryAt = DateTime.now().add(Duration(seconds: backoffSeconds));
  }
}

// ---------------------------------------------------------------------------
// Handler typedef — type-aware
// ---------------------------------------------------------------------------

typedef OfflineActionHandler = Future<void> Function(OfflineAction action);

// ---------------------------------------------------------------------------
// OfflineQueueService
// ---------------------------------------------------------------------------

/// Persists offline actions to Hive. When connectivity returns (or on app
/// restart if the device is already online) the queue is drained with
/// exponential-backoff retries. Actions are evicted after 5 failures.
class OfflineQueueService {
  OfflineQueueService(this._connectivity) {
    _init();
  }

  static const _boxName = 'offline_action_queue_v3';
  static const _maxRetries = 5;

  final ConnectivityService _connectivity;

  // Handlers keyed by action type so dispatch is O(1) and type-safe.
  final Map<OfflineActionType, List<OfflineActionHandler>> _handlers = {};

  Box<String>? _box;
  bool _isDraining = false;
  bool _initialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  StreamSubscription<bool>? _connectivitySub;

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  Future<void> _init() async {
    try {
      await Hive.initFlutter();
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box<String>(_boxName);
      } else {
        _box = await Hive.openBox<String>(_boxName);
      }
      _initialized = true;
      if (!_initCompleter.isCompleted) _initCompleter.complete();

      // Listen for connectivity changes.
      _connectivitySub = _connectivity.onlineStream.listen((online) {
        if (online) {
          unawaited(_drain());
        }
      });

      // Drain immediately if already online (handles app-restart recovery).
      if (_connectivity.isOnline) {
        unawaited(_drain());
      }
    } catch (e) {
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
    }
  }

  /// Waits until Hive is open. Callers use this to avoid race conditions
  /// between construction and the first enqueue call.
  Future<void> get ready => _initCompleter.future;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Register a handler for a specific action type.
  void registerHandler(OfflineActionType type, OfflineActionHandler handler) {
    _handlers.putIfAbsent(type, () => []).add(handler);
    if (_connectivity.isOnline) {
      unawaited(_drain());
    }
  }

  /// Persist an action. If online, attempt to drain immediately.
  Future<void> enqueue(OfflineAction action) async {
    if (!_initialized) {
      // Wait up to 5 s for Hive to open before giving up.
      await _initCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
    }

    final box = _box;
    if (box == null) return; // Storage unavailable — fail gracefully.

    final jsonStr = jsonEncode(action.toJson());
    await box.put(action.id, jsonStr);

    if (_connectivity.isOnline) {
      unawaited(_drain());
    }
  }

  /// Returns the number of pending actions in the queue.
  int get pendingCount => _box?.length ?? 0;

  // ---------------------------------------------------------------------------
  // Drain
  // ---------------------------------------------------------------------------

  Future<void> _drain() async {
    if (_isDraining) return;
    if (_box == null || !_connectivity.isOnline) return;

    _isDraining = true;
    try {
      final keys = List<dynamic>.from(_box!.keys);
      if (keys.isEmpty) return;

      for (final key in keys) {
        if (!_connectivity.isOnline) break;

        final raw = _box!.get(key as String);
        if (raw == null) continue;

        OfflineAction action;
        try {
          action = OfflineAction.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          );
        } catch (_) {
          // Corrupted entry — evict.
          await _box!.delete(key);
          continue;
        }

        // Evict permanently failed actions.
        if (action.retries >= _maxRetries) {
          await _box!.delete(key);
          continue;
        }

        // Respect backoff window.
        if (!action.isEligible) continue;

        final handlers = _handlers[action.type] ?? [];
        if (handlers.isEmpty) continue; // No handler registered yet — keep.

        bool success = false;
        for (final handler in handlers) {
          try {
            await handler(action);
            success = true;
          } catch (_) {
            // One handler failed; record failure and persist updated backoff.
            action.recordFailure();
            await _box!.put(key, jsonEncode(action.toJson()));
            success = false;
            break;
          }
        }

        if (success) {
          await _box!.delete(key);
        }
      }
    } finally {
      _isDraining = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  void dispose() {
    _connectivitySub?.cancel();
    _box?.close();
  }
}
