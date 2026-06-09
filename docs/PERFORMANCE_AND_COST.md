# Performance & Firebase Cost Protection

## Firestore

- **Persistence:** `configureFirestore()` in `main.dart` — unlimited cache.
- **Pagination:** `PaginationLimits` — feed 10, chats 20, notifications 20, followers 20, messages 50.
- **Cursor pages:** `getChatsPage`, `getMessagesPage` use `startAfterDocument` + `FirestoreQueryCache` (60s TTL).
- **Cost guard:** `FirestoreCostGuard` — session read counter, debug warn at 1000+, Crashlytics for expensive queries.

## Streams

- Use `GuardedStreamBuilder` where rapid rebuilds are possible (max 10 emissions/minute).

## Media

- `MediaCompressionService` — profile 500², post/story 1080, thumbnails 200² @ 60%.
- `StorageRepository` returns `MediaUploadResult` with `thumbnailUrl` for posts.
- Feed `PostCard` loads thumbnail; full image on post detail.

## Offline

- `ConnectivityService` + `OfflineBanner` in app shell.
- `OfflineQueueService` — persist actions; register handlers per feature.

## Traces

- `GotchaaPerformanceTraces` — feed_load, chat_open, vibetalk_match, image_upload_*.
