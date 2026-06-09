/// Performance monitoring and diagnostic utilities.
///
/// Provides tools for measuring performance, tracking metrics, and optimizing
/// app performance.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../logging/app_logger.dart';

/// Performance tracker for measuring operation durations.
class PerformanceTracker {
  /// Creates a [PerformanceTracker].
  PerformanceTracker({this.tag = 'Performance'});

  /// Tag for this tracker instance.
  final String tag;

  final _measurements = <String, List<Duration>>{};
  final _activeTimers = <String, Stopwatch>{};

  /// Start measuring a named operation.
  void startMeasure(String operationName) {
    _activeTimers[operationName] = Stopwatch()..start();
    AppLogger.d('[$tag] Started measuring: $operationName');
  }

  /// Stop measuring and record the duration.
  Duration? stopMeasure(String operationName) {
    final stopwatch = _activeTimers.remove(operationName);
    if (stopwatch == null) {
      AppLogger.w('[$tag] No active measurement for: $operationName');
      return null;
    }

    stopwatch.stop();
    final duration = stopwatch.elapsed;

    _measurements.putIfAbsent(operationName, () => []).add(duration);

    AppLogger.d(
      '[$tag] Completed measure: $operationName (${duration.inMilliseconds}ms)',
    );

    return duration;
  }

  /// Measure a synchronous operation.
  T measure<T>(String operationName, T Function() operation) {
    startMeasure(operationName);
    try {
      return operation();
    } finally {
      stopMeasure(operationName);
    }
  }

  /// Measure an asynchronous operation.
  Future<T> measureAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startMeasure(operationName);
    try {
      return await operation();
    } finally {
      stopMeasure(operationName);
    }
  }

  /// Get statistics for a measured operation.
  MeasurementStats? getStats(String operationName) {
    final measurements = _measurements[operationName];
    if (measurements == null || measurements.isEmpty) {
      return null;
    }

    return MeasurementStats.fromDurations(measurements);
  }

  /// Get all available measurement names.
  List<String> get measurementNames => _measurements.keys.toList();

  /// Clear all measurements.
  void clear() {
    _measurements.clear();
    _activeTimers.clear();
  }

  /// Get a summary of all measurements.
  String getSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== Performance Summary [$tag] ===');

    for (final operation in measurementNames) {
      final stats = getStats(operation);
      if (stats != null) {
        buffer.writeln('$operation:');
        buffer.writeln('  Count: ${stats.count}');
        buffer.writeln('  Min: ${stats.min.inMilliseconds}ms');
        buffer.writeln('  Max: ${stats.max.inMilliseconds}ms');
        buffer.writeln('  Avg: ${stats.average.inMilliseconds}ms');
        buffer.writeln('  Total: ${stats.total.inMilliseconds}ms');
      }
    }

    return buffer.toString();
  }

  /// Print performance summary to logs.
  void printSummary() {
    AppLogger.i(getSummary());
  }
}

/// Statistics for a series of measurements.
class MeasurementStats {
  /// Creates [MeasurementStats] from a list of durations.
  MeasurementStats.fromDurations(List<Duration> durations)
      : count = durations.length,
        min = durations.reduce((a, b) => a < b ? a : b),
        max = durations.reduce((a, b) => a > b ? a : b),
        total = durations.fold<Duration>(
          Duration.zero,
          (prev, curr) => prev + curr,
        ) {
    average = Duration(microseconds: total.inMicroseconds ~/ count);
  }

  /// Number of measurements.
  final int count;

  /// Minimum duration.
  final Duration min;

  /// Maximum duration.
  final Duration max;

  /// Total duration of all measurements.
  final Duration total;

  /// Average duration across all measurements.
  late final Duration average;

  @override
  String toString() => 'Stats(count=$count, min=${min.inMilliseconds}ms, '
      'max=${max.inMilliseconds}ms, avg=${average.inMilliseconds}ms)';
}

/// Memory usage analyzer.
class MemoryAnalyzer {
  /// Estimate memory usage of a list.
  static int estimateListMemory<T>(List<T> list) {
    // This is a rough estimation
    const listOverhead = 56; // Base overhead per list
    const itemOverhead = 16; // Approximate overhead per item
    return listOverhead + (list.length * itemOverhead);
  }

  /// Estimate memory usage of a map.
  static int estimateMapMemory<K, V>(Map<K, V> map) {
    const mapOverhead = 56;
    const entryOverhead = 24;
    return mapOverhead + (map.length * entryOverhead);
  }

  /// Format bytes for human-readable display.
  static String formatMemory(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Debouncer for rate-limiting function calls.
class Debouncer {
  /// Creates a [Debouncer] with the given duration.
  Debouncer({required this.duration});

  /// Debounce duration.
  final Duration duration;

  Timer? _timer;

  /// Execute the function after the debounce duration.
  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancel any pending debounced call.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose the debouncer.
  void dispose() {
    cancel();
  }
}

/// Throttler for rate-limiting function calls with a minimum interval.
class Throttler {
  /// Creates a [Throttler] with the given minimum interval.
  Throttler({required this.minInterval});

  /// Minimum interval between executions.
  final Duration minInterval;

  DateTime? _lastExecutionTime;

  /// Execute the function if enough time has passed since last execution.
  void call(VoidCallback action) {
    final now = DateTime.now();
    final lastTime = _lastExecutionTime;

    if (lastTime == null ||
        now.difference(lastTime).inMilliseconds >= minInterval.inMilliseconds) {
      _lastExecutionTime = now;
      action();
    }
  }

  /// Reset the throttler.
  void reset() {
    _lastExecutionTime = null;
  }
}

/// Cache with automatic expiration.
class ExpiringCache<K, V> {
  /// Creates an [ExpiringCache] with the given TTL.
  ExpiringCache({required this.ttl});

  /// Time-to-live for cached values.
  final Duration ttl;

  final _cache = <K, CachedValue<V>>{};

  /// Get a cached value if it hasn't expired.
  V? get(K key) {
    final cached = _cache[key];
    if (cached == null) return null;

    if (DateTime.now().difference(cached.createdAt) > ttl) {
      _cache.remove(key);
      return null;
    }

    return cached.value;
  }

  /// Set a cached value.
  void set(K key, V value) {
    _cache[key] = CachedValue(value, DateTime.now());
  }

  /// Remove a cached value.
  void remove(K key) {
    _cache.remove(key);
  }

  /// Clear all cached values.
  void clear() {
    _cache.clear();
  }

  /// Get the number of non-expired cached values.
  int get size {
    _removeExpired();
    return _cache.length;
  }

  /// Remove all expired values.
  void _removeExpired() {
    final now = DateTime.now();
    _cache.removeWhere((_, cached) => now.difference(cached.createdAt) > ttl);
  }
}

/// A cached value with creation timestamp.
class CachedValue<V> {
  /// Creates a [CachedValue].
  CachedValue(this.value, this.createdAt);

  /// The cached value.
  final V value;

  /// When this value was created.
  final DateTime createdAt;
}

/// Global performance tracker instance.
final performanceTracker = PerformanceTracker();
