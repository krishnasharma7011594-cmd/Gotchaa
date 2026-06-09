import 'auto_moderation_service.dart';
import 'profanity_filter.dart';

enum ValidationSeverity { low, medium, high }

class ValidationResult {
  ValidationResult({
    required this.isValid,
    this.reason,
    this.severity,
    this.warningOnly = false,
    this.maskedText,
  });

  factory ValidationResult.valid({String? maskedText}) =>
      ValidationResult(isValid: true, maskedText: maskedText);

  factory ValidationResult.invalid(String reason, ValidationSeverity severity,
          {bool warningOnly = false}) =>
      ValidationResult(
        isValid: warningOnly,
        reason: reason,
        severity: severity,
        warningOnly: warningOnly,
      );

  final bool isValid;
  final String? reason;
  final ValidationSeverity? severity;
  final bool warningOnly;
  final String? maskedText;
}

class ContentValidator {
  final _auto = AutoModerationService.instance;

  ValidationResult validateUsername(String name) {
    if (name.isEmpty) {
      return ValidationResult.invalid(
          'Username cannot be empty', ValidationSeverity.low);
    }
    if (name.length < 3 || name.length > 30) {
      return ValidationResult.invalid(
          'Username must be between 3 and 30 characters',
          ValidationSeverity.low);
    }
    final scan = _auto.scanText(
      text: name,
      context: FilterContext.username,
      userId: 'username_check',
      contentKey: name,
    );
    if (scan.isBlocked) {
      return ValidationResult.invalid(
          scan.reason ?? 'Inappropriate username', ValidationSeverity.high);
    }
    final validChars = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!validChars.hasMatch(name)) {
      return ValidationResult.invalid(
          'Username can only contain letters, numbers, dots, and underscores',
          ValidationSeverity.medium);
    }
    return ValidationResult.valid(maskedText: scan.maskedText);
  }

  ValidationResult validateBio(String bio) {
    if (bio.length > 150) {
      return ValidationResult.invalid(
          'Bio cannot exceed 150 characters', ValidationSeverity.low);
    }
    return _fromScan(_auto.scanText(
      text: bio,
      context: FilterContext.bio,
      userId: 'bio',
      contentKey: bio,
    ));
  }

  ValidationResult validatePostText(String text, {required String userId}) {
    if (text.isEmpty) {
      return ValidationResult.invalid(
          'Post content cannot be empty', ValidationSeverity.low);
    }
    if (text.length > 500) {
      return ValidationResult.invalid(
          'Post content cannot exceed 500 characters', ValidationSeverity.low);
    }
    return _fromScan(_auto.scanText(
      text: text,
      context: FilterContext.post,
      userId: userId,
      contentKey: text,
      isPublicFeed: true,
    ));
  }

  ValidationResult validateMessageText(String text, {required String userId}) {
    if (text.isEmpty) {
      return ValidationResult.invalid(
          'Message cannot be empty', ValidationSeverity.low);
    }
    if (text.length > 1000) {
      return ValidationResult.invalid(
          'Message cannot exceed 1000 characters', ValidationSeverity.low);
    }
    return _fromScan(_auto.scanText(
      text: text,
      context: FilterContext.message,
      userId: userId,
      contentKey: text,
    ));
  }

  ValidationResult _fromScan(ModerationScanResult scan) {
    if (scan.isBlocked) {
      return ValidationResult.invalid(
        scan.reason ?? 'Content violates community guidelines',
        ValidationSeverity.high,
      );
    }
    if (scan.action == ModerationActionType.allowWithWarning) {
      return ValidationResult.invalid(
        scan.reason ?? 'Please review your content',
        ValidationSeverity.medium,
        warningOnly: true,
      );
    }
    return ValidationResult.valid(maskedText: scan.maskedText);
  }
}
