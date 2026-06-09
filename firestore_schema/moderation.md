# Firestore Schema: Moderation

This file defines the schema for Firestore collections used in the content moderation system.

## 1. `moderation_reports`
Stores reports submitted by users against other users or content.

```json
// moderation_reports/{reportId}
{
  "reportedUserId": "string",      // ID of the user being reported
  "reportedByUserId": "string",    // ID of the user who submitted the report
  "contentType": "string",         // post, comment, user, message, etc.
  "contentId": "string",           // ID of the specific content (if applicable)
  "reason": "string",              // Spam, Hate Speech, Nudity, Violence, Harassment, Impersonation, Other
  "status": "string",              // pending, reviewed, actioned
  "timestamp": "timestamp",        // When the report was created
  "moderatorNote": "string"        // Notes added by the moderator during review
}
```

## 2. `flagged_content`
Stores content that has been flagged automatically or manually for review.

```json
// flagged_content/{contentId}
{
  "contentType": "string",         // post, comment, message
  "contentId": "string",           // ID of the flagged content
  "userId": "string",              // ID of the user who created the content
  "flagReason": "string",          // Profanity, Spam, AI_Flagged, etc.
  "autoFlagged": "boolean",        // true if flagged by automated systems
  "hidden": "boolean",             // true if hidden from public view
  "timestamp": "timestamp"         // When the content was flagged
}
```

## 3. `moderation_actions`
Stores actions taken against users (warnings, mutes, bans).

```json
// moderation_actions/{actionId}
{
  "userId": "string",              // ID of the user the action is taken against
  "actionType": "string",          // warn, mute, ban
  "reason": "string",              // Reason for the action
  "expiresAt": "timestamp",        // Expiration time (null for permanent bans)
  "createdBy": "string",           // ID of the moderator or "system"
  "timestamp": "timestamp"         // When the action was created
}
```
