/// Numeric extension utilities.
///
/// Provides convenient methods for common numeric operations.
library;

/// Extensions on num and int classes.
extension NumExtensions on num {
  /// Convert bytes to human-readable format.
  ///
  /// Example: 1024 -> "1.0 KB", 1048576 -> "1.0 MB"
  String get formatBytes {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var bytes = toDouble();
    var unitIndex = 0;

    while (bytes >= 1024 && unitIndex < units.length - 1) {
      bytes /= 1024;
      unitIndex++;
    }

    return '${bytes.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Format as currency with given symbol.
  String formatCurrency({String symbol = r'$', int decimals = 2}) =>
      '$symbol${toStringAsFixed(decimals)}';

  /// Format as percentage.
  String formatPercent({int decimals = 1}) =>
      '${(this * 100).toStringAsFixed(decimals)}%';

  /// Check if number is between two values (inclusive).
  bool isBetween(num min, num max) => this >= min && this <= max;

  /// Clamp the number between min and max.
  num clamp(num min, num max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// Get the absolute value.
  num get abs => this.abs();

  /// Check if number is even (for integers).
  bool get isEven => (this as int).isEven;

  /// Check if number is odd (for integers).
  bool get isOdd => (this as int).isOdd;

  /// Check if number is positive.
  bool get isPositive => this > 0;

  /// Check if number is negative.
  bool get isNegative => this < 0;

  /// Check if number is zero.
  bool get isZero => this == 0;

  /// Check if number is a whole number.
  bool get isWhole => toDouble() == toInt().toDouble();
}

/// Extensions on double class.
extension DoubleExtensions on double {
  /// Round to a specific number of decimal places.
  double roundToPrecision(int decimals) {
    final factor = pow(10.0, decimals).toInt();
    return (this * factor).round() / factor;
  }

  /// Check if this double is approximately equal to another.
  bool approximatelyEquals(double other, {double tolerance = 0.01}) =>
      (this - other).abs() <= tolerance;

  /// Get the square root.
  double get sqrt => power(0.5);

  /// Get the power of this number.
  double power(num exponent) => pow(this, exponent).toDouble();

  /// How many times this number goes into another evenly.
  int divideEvenly(num other) => (this / other).floor();
}

/// Extensions on int class.
extension IntExtensions on int {
  /// Repeat a function this many times.
  void times(Function(int) callback) {
    for (int i = 0; i < this; i++) {
      callback(i);
    }
  }

  /// Get the factorial.
  int get factorial {
    if (this < 0) return 1;
    if (this == 0 || this == 1) return 1;
    int result = 1;
    for (int i = 2; i <= this; i++) {
      result *= i;
    }
    return result;
  }

  /// Check if this number is prime.
  bool get isPrime {
    if (this < 2) return false;
    if (this == 2) return true;
    if (this % 2 == 0) return false;
    for (int i = 3; i * i <= this; i += 2) {
      if (this % i == 0) return false;
    }
    return true;
  }

  /// Get the next prime number after this one.
  int get nextPrime {
    int candidate = this + 1;
    while (!candidate.isPrime) {
      candidate++;
    }
    return candidate;
  }

  /// Get digits of this number as a list.
  List<int> get digits => toString().split('').map(int.parse).toList();

  /// Get the sum of digits.
  int get digitSum => digits.reduce((a, b) => a + b);
}

/// Extension for power function.
double pow(num base, num exponent) => base.toDouble() ^ exponent.toInt();

/// Fix bitwise XOR operator if needed.
extension BitXor on double {
  double operator ^(int exponent) => pow(this, exponent).toDouble();
}
