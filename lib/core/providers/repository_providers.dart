import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import '../repositories/firestore_repository.dart';
import '../repositories/post_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/social_repository.dart';
import '../repositories/storage_repository.dart';
import '../security/e2ee_service.dart';
import '../services/username_service.dart';

final firestoreRepositoryProvider =
    Provider<FirestoreRepository>((ref) => FirestoreRepository());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firestore = ref.watch(firestoreRepositoryProvider);
  final e2ee = ref.watch(e2eeServiceProvider);
  return AuthRepository(firestore, e2ee);
});

final storageRepositoryProvider =
    Provider<StorageRepository>((ref) => StorageRepository());

final postRepositoryProvider =
    Provider<PostRepository>((ref) => PostRepository());

final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => ProfileRepository());

final socialRepositoryProvider =
    Provider<SocialRepository>((ref) => SocialRepository());

final usernameServiceProvider =
    Provider<UsernameService>((ref) => UsernameService());
