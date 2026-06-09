# User Generated Content (UGC) Compliance Report

This report documents the implementation details and verification of the User Generated Content (UGC) compliance and moderation workflows within the **Gotchaa** platform.

---

## 1. Feature Specifications & Technical Implementations

### A. Block User / Unblock User / Mute User
- **Firestore Schema**: 
  - Block relationships are persisted in a top-level `blocked_accounts` collection using document IDs in the form `${blockerId}_blocked_${blockedId}`.
  - Mute relationships are persisted in a top-level `muted_accounts` collection using document IDs in the form `${muterId}_muted_${mutedId}`.
  - In addition, blocker profiles sync `blockedUids` and `mutedUids` to their profile document in the `users` collection to optimize client-side feed operations.
- **Mutual Unfollowing**: Performing a block automatically terminates followers/following relationships both ways.
- **E2EE / Chat Rules**: Messages, chats, and follow requests are protected by server-side Firestore security rules that lookup relationships in `blocked_accounts` and prevent read/write actions if a block exists.

### B. Feed, Search, and Chat Filtering
- **Chats & Messages**:
  - `chatListProvider` watches `blockedUidsProvider` and filters out all chats containing blocked participants.
  - `sendMessage` performs pre-flight verification against `blocked_accounts` and throws an exception on block detection.
- **Main Feeds (For You, Following, Nearby)**:
  - Feed items from blocked or muted creators are dynamically filtered out of post feeds and Vybz video lists using `blockedUidsProvider` and `mutedUidsProvider`.
- **Search and Recommendations**:
  - `userSearchProvider` and `postSearchProvider` in `explore_screen.dart` and `user_search_sheet.dart` exclude blocked/muted users and their posts from search results.
- **Profile Redirection**:
  - Trying to navigate to a blocked user's profile returns a "User not available" placeholder.

### C. Automated Moderation Workflow
- **Rules Trigger**: 
  - When a report is submitted via `submitReport`, the repository queries the `moderation_reports` collection for occurrences of the same `contentId` in the preceding 24 hours.
- **Trigger Actions ($\ge 3$ reports)**:
  - Automatically updates the content document (`posts`, `chats/messages`, or `vybz`) to set `isHidden: true` and `hiddenReason: 'moderation_limit'`.
  - Dispatches the content metadata to the `moderation_queue` collection for moderator validation.

---

## 2. Regulatory Compliance Verification

### A. Google Play Store UGC Policy Compliance
- **Requirement**: Provide an in-app system for blocking and reporting users and content, and immediately hide offending content.
- **Resolution**: Implemented dynamic block/mute menus on profile screens, report bottom sheets, dynamic filtering across search/feeds, and automated $3+$ reports/24h content hiding into a moderator review queue.

### B. General Data Protection Regulation (GDPR) Compliance
- **Requirement**: Right to restrict processing (Art. 18) and Right to be forgotten / Erasure (Art. 17).
- **Resolution**: Block/Mute actions allow users to restrict the processing of their data in other users' feeds. Deleting block/mute entries complies with standard erasure procedures.

### C. India Digital Personal Data Protection (DPDP) Act Compliance
- **Requirement**: Processing based on consent and lawful purposes; user control over personal data and access restrictions.
- **Resolution**: Mute and Block tools give data principals complete control over how their profiles are visible, how their data interacts, and who can send them messages or invitations.
