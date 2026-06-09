import 'package:cloud_firestore/cloud_firestore.dart';
import '../logging/app_logger.dart';

/// Firestore persistence + offline cache sizing.
void configureFirestore() {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  AppLogger.i('Firestore persistence enabled, unlimited cache');
}
