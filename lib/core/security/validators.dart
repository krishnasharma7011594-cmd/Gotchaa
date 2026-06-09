/// Input validation and sanitization utilities.
///
/// ⚠️ SECURITY: All user inputs must be validated BEFORE processing.
/// This module provides strict schema-based validation with type checking,
/// length limits, format validation, and XSS/SQL Injection prevention.
library;

/// Input validation result.
class ValidationResult {
  /// Creates a validation result.
  ValidationResult({required this.isValid, this.error, this.sanitizedValue});

  /// Factory constructor for success.
  factory ValidationResult.success({dynamic sanitizedValue}) =>
      ValidationResult(isValid: true, sanitizedValue: sanitizedValue);

  /// Factory constructor for failure.
  factory ValidationResult.failure(String error) =>
      ValidationResult(isValid: false, error: error);

  /// Whether validation passed.
  final bool isValid;

  /// Error message if validation failed.
  final String? error;

  /// Sanitized value (if applicable).
  final dynamic sanitizedValue;
}

/// Core input validator class.
///
/// Provides strict validation for all user inputs.
class InputValidator {
  /// Validate email address.
  ///
  /// Rules:
  /// - Must match RFC 5322 email format (basic profile)
  /// - Max 254 characters (RFC 5321)
  /// - Must not be blank
  static ValidationResult validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Email is required');
    }

    if (value.length > 254) {
      return ValidationResult.failure('Email must be at most 254 characters');
    }

    const emailRegex = r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9]'
        r'(?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9]'
        r'(?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$';

    if (!RegExp(emailRegex).hasMatch(value)) {
      return ValidationResult.failure('Invalid email format');
    }

    return ValidationResult.success(sanitizedValue: value.toLowerCase().trim());
  }

  /// Validate password strength.
  ///
  /// Rules:
  /// - Minimum 12 characters (NIST SP 800-63B recommendation)
  /// - Must contain uppercase, lowercase, number, and special character
  /// - Must not exceed 512 characters
  /// - Must not contain common patterns
  static ValidationResult validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult.failure('Password is required');
    }

    if (value.length < 12) {
      return ValidationResult.failure(
        'Password must be at least 12 characters',
      );
    }

    if (value.length > 512) {
      return ValidationResult.failure('Password is too long');
    }

    if (!RegExp('[a-z]').hasMatch(value)) {
      return ValidationResult.failure(
        'Password must contain lowercase letters',
      );
    }

    if (!RegExp('[A-Z]').hasMatch(value)) {
      return ValidationResult.failure(
        'Password must contain uppercase letters',
      );
    }

    if (!RegExp(r'\d').hasMatch(value)) {
      return ValidationResult.failure('Password must contain numbers');
    }

    // Check for at least one special character
    const specials = r'!@#$%^&*()_+=-[]{}|;:,.<>?/';
    if (!value.split('').any((char) => specials.contains(char))) {
      return ValidationResult.failure(
        r'Password must contain special characters (@$!%*?&)',
      );
    }

    // Check for common weak patterns
    if (_hasCommonPasswordPatterns(value)) {
      return ValidationResult.failure('Password is too common');
    }

    return ValidationResult.success(sanitizedValue: value);
  }

  /// Validate username.
  ///
  /// Rules:
  /// - 3-32 alphanumeric characters plus underscore
  /// - Must start with letter or number
  /// - Case-insensitive uniqueness check (handled by backend)
  static ValidationResult validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Username is required');
    }

    final cleaned = value.toLowerCase().trim();

    if (cleaned.length < 3) {
      return ValidationResult.failure('Username must be at least 3 characters');
    }

    if (cleaned.length > 32) {
      return ValidationResult.failure('Username must be at most 32 characters');
    }

    if (!RegExp(r'^[a-z0-9][a-z0-9_]*[a-z0-9]$|^[a-z0-9]$').hasMatch(cleaned)) {
      return ValidationResult.failure(
        'Username can only contain letters, numbers, and underscores',
      );
    }

    return ValidationResult.success(sanitizedValue: cleaned);
  }

  /// Validate phone number.
  ///
  /// Rules:
  /// - 10-15 digits (E.164 format)
  /// - Optional + prefix
  /// - No letters or special characters except +
  static ValidationResult validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Phone number is required');
    }

    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.length < 10) {
      return ValidationResult.failure('Phone number too short');
    }

    if (cleaned.length > 15) {
      return ValidationResult.failure('Phone number too long');
    }

    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(cleaned)) {
      return ValidationResult.failure('Invalid phone number format');
    }

    return ValidationResult.success(sanitizedValue: cleaned);
  }

  /// Validate URL.
  ///
  /// Rules:
  /// - Must be valid URI
  /// - HTTP/HTTPS only for external URLs
  /// - Max 2048 characters
  static ValidationResult validateUrl(String? value, {bool allowHttp = false}) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('URL is required');
    }

    if (value.length > 2048) {
      return ValidationResult.failure('URL is too long');
    }

    try {
      final uri = Uri.parse(value);

      if (!uri.hasScheme) {
        return ValidationResult.failure('URL must include scheme (http/https)');
      }

      if (!allowHttp && uri.scheme != 'https') {
        return ValidationResult.failure('Only HTTPS URLs are allowed');
      }

      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return ValidationResult.failure('Only HTTP/HTTPS URLs are allowed');
      }

      return ValidationResult.success(sanitizedValue: value);
    } on FormatException {
      return ValidationResult.failure('Invalid URL format');
    }
  }

  /// Validate text field with length constraints.
  ///
  /// Rules:
  /// - No null/empty
  /// - Length between min and max
  /// - No multi-line by default
  static ValidationResult validateText(
    String? value, {
    int minLength = 1,
    int maxLength = 500,
    bool allowMultiline = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('This field is required');
    }

    if (value.length < minLength) {
      return ValidationResult.failure('Must be at least $minLength characters');
    }

    if (value.length > maxLength) {
      return ValidationResult.failure('Must be at most $maxLength characters');
    }

    if (!allowMultiline && value.contains('\n')) {
      return ValidationResult.failure('Multiline input is not allowed');
    }

    return ValidationResult.success(sanitizedValue: value.trim());
  }

  /// Validate integer value.
  static ValidationResult validateInteger(
    dynamic value, {
    int? minValue,
    int? maxValue,
  }) {
    int intValue;

    if (value is int) {
      intValue = value;
    } else if (value is String) {
      try {
        intValue = int.parse(value.trim());
      } on FormatException {
        return ValidationResult.failure('Must be a valid integer');
      }
    } else {
      return ValidationResult.failure('Invalid value type');
    }

    if (minValue != null && intValue < minValue) {
      return ValidationResult.failure('Value must be at least $minValue');
    }

    if (maxValue != null && intValue > maxValue) {
      return ValidationResult.failure('Value must be at most $maxValue');
    }

    return ValidationResult.success(sanitizedValue: intValue);
  }

  /// Validate double/decimal value.
  static ValidationResult validateDouble(
    dynamic value, {
    double? minValue,
    double? maxValue,
  }) {
    double doubleValue;

    if (value is double) {
      doubleValue = value;
    } else if (value is int) {
      doubleValue = value.toDouble();
    } else if (value is String) {
      try {
        doubleValue = double.parse(value.trim());
      } on FormatException {
        return ValidationResult.failure('Must be a valid number');
      }
    } else {
      return ValidationResult.failure('Invalid value type');
    }

    if (minValue != null && doubleValue < minValue) {
      return ValidationResult.failure('Value must be at least $minValue');
    }

    if (maxValue != null && doubleValue > maxValue) {
      return ValidationResult.failure('Value must be at most $maxValue');
    }

    return ValidationResult.success(sanitizedValue: doubleValue);
  }

  /// Validate that value is not null and is of expected type.
  static ValidationResult validateType<T>(
    dynamic value,
    Type expectedType, {
    String? fieldName,
  }) {
    if (value == null) {
      return ValidationResult.failure('${fieldName ?? "Field"} is required');
    }

    if (value.runtimeType != expectedType) {
      return ValidationResult.failure(
        '${fieldName ?? "Field"} must be of type $expectedType',
      );
    }

    return ValidationResult.success(sanitizedValue: value);
  }

  /// Validate that list contains only expected types.
  static ValidationResult validateListType<T>(
    List? value, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return ValidationResult.failure(
        '${fieldName ?? "Field"} cannot be empty',
      );
    }

    for (final item in value) {
      if (item is! T) {
        return ValidationResult.failure(
          '${fieldName ?? "Field"} contains invalid item type',
        );
      }
    }

    return ValidationResult.success(sanitizedValue: value);
  }

  /// Check for SQL injection patterns.
  ///
  /// ⚠️ NOTE: This is a basic client-side check.
  /// Server MUST use parameterized queries for full protection.
  static ValidationResult validateAgainstSqlInjection(String value) {
    final lowerValue = value.toLowerCase();

    // Check for common SQL patterns
    const sqlPatterns = [
      "'.*('|(--)|;)",
      '".*("|(--)|;)',
      r'\bunion\b',
      r'\binsert\b',
      r'\bupdate\b',
      r'\bdelete\b',
      r'\bdrop\b',
      '(--|;)',
    ];

    for (final pattern in sqlPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lowerValue)) {
        return ValidationResult.failure('Invalid input detected');
      }
    }

    return ValidationResult.success(sanitizedValue: value);
  }

  /// Check for XSS (Cross-Site Scripting) patterns.
  ///
  /// ⚠️ NOTE: This is basic client-side XSS prevention.
  /// Server MUST properly escape/sanitize all output.
  static ValidationResult validateAgainstXss(String value) {
    const xssPatterns = [
      r'<\s*script',
      r'javascript\s*:',
      r'on\w+\s*=',
      r'<\s*iframe',
      r'<\s*object',
      r'<\s*embed',
    ];

    for (final pattern in xssPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(value)) {
        return ValidationResult.failure('Invalid characters detected');
      }
    }

    return ValidationResult.success(sanitizedValue: value);
  }

  /// Sanitize HTML/script tags (basic removal).
  ///
  /// ⚠️ IMPORTANT: This is basic client-side sanitization.
  /// Never rely on this for security. Server MUST sanitize output.
  static String sanitizeHtml(String value) {
    // Remove script tags
    var result = value.replaceAll(
      RegExp(r'<\s*script[^>]*>.*?</\s*script\s*>', caseSensitive: false),
      '',
    );

    // Remove event handlers
    result = result.replaceAll(
      RegExp(r'''\s*on\w+\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]+)''',
          caseSensitive: false),
      '',
    );

    // Remove dangerous HTML tags
    result = result.replaceAll(
      RegExp(
        r'<\s*(iframe|object|embed|link|meta|style)[^>]*>',
        caseSensitive: false,
      ),
      '',
    );

    return result;
  }

  /// Common password blacklist check.
  static bool _hasCommonPasswordPatterns(String password) {
    final lowerPassword = password.toLowerCase();

    // Check for sequential characters
    if (RegExp(
      '(012|123|234|345|456|567|678|789|890|abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)',
    ).hasMatch(lowerPassword)) {
      return true;
    }

    // Check for repeated characters (more than 3 same chars in a row)
    if (RegExp(r'(.)\1{3,}').hasMatch(lowerPassword)) {
      return true;
    }

    // Common password patterns
    const commonPatterns = [
      'password',
      'qwerty',
      'admin',
      '123456',
      'gotchaa',
      'welcome',
      'letmein',
    ];

    for (final pattern in commonPatterns) {
      if (lowerPassword.contains(pattern)) {
        return true;
      }
    }

    return false;
  }
}

/// Request payload validator.
///
/// Validates entire request objects against schemas.
class PayloadValidator {
  /// Validate that no unexpected fields are present.
  ///
  /// ⚠️ SECURITY: Reject unexpected fields to prevent
  /// mass assignment attacks (e.g., setting admin flags).
  static ValidationResult validateNoExtraFields(
    Map<String, dynamic> payload,
    Set<String> allowedFields,
  ) {
    final extraFields =
        payload.keys.where((key) => !allowedFields.contains(key)).toList();

    if (extraFields.isNotEmpty) {
      return ValidationResult.failure(
        'Unexpected fields: ${extraFields.join(", ")}',
      );
    }

    return ValidationResult.success();
  }

  /// Validate required fields are present.
  static ValidationResult validateRequiredFields(
    Map<String, dynamic> payload,
    Set<String> requiredFields,
  ) {
    final missing = requiredFields
        .where(
          (field) =>
              payload[field] == null || payload[field].toString().isEmpty,
        )
        .toList();

    if (missing.isNotEmpty) {
      return ValidationResult.failure(
        'Missing required fields: ${missing.join(", ")}',
      );
    }

    return ValidationResult.success();
  }

  /// Validate all fields in payload.
  ///
  /// [validators] is a map of field names to validator functions.
  static ValidationResult validatePayload(
    Map<String, dynamic> payload,
    Map<String, ValidationResult Function(dynamic)> validators,
  ) {
    for (final entry in validators.entries) {
      final fieldName = entry.key;
      final validatorFn = entry.value;
      final value = payload[fieldName];

      final result = validatorFn(value);
      if (!result.isValid) {
        return ValidationResult.failure('$fieldName: ${result.error}');
      }
    }

    return ValidationResult.success();
  }
}
