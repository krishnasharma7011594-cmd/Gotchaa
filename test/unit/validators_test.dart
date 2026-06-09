import 'package:flutter_test/flutter_test.dart';
import 'package:gotchaa/core/security/validators.dart';

void main() {
  group('InputValidator Tests', () {
    group('Email Validation', () {
      // 10 Valid Emails
      final validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'a@b.c',
        'user+alias@gmail.com',
        '123@domain.com',
        'email@domain-one.com',
        '_______@domain.com',
        'email@domain.name',
        'email@domain.co.jp',
        'firstname.lastname@domain.com',
      ];

      for (final email in validEmails) {
        test('Valid email: $email', () {
          final result = InputValidator.validateEmail(email);
          expect(result.isValid, isTrue, reason: 'Failed for $email');
        });
      }

      // 10 Invalid Emails
      final invalidEmails = [
        null,
        '',
        '   ',
        'test', // No @
        '@example.com', // No local part
        'test@', // No domain
        'test@example..com', // Double dot
        'test@example', // No TLD (usually invalid in strict contexts)
        'test@ example.com', // Space in domain
        'a' * 245 + '@example.com', // Too long (> 254)
      ];

      for (final email in invalidEmails) {
        test('Invalid email: $email', () {
          final result = InputValidator.validateEmail(email);
          expect(result.isValid, isFalse, reason: 'Passed for $email');
        });
      }
    });

    group('Password Strength', () {
      // Note: Implementation requires 12 chars, upper, lower, number, special.
      // User requested: under 8 weak, 8+ medium, 12+ strong.
      // We test against the actual strict implementation.

      test('Strong password passes', () {
        final result = InputValidator.validatePassword('Abcdefghij1!');
        expect(result.isValid, isTrue);
      });

      test('Password under 12 characters fails (Weak)', () {
        final result = InputValidator.validatePassword('Short1!');
        expect(result.isValid, isFalse);
      });

      test('Password without uppercase fails', () {
        final result = InputValidator.validatePassword('abcdefghij1!');
        expect(result.isValid, isFalse);
      });

      test('Password without lowercase fails', () {
        final result = InputValidator.validatePassword('ABCDEFGHIJ1!');
        expect(result.isValid, isFalse);
      });

      test('Password without numbers fails', () {
        final result = InputValidator.validatePassword('Abcdefghijkl!');
        expect(result.isValid, isFalse);
      });

      test('Password without special characters fails', () {
        final result = InputValidator.validatePassword('Abcdefghij12');
        expect(result.isValid, isFalse);
      });

      test('Common password fails', () {
        final result = InputValidator.validatePassword('password123!');
        expect(result.isValid, isFalse);
      });

      test('Sequential characters fail', () {
        final result = InputValidator.validatePassword('abc123456789!');
        expect(result.isValid, isFalse);
      });

      test('Repeated characters fail', () {
        final result = InputValidator.validatePassword('aaaaBBBB1234!');
        expect(result.isValid, isFalse);
      });

      test('Very long password fails', () {
        final result = InputValidator.validatePassword('A' * 513 + '1!');
        expect(result.isValid, isFalse);
      });
    });

    group('Username Rules', () {
      // 5 Valid Usernames
      final validUsernames = [
        'user123',
        'valid_username',
        'abc',
        'john_doe',
        'user_1',
      ];

      for (final username in validUsernames) {
        test('Valid username: $username', () {
          expect(InputValidator.validateUsername(username).isValid, isTrue);
        });
      }

      // 5 Invalid Usernames
      final invalidUsernames = [
        null,
        '',
        'ab', // Too short (< 3)
        'a' * 33, // Too long (> 32)
        '_user', // Starts with underscore (violates regex in implementation)
        'user_', // Ends with underscore
        'user name', // Contains space
        'user@name', // Special char
      ];

      for (final username in invalidUsernames) {
        test('Invalid username: $username', () {
          expect(InputValidator.validateUsername(username).isValid, isFalse);
        });
      }
    });

    group('URL Validation', () {
      test('Valid HTTPS URL passes', () {
        expect(
            InputValidator.validateUrl('https://example.com').isValid, isTrue);
      });

      test('Valid HTTP URL fails by default', () {
        expect(
            InputValidator.validateUrl('http://example.com').isValid, isFalse);
      });

      test('Valid HTTP URL passes when allowed', () {
        expect(
            InputValidator.validateUrl('http://example.com', allowHttp: true)
                .isValid,
            isTrue);
      });

      test('Missing scheme fails', () {
        expect(InputValidator.validateUrl('example.com').isValid, isFalse);
      });

      test('Invalid format fails', () {
        expect(InputValidator.validateUrl('not a url').isValid, isFalse);
      });
    });

    group('XSS Injection Patterns', () {
      final xssInputs = [
        '<script>alert(1)</script>',
        'javascript:alert(1)',
        '<img src=x onerror=alert(1)>',
        '<iframe src="javascript:alert(1)">',
        'onmouseover=alert(1)',
      ];

      for (final input in xssInputs) {
        test('XSS detected: $input', () {
          final result = InputValidator.validateAgainstXss(input);
          expect(result.isValid, isFalse);
        });
      }

      test('Safe input passes XSS check', () {
        expect(
            InputValidator.validateAgainstXss('Hello World').isValid, isTrue);
      });
    });

    group('SQL Injection Patterns', () {
      final sqlInputs = [
        "admin' --",
        "' OR '1'='1",
        "UNION SELECT",
        "DROP TABLE users",
        "'; EXEC sp_executesql",
      ];

      for (final input in sqlInputs) {
        test('SQLi detected: $input', () {
          final result = InputValidator.validateAgainstSqlInjection(input);
          expect(result.isValid, isFalse);
        });
      }

      test('Safe input passes SQLi check', () {
        expect(
            InputValidator.validateAgainstSqlInjection('Hello World').isValid,
            isTrue);
      });
    });

    group('Sanitization', () {
      test('Sanitize HTML tags', () {
        final result = InputValidator.sanitizeHtml(
            '<script>alert(1)</script><b>Hello</b>');
        expect(result, equals('<b>Hello</b>'));
      });

      test('Sanitize event handlers', () {
        final result =
            InputValidator.sanitizeHtml('<div onclick="alert(1)">Hello</div>');
        expect(result, equals('<div>Hello</div>'));
      });
    });
  });
}
