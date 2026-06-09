# GOTCHAA Content Moderation Architecture

This document outlines the multi-layered content moderation system implemented in the GOTCHAA app to ensure compliance with Google Play Store policies regarding User Generated Content (UGC).

## Overview

The moderation system is designed to be proactive, multi-layered, and future-ready. It combines fast client-side checks with server-side storage and prepares the app for advanced AI-based moderation.

---

## Layer 1: Client-Side Text Filtering (Dart)

Located in `lib/core/moderation/`.

### 1. Profanity Filter (`profanity_filter.dart`)
- **Purpose**: Masks profanity and detects violations in real-time.
- **Features**:
  - Baseline list of English profanity words.
  - Support for extending the word list dynamically via Firebase Remote Config (`blocked_words_list`).
  - Synchronous checks to avoid blocking the UI thread.

### 2. Content Validator (`content_validator.dart`)
- **Purpose**: Validates specific types of content before submission.
- **Features**:
  - `validateUsername`: Blocks profanity, special character abuse, and impersonation patterns (e.g., "admin").
  - `validateBio`: Checks user bios for length and profanity.
  - `validatePostText`: Checks posts for length and profanity.
  - `validateMessageText`: Lightweight check for real-time chat.

### 3. Spam Detector (`spam_detector.dart`)
- **Purpose**: Prevents spamming behavior.
- **Features**:
  - Detects repeated messages (same text sent 3+ times in 60 seconds).
  - Detects ALL-CAPS abuse (messages with >80% uppercase letters).
  - Detects link spam (excessive links in a message).

---

## Layer 2: Firestore Moderation Collections

Defined in `firestore_schema/moderation.md`.

- **`moderation_reports`**: Stores reports submitted by users.
- **`flagged_content`**: Stores content flagged automatically or manually.
- **`moderation_actions`**: Stores actions taken against users (warnings, mutes, bans).

---

## Layer 3: Report System

Located in `lib/features/reporting/`.

- **Report Bottom Sheet**: A user-friendly bottom sheet allowing users to report content or users across various categories (Spam, Hate Speech, Nudity, etc.).
- **Report Repository**: Handles submitting reports to Firestore and fetching report history.

---

## Layer 4: User Safety Tools

Located in `lib/features/safety/`.

- **Safety Service**: Provides methods for users to protect themselves.
  - `blockUser`: Prevents interaction and hides content from blocked users.
  - `muteUser`: Silences notifications and hides chat messages.
  - Methods write to `users/{userId}/blocked/` and `users/{userId}/muted/`.

---

## Layer 5: AI Moderation (Future-Ready)

Located in `lib/core/moderation/ai_moderation_service.dart`.

- **AI Moderation Service**: An abstract interface for AI checks.
- **Gemini Moderation Service**: A stub implementation that calls a Firebase Cloud Function (`moderateContent`).
- **Cloud Function Scaffold**: Located in `functions/src/moderation/moderateContent.ts`, ready for integration with Gemini or other AI APIs.

---

## Performance Considerations

- **Latency**: Client-side checks are synchronous and optimized with regex to run in under 10ms.
- **Background Processing**: Heavy checks or Remote Config fetches are done asynchronously or on app startup.
- **Fail-Open Policy**: If AI moderation fails or times out, the app defaults to approving content (fail-open) to ensure a smooth user experience, while logging the incident for review.
