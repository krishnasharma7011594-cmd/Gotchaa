/// String extension utilities.
///
/// Provides convenient methods for common string operations.
library;

/// Extensions on String class.
extension StringExtensions on String {
  /// Check if string is a valid email address.
  ///
  /// Uses a regex pattern that covers most common email formats.
  bool get isValidEmail {
    const emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    return RegExp(emailRegex).hasMatch(this);
  }

  /// Check if string is a valid phone number (basic validation).
  bool get isValidPhoneNumber {
    final cleaned = replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned.length >= 10 && cleaned.length <= 15;
  }

  /// Check if string is a valid URL.
  bool get isValidUrl {
    try {
      Uri.parse(this);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Check if string is empty or contains only whitespace.
  bool get isBlank => isEmpty || trim().isEmpty;

  /// Check if string is not empty and not blank.
  bool get isNotBlank => !isBlank;

  /// Capitalize the first letter of the string.
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Convert to title case (capitalize each word).
  String get toTitleCase => split(
    ' ',
  ).map((word) => word.isNotBlank ? word.capitalize : word).join(' ');

  /// Remove all whitespace from string.
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Truncate string to max length with ellipsis.
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return substring(0, maxLength - suffix.length) + suffix;
  }

  /// Check if string contains only alphabetic characters.
  bool get isAlphabetic => RegExp(r'^[a-zA-Z]+$').hasMatch(this);

  /// Check if string contains only numeric characters.
  bool get isNumeric => RegExp(r'^[0-9]+$').hasMatch(this);

  /// Check if string contains only alphanumeric characters.
  bool get isAlphanumeric => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);

  /// Check if string is a strong password.
  ///
  /// Rules: At least 8 characters, contains uppercase, lowercase, number, special char.
  bool get isStrongPassword {
    if (length < 8) return false;
    return RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]',
    ).hasMatch(this);
  }

  /// Mask important parts of string (e.g., for security).
  ///
  /// Example: maskString("1234567890", 2, 4) -> "12****7890"
  String maskString(int startVisible, int endVisible) {
    if (length <= startVisible + endVisible) return this;
    final start = substring(0, startVisible);
    final end = substring(length - endVisible);
    final masked = '*' * (length - startVisible - endVisible);
    return start + masked + end;
  }

  /// Convert string to hexadecimal representation.
  String toHex() =>
      codeUnits.map((u) => u.toRadixString(16).padLeft(2, '0')).join();

  /// Check if string starts with any of the given prefixes.
  bool startsWithAny(List<String> prefixes) =>
      prefixes.any(startsWith);

  /// Check if string ends with any of the given suffixes.
  bool endsWithAny(List<String> suffixes) =>
      suffixes.any(endsWith);

  /// Get the initials from a name string.
  ///
  /// Example: "John Doe" -> "JD"
  String get initials => split(' ')
      .where((word) => word.isNotBlank)
      .take(2)
      .map((word) => word[0].toUpperCase())
      .join();

  /// Reverse the string.
  String get reversed => split('').reversed.join('');

  /// Check if string is a palindrome.
  bool get isPalindrome => toLowerCase() == toLowerCase().reversed;

  /// Count occurrences of a substring.
  int countOccurrences(String pattern) {
    if (pattern.isEmpty) return 0;
    return RegExp(RegExp.escape(pattern)).allMatches(this).length;
  }

  /// Replace multiple patterns at once.
  String replaceMultiple(Map<String, String> replacements) {
    String result = this;
    replacements.forEach((pattern, replacement) {
      result = result.replaceAll(pattern, replacement);
    });
    return result;
  }

  /// Get similarity ratio between two strings (0.0 to 1.0).
  double similarityWith(String other) {
    final len = [length, other.length].reduce((a, b) => a > b ? a : b);
    if (len == 0) return 1;

    int differences = 0;
    for (int i = 0; i < len; i++) {
      if (i >= length || i >= other.length || this[i] != other[i]) {
        differences++;
      }
    }
    return 1.0 - (differences / len);
  }

  /// Convert to slug format for URLs.
  ///
  /// Example: "Hello World!" -> "hello-world"
  String toSlug() => toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp('-+'), '-');
}
