/// Comprehensive Security Implementation Guide for Gotchaa App
///
/// 🔒 SECURITY CRITICAL DOCUMENT
///
/// This guide outlines all security enhancements implemented and should be
/// followed by all developers working on the Gotchaa application.
///
/// Last Updated: February 24, 2026
/// Security Level: HIGH (Production Ready)

/*
================================================================================
                            TABLE OF CONTENTS
================================================================================

  1. ✅ Input Validation & Sanitization
  2. ✅ Rate Limiting & Brute Force Protection
  3. ✅ Secure API Key & Token Management
  4. ✅ Security Headers & API Hardening
  5. ✅ Error Handling & Information Disclosure Prevention
  6. ⚡ Backend Security (Recommended)
  7. 📋 Security Checklist for Code Review
  8. 🔐 Incident Response Procedures

================================================================================
                    1. INPUT VALIDATION & SANITIZATION
================================================================================

✅ IMPLEMENTED: validators.dart

All user inputs MUST be validated BEFORE processing.

### Usage Example:

```dart
import 'package:gotchaa/core/security/validators.dart';

// Validate email
final emailResult = InputValidator.validateEmail(userEmail);
if (!emailResult.isValid) {
  showError(emailResult.error); // Show user-friendly error
  return;
}
final validEmail = emailResult.sanitizedValue;

// Validate password
final passwordResult = InputValidator.validatePassword(userPassword);
if (!passwordResult.isValid) {
  showError(passwordResult.error);
  return;
}

// Validate text fields
final usernameResult = InputValidator.validateUsername(username);
if (!usernameResult.isValid) {
  showError(usernameResult.error);
  return;
}

// Validate request payload - prevents mass assignment attacks
final payloadResult = PayloadValidator.validatePayload(
  requestData,
  {
    'email': InputValidator.validateEmail,
    'username': InputValidator.validateUsername,
    'bio': (value) => InputValidator.validateText(value, maxLength: 500),
  },
);
if (!payloadResult.isValid) {
  throw ValidationException(message: payloadResult.error ?? 'Validation failed');
}
```

### Validation Rules:

⚠️ EMAIL:
  - RFC 5322 compliant format
  - Max 254 characters
  - Converted to lowercase (case-insensitive)

⚠️ PASSWORD:
  - Minimum 12 characters (NIST SP 800-63B compliant)
  - Uppercase + lowercase + number + special character
  - No common patterns (e.g., "password", "123456")
  - Max 512 characters

⚠️ USERNAME:
  - 3-32 characters
  - Alphanumeric + underscore only
  - Case-insensitive
  - Must start/end with letter or number

⚠️ PHONE NUMBER:
  - 10-15 digits (E.164 format)
  - Optional + prefix
  - Cleaned of formatting characters

⚠️ GENERIC TEXT:
  - No scripts, HTML tags, or dangerous patterns
  - Client-side XSS/SQL injection detection
  - Max length enforcement

### Security Notes:

⚠️ CLIENT-SIDE VALIDATION IS NOT ENOUGH
   - JavaScript/Dart validation can be bypassed
   - Backend MUST validate all inputs again
   - Never trust client validation

⚠️ SANITIZATION IS DEFENSIVE ONLY
   - Sanitizing HTML tags on client is not sufficient
   - Backend MUST use parameterized queries
   - Always escape output when rendering

================================================================================
                      2. RATE LIMITING & BRUTE FORCE
================================================================================

✅ IMPLEMENTED: rate_limiting.dart

Client-side rate limiting provides basic protection. Backend MUST enforce
server-side limits for actual security.

### Setup:

```dart
import 'package:gotchaa/core/security/rate_limiting.dart';

// Check rate limit before making request
final rateLimitService = RateLimitingService();
final checkResult = await rateLimitService.checkLimit(
  endpoint: '/auth/login',
  userId: currentUserId,
  clientIp: clientIp,
);

if (!checkResult.allowed) {
  final retryAfter = checkResult.retryAfter;
  showErrorSnackbar(
    'Too many requests. Please wait ${retryAfter.inSeconds} seconds.',
  );
  return;
}

// Make API request
final response = await apiClient.post('/auth/login', data: credentials);
```

### Default Limits:

⚠️ AUTHENTICATION ENDPOINTS (10 requests / 15 minutes):
  - POST /auth/login
  - POST /auth/register
  - POST /auth/forgot-password
  - POST /auth/reset-password

⚠️ SENSITIVE OPERATIONS (5 requests / 5 minutes):
  - POST /users/{id}/follow
  - POST /posts/{id}/like
  
⚠️ MESSAGING (30 requests / 1 minute):
  - POST /messages/send

⚠️ GENERAL API (100 requests / 15 minutes):
  - All other endpoints

### Backend Rate Limiting (CRITICAL):

The backend MUST implement strict rate limiting using:

```javascript
// Example NestJS implementation
import { ThrottlerModule } from '@nestjs/throttler';

@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 900, // 15 minutes
      limit: 100, // requests
      skipSuccessfulRequests: false,
      skipFailedRequests: false,
      storage: new RedisStore(), // Use Redis for distributed systems
      keyPrefix: 'gotcha_rate_limit',
      generateKey: (context) => {
        const request = context.switchToHttp().getRequest();
        // Use user ID if authenticated, otherwise use IP
        return (
          request.user?.id ||
          request.ip ||
          request.connection.remoteAddress
        );
      },
    }),
  ],
})
export class AppModule {}
```

### Custom Endpoint Limits:

```dart
// Register stricter limits for sensitive endpoints
final rateLimitService = RateLimitingService();
rateLimitService.registerEndpointLimit(
  '/admin/users/delete',
  maxRequests: 1,
  windowDuration: const Duration(hours: 1),
);
```

================================================================================
                  3. SECURE API KEY & TOKEN MANAGEMENT
================================================================================

✅ IMPLEMENTED: api_key_manager.dart

### ⚠️ NEVER DO THIS:

```dart
// ❌ NEVER hardcode API keys!
const String apiKey = 'sk_live_abc123xyz';

// ❌ NEVER store in SharedPreferences!
await prefs.setString('api_key', apiKey);

// ❌ NEVER commit to Git!
// (Check .gitignore includes sensitive files)

// ❌ NEVER log tokens!
print('Token: $token'); // 🚨 Security leak!
```

### ✅ DO THIS INSTEAD:

```dart
import 'package:gotchaa/core/security/api_key_manager.dart';

// Initialize on app startup
final apiKeyManager = ApiKeyManager();
await apiKeyManager.initialize();

// Get API key when needed
final apiKey = await apiKeyManager.getApiKey();
if (apiKey != null) {
  // Use API key
}

// Get API base URL (per environment)
final baseUrl = apiKeyManager.getApiBaseUrl();

// Get tokens
final bearerTokenManager = BearerTokenManager();
final accessToken = await bearerTokenManager.getAccessToken();
final refreshToken = await bearerTokenManager.getRefreshToken();

// Set tokens after login
await bearerTokenManager.setTokens(
  accessToken: response.data['access_token'],
  refreshToken: response.data['refresh_token'],
  expiresIn: Duration(seconds: response.data['expires_in']),
);

// Check if token needs refresh
if (bearerTokenManager.shouldRefreshToken()) {
  // Refresh token before it expires
}

// Clear tokens on logout
await bearerTokenManager.clearTokens();
```

### Key Storage:

PLATFORM-SPECIFIC SECURE STORAGE:
  - iOS: Keychain (encrypted)
  - Android: Keystore / EncryptedSharedPreferences (encrypted)
  - Web: Secure cookies only (httpOnly flag)

### Key Rotation:

RECOMMENDED SCHEDULE:
  - API Keys: Every 90 days
  - Access Tokens: Short-lived (15-60 minutes)
  - Refresh Tokens: Medium-lived (7-30 days)

IMPLEMENTATION:
```dart
// Rotate API key programmatically
await apiKeyManager.rotateApiKey(newKey);
```

### Environment Configuration:

```bash
# Development
BUILD_FLAVOR=development

# Staging
BUILD_FLAVOR=staging

# Production
BUILD_FLAVOR=production
```

================================================================================
                    4. SECURITY HEADERS & API HARDENING
================================================================================

✅ IMPLEMENTED: dio_security_interceptor.dart

### Automatic Headers Added:

```dart
// All requests automatically include:
'X-Frame-Options': 'DENY',                    // Prevent clickjacking
'X-Content-Type-Options': 'nosniff',          // Prevent MIME sniffing
'X-XSS-Protection': '1; mode=block',          // XSS protection
'Strict-Transport-Security': 'max-age=...',   // HTTPS enforcement
'Referrer-Policy': 'strict-origin-when-cross-origin',
'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
'Cache-Control': 'no-cache, no-store, must-revalidate',
'Content-Security-Policy': "default-src 'none'; script-src 'self'",
```

### Setup Dio with Interceptors:

```dart
import 'package:dio/dio.dart';
import 'package:gotchaa/core/security/dio_security_interceptor.dart';
import 'package:gotchaa/core/security/rate_limiting.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: 'https://api.gotchaa.app/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  ),
);

// Add security interceptors in order
dio.interceptors.addAll([
  // 1. Validate responses
  ResponseValidatorInterceptor(),
  
  // 2. Add security headers
  SecurityHeadersInterceptor(),
  
  // 3. Add authentication tokens
  BearerTokenInterceptor(dio),
  
  // 4. Enforce rate limiting
  RateLimitingInterceptor(
    RateLimitingService(),
    userId: authenticatedUserId,
    clientIp: clientIp,
  ),
  
  // 5. Log securely (never logs sensitive data)
  SecureLoggingInterceptor(enableLogging: kDebugMode),
]);
```

### HTTPS Enforcement:

⚠️ CRITICAL: All production traffic MUST use HTTPS

```dart
// ❌ Never use HTTP in production
const String apiBaseUrl = 'http://api.gotchaa.app'; // ❌ WRONG

// ✅ Always use HTTPS
const String apiBaseUrl = 'https://api.gotchaa.app'; // ✅ CORRECT

// Certificate pinning (recommended for production)
setupCertificatePinning();
```

================================================================================
                5. ERROR HANDLING & INFORMATION DISCLOSURE
================================================================================

✅ IMPLEMENTED: Enhanced exceptions and response validator

### Show Safe User Messages:

```dart
// ❌ NEVER expose internal errors
catch (e) {
  print(e); // ❌ Never print errors with internal details!
  showErrorDialog(e.toString()); // ❌ Don't show to users!
}

// ✅ Always use safe error messages
catch (e) {
  debugPrint('Error: ${e.toString()}'); // OK in debug only
  
  if (e is NetworkException) {
    showErrorDialog('Unable to connect. Please check your internet.');
  } else if (e is ValidationException) {
    showErrorDialog(e.message); // Validation messages are safe
  } else if (e is RateLimitException) {
    showErrorDialog(
      'Too many requests. Please wait before trying again.',
    );
  } else {
    // Generic error - never expose internal details
    showErrorDialog('Something went wrong. Please try again later.');
  }
}
```

### Logging Best Practices:

```dart
// ⚠️ NEVER log sensitive data
debugPrint('Token: \$token'); // ❌ WRONG
debugPrint('Password: \$password'); // ❌ WRONG
debugPrint('Full user: \${user.toString()}'); // ❌ Might expose secrets

// ✅ Always sanitize sensitive data
debugPrint('User ID: \${user.id}'); // ✅ OK
debugPrint('Email: \${user.email}'); // ✅ OK if needed
debugPrint('Action: User logged in'); // ✅ OK

// ✅ Use structured logging
logger.debug(
  'User authentication',
  extra: {'userId': user.id, 'timestamp': DateTime.now()},
); // Logs with sensitive data stripped

// ✅ Use custom serialization
class User {
  @override
  String toString() {
    return 'User(id: \$id, email: [REDACTED])'; // Redact passwords/tokens
  }
}
```

### Error Response Examples:

```dart
// ✅ GOOD Error Response (no info leakage):
{
  "error": "invalid_credentials",
  "message": "Invalid email or password"
}

// ❌ BAD Error Response (information leakage):
{
  "error": "invalid_credentials",
  "message": "No user with this email in our database",
  "stackTrace": "at UserRepository.findByEmail() ...",
  "database_query": "SELECT * FROM users WHERE email = ?",
}
```

================================================================================
                    6. BACKEND SECURITY (RECOMMENDED)
================================================================================

### NestJS Implementation Example:

```javascript
// ============================================================================
// 6.1 INPUT VALIDATION (NestJS)
// ============================================================================

import { IsEmail, IsStrongPassword, Min, Max } from 'class-validator';
import { BadRequestException, HttpException, HttpStatus } from '@nestjs/common';

// ✅ Strict DTO validation
export class LoginDto {
  @IsEmail()
  @Max(254)
  email: string;

  @IsStrongPassword({
    minLength: 12,
    minNumbers: 1,
    minSymbols: 1,
    minUppercase: 1,
    minLowercase: 1,
  })
  password: string;
}

// ⚠️ Validate on every endpoint
@Post('/auth/login')
async login(@Body() loginDto: LoginDto) {
  // Validation automatically happens via class-validator + ValidationPipe
  // Never process unvalidated input
}

// ============================================================================
// 6.2 RATE LIMITING (NestJS)
// ============================================================================

import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';

@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 900, // 15 minutes
      limit: 100,
      storage: new RedisStore(), // Distributed
    }),
  ],
})
export class AppModule {}

// Apply to specific endpoints
@UseGuards(ThrottlerGuard) 
@Post('/auth/login')
async login(@Body() dto: LoginDto) {}

// Custom rate limits per endpoint
@Throttle({ default: { limit: 10, ttl: 900 } })
@Post('/auth/login')
async login(@Body() dto: LoginDto) {}

// ============================================================================
// 6.3 SECURITY HEADERS (NestJS)
// ============================================================================

import helmet from 'helmet';

app.use(helmet()); // Automatically adds security headers

// Custom configuration
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'https:'],
      },
    },
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true,
    },
  }),
);

// ============================================================================
// 6.4 AUTHENTICATION & AUTHORIZATION (NestJS)
// ============================================================================

import { JwtModule } from '@nestjs/jwt';
import { AuthGuard } from '@nestjs/passport';

@Module({
  imports: [
    JwtModule.register({
      secret: process.env.JWT_SECRET,
      signOptions: { 
        expiresIn: '15m', // Short-lived access tokens
        algorithm: 'HS256',
      },
    }),
  ],
})
export class AuthModule {}

// Protect routes
@UseGuards(AuthGuard('jwt'))
@Get('/users/profile')
getProfile(@Request() req) {
  return req.user;
}

// ============================================================================
// 6.5 ERROR HANDLING (NestJS)
// ============================================================================

import { ExceptionFilter, Catch, ArgumentsHost, HttpException, HttpStatus } from '@nestjs/common';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    const request = ctx.getRequest();

    // Never expose internal error details in production
    const isDevelopment = process.env.NODE_ENV === 'development';
    
    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'An unexpected error occurred';
    let userMessage = 'Something went wrong. Please try again later.';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      userMessage = exception.getResponse()['message'] || message;
    }

    // Log full error (never sent to client)
    console.error('[Exception]', exception);

    response.status(status).json({
      statusCode: status,
      message: userMessage,
      timestamp: new Date().toISOString(),
      // Only in development:
      ...(isDevelopment && { 
        details: exception instanceof Error ? exception.message : undefined,
        path: request.url,
      }),
    });
  }
}

// ============================================================================
// 6.6 LOGGING (NestJS)
// ============================================================================

import { Logger } from '@nestjs/common';

export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  async login(email: string, password: string) {
    // ❌ NEVER log passwords or tokens
    // ✅ Always log safely
    this.logger.debug(\`Login attempt for email: \${email}\`);
    
    try {
      const user = await this.userService.findByEmail(email);
      if (!user || !await this.validatePassword(password, user.password)) {
        // ⚠️ Don't reveal if email exists!
        this.logger.warn(\`Failed login attempt for: \${email}\`);
        throw new UnauthorizedException('Invalid credentials');
      }

      const token = this.jwtService.sign({ userId: user.id });
      this.logger.debug(\`User \${user.id} logged in successfully\`);
      
      return { access_token: token };
    } catch (error) {
      this.logger.error(\`Login error: \${error.message}\`, error.stack);
      throw error;
    }
  }
}

// ============================================================================
// 6.7 INPUT SANITIZATION (NestJS)
// ============================================================================

import { plainToClass, plainToInstance } from 'class-transformer';
import DOMPurify from 'isomorphic-dompurify';

// Sanitize user input
export function sanitizeUserInput(data: any) {
  const sanitized = {};
  for (const [key, value] of Object.entries(data)) {
    if (typeof value === 'string') {
      // Remove HTML/script tags
      sanitized[key] = DOMPurify.sanitize(value);
    } else {
      sanitized[key] = value;
    }
  }
  return sanitized;
}

// Use in service
const sanitizedInput = sanitizeUserInput(req.body);

// ============================================================================
// 6.8 CSRF PROTECTION (NestJS)
// ============================================================================

import { CsrfMiddleware } from '@nestjs/csrf';

app.use(new CsrfMiddleware());

// Or with CORS properly configured
app.use(
  cors({
    origin: 'https://gotchaa.app',
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }),
);
```

================================================================================
                  7. SECURITY CHECKLIST FOR CODE REVIEW
================================================================================

### API Endpoints:

- [ ] All inputs validated and sanitized
- [ ] No hardcoded API keys or secrets
- [ ] Rate limiting enforced (both client and server)
- [ ] Error messages don't leak sensitive information
- [ ] Authentication tokens not logged
- [ ] HTTPS/TLS enforced
- [ ] CORS properly configured
- [ ] CSRF tokens implemented (for state-changing operations)
- [ ] SQL parameterized queries used
- [ ] Authentication & authorization checked
- [ ] NoSQL injection prevention implemented
- [ ] XSS prevention measures in place
- [ ] Security headers present

### Frontend Code:

- [ ] No hardcoded API keys, passwords, or tokens
- [ ] Sensitive data not stored in SharedPreferences  
- [ ] Using secure storage (Keychain/Keystore)
- [ ] Tokens cleared on logout
- [ ] Network requests use HTTPS only
- [ ] Input validation before API calls
- [ ] Error handling without exposing internals
- [ ] No sensitive data in logs
- [ ] Security headers configured (Dio interceptors)
- [ ] Certificate pinning implemented (if needed)

### Infrastructure:

- [ ] HTTPS/TLS enabled on all APIs
- [ ] Rate limiting configured
- [ ] API keys and secrets in environment variables
- [ ] Database credentials secured
- [ ] Regular key rotation schedule established
- [ ] Monitoring and alerting configured
- [ ] Access logs maintained
- [ ] Incident response plan documented

================================================================================
                    8. INCIDENT RESPONSE PROCEDURES
================================================================================

### If API Key is Exposed:

1. **IMMEDIATELY:**
   - Revoke the compromised key
   - Issue new API key
   - Update all applications

2. **WITHIN 1 HOUR:**
   - Review access logs for unauthorized usage
   - Check if any data was accessed
   - Document the incident

3. **WITHIN 24 HOURS:**
   - Notify affected users if data was compromised
   - Update incident documentation
   - Send postmortem to team

4. **ONGOING:**
   - Implement additional monitoring
   - Schedule more frequent key rotations
   - Review and improve key management process

### If Database is Breached:

1. **IMMEDIATELY:**
   - Take affected systems offline
   - Notify relevant parties
   - Begin forensic investigation

2. **WITHIN 4 HOURS:**
   - Determine scope of breach
   - Identify affected users/data
   - Change all credentials

3. **WITHIN 24 HOURS:**
   - Notify users of the breach per GDPR/regulations
   - Offer credit monitoring if needed
   - Begin remediation work

### If Token is Compromised:

1. **IMMEDIATELY:**
   - Revoke the token
   - Force user reauthentication
   - Monitor account for suspicious activity

2. **WITHIN 1 HOUR:**
   - Check if token was used to access other accounts
   - Review access logs
   - Notify user

3. **ONGOING:**
   - Shorten token expiration times
   - Implement token revocation service
   - Monitor for future compromises

================================================================================
                            SECURITY RESOURCES
================================================================================

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP Mobile Top 10: https://owasp.org/www-project-mobile-top-10/
- NIST Cybersecurity Framework: https://www.nist.gov/cyberframework
- OWASP Authentication Cheat Sheet:
  https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- Dart Security Best Practices: https://dart.dev/guides/security

================================================================================
*/
