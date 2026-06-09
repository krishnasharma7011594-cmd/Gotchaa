/// Implementation Guide for Gotchaa App Development
///
/// This document provides step-by-step instructions for implementing features
/// in the Gotchaa app following best practices and the established architecture.
///
/// Last Updated: February 24, 2026

// ============================================================================
// PART 1: QUICK START CHECKLIST
// ============================================================================

/*
✓ Core Infrastructure Created:
  ├─ Clean Architecture base classes
  ├─ Error handling system (exceptions, failures, results)
  ├─ Logging infrastructure
  ├─ Performance monitoring tools
  ├─ String, DateTime, and Number extensions
  ├─ Constants and configuration
  ├─ Testing utilities and mocks
  └─ Comprehensive documentation

Next Steps:
  1. Update pubspec.lock (run: flutter pub get)
  2. Implement dependency injection setup
  3. Create feature repositories and use cases
  4. Implement ViewModels with state management
  5. Build UI screens using established patterns
  6. Write unit tests for all business logic
  7. Add integration tests for critical flows
*/

// ============================================================================
// PART 2: STEP-BY-STEP FEATURE IMPLEMENTATION
// ============================================================================

/*
## Step 1: Create Feature Structure

```
lib/features/user_profile/
├── presentation/
│   ├── screens/
│   │   └── user_profile_screen.dart
│   ├── widgets/
│   │   ├── profile_header.dart
│   │   ├── stats_widget.dart
│   │   └── followers_list.dart
│   └── viewmodels/
│       └── user_profile_viewmodel.dart
├── domain/
│   ├── entities/
│   │   └── user_profile.dart
│   ├── repositories/
│   │   └── user_profile_repository.dart
│   └── usecases/
│       ├── get_user_profile_usecase.dart
│       ├── update_user_profile_usecase.dart
│       └── follow_user_usecase.dart
└── data/
    ├── datasources/
    │   ├── user_profile_remote_datasource.dart
    │   └── user_profile_local_datasource.dart
    ├── models/
    │   └── user_profile_model.dart
    └── repositories/
        └── user_profile_repository_impl.dart
```

## Step 2: Define Domain Models

```dart
// lib/features/user_profile/domain/entities/user_profile.dart

class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final bool isFollowing;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.followerCount,
    required this.followingCount,
    required this.postCount,
    required this.isFollowing,
    required this.createdAt,
  });
}
```

## Step 3: Define Repository Interface

```dart
// lib/features/user_profile/domain/repositories/user_profile_repository.dart

import 'package:gotchaa/core/core_barrel.dart';
import '../entities/user_profile.dart';

// Define failure type specific to this repository
class UserProfileFailure extends Failure {
  const UserProfileFailure({
    required String message,
    GotchaException? exception,
    this.field,
  }) : super(message: message, exception: exception);

  final String? field;
}

abstract class UserProfileRepository extends BaseRepository {
  /// Get a user's profile by ID
  Future<Result<UserProfile, UserProfileFailure>> getUserProfile(String userId);

  /// Get the current user's profile
  Future<Result<UserProfile, UserProfileFailure>> getCurrentUserProfile();

  /// Update the current user's profile
  Future<Result<UserProfile, UserProfileFailure>> updateProfile(
    UserProfile profile,
  );

  /// Follow a user
  Future<Result<void, UserProfileFailure>> followUser(String userId);

  /// Unfollow a user
  Future<Result<void, UserProfileFailure>> unfollowUser(String userId);
}
```

## Step 4: Implement Use Cases

```dart
// lib/features/user_profile/domain/usecases/get_user_profile_usecase.dart

import 'package:gotchaa/core/core_barrel.dart';
import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

class GetUserProfileUseCase extends UseCase<UserProfile, String, UserProfileFailure> {
  const GetUserProfileUseCase(this._repository);

  final UserProfileRepository _repository;

  @override
  Future<Result<UserProfile, UserProfileFailure>> call(String userId) async {
    logDebug('GetUserProfileUseCase: Fetching profile for user $userId');
    return _repository.getUserProfile(userId);
  }
}
```

## Step 5: Create Data Models

```dart
// lib/features/user_profile/data/models/user_profile_model.dart

import '../../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required String id,
    required String username,
    required String displayName,
    required String bio,
    required String avatarUrl,
    required int followerCount,
    required int followingCount,
    required int postCount,
    required bool isFollowing,
    required DateTime createdAt,
  }) : super(
    id: id,
    username: username,
    displayName: displayName,
    bio: bio,
    avatarUrl: avatarUrl,
    followerCount: followerCount,
    followingCount: followingCount,
    postCount: postCount,
    isFollowing: isFollowing,
    createdAt: createdAt,
  );

  /// Convert from JSON API response
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      followerCount: json['followerCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      postCount: json['postCount'] as int? ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'displayName': displayName,
    'bio': bio,
    'avatarUrl': avatarUrl,
    'followerCount': followerCount,
    'followingCount': followingCount,
    'postCount': postCount,
    'isFollowing': isFollowing,
    'createdAt': createdAt.toIso8601String(),
  };
}
```

## Step 6: Implement Data Sources

```dart
// lib/features/user_profile/data/datasources/user_profile_remote_datasource.dart

import 'package:dio/dio.dart';
import '../models/user_profile_model.dart';

abstract class UserProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile(String userId);
  Future<UserProfileModel> updateProfile(UserProfileModel profile);
  Future<void> followUser(String userId);
}

class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  const UserProfileRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    final response = await _dio.get('/users/\$userId/profile');
    return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserProfileModel> updateProfile(UserProfileModel profile) async {
    final response = await _dio.put(
      '/users/\${profile.id}/profile',
      data: profile.toJson(),
    );
    return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> followUser(String userId) async {
    await _dio.post('/users/\$userId/follow');
  }
}
```

## Step 7: Implement Repository

```dart
// lib/features/user_profile/data/repositories/user_profile_repository_impl.dart

import 'package:gotchaa/core/core_barrel.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_profile_remote_datasource.dart';
import '../models/user_profile_model.dart';

class UserProfileRepositoryImpl extends UserProfileRepository {
  const UserProfileRepositoryImpl(this._remoteDataSource);

  final UserProfileRemoteDataSource _remoteDataSource;

  @override
  Future<Result<UserProfile, UserProfileFailure>> getUserProfile(
    String userId,
  ) async {
    try {
      final profile = await _remoteDataSource.getUserProfile(userId);
      return Success<UserProfile, UserProfileFailure>(profile);
    } on NetworkException catch (e, st) {
      return Failure<UserProfile, UserProfileFailure>(
        UserProfileFailure(
          message: 'Failed to fetch profile: \${e.message}',
          exception: e,
        ),
      );
    } catch (e, st) {
      logError('getUserProfile error', error: e, stackTrace: st);
      return Failure<UserProfile, UserProfileFailure>(
        UserProfileFailure(
          message: 'An unexpected error occurred',
          exception: GenericException(message: e.toString(), stackTrace: st),
        ),
      );
    }
  }

  // Implement other methods similarly...
}
```

## Step 8: Create ViewModel

```dart
// lib/features/user_profile/presentation/viewmodels/user_profile_viewmodel.dart

import 'package:gotchaa/core/core_barrel.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/update_user_profile_usecase.dart';
import '../../domain/usecases/follow_user_usecase.dart';

class UserProfileViewModel extends StateViewModel<UserProfile> {
  UserProfileViewModel({
    required GetUserProfileUseCase getUserProfileUseCase,
    required UpdateUserProfileUseCase updateUserProfileUseCase,
    required FollowUserUseCase followUserUseCase,
  })  : _getUserProfileUseCase = getUserProfileUseCase,
        _updateUserProfileUseCase = updateUserProfileUseCase,
        _followUserUseCase = followUserUseCase;

  final GetUserProfileUseCase _getUserProfileUseCase;
  final UpdateUserProfileUseCase _updateUserProfileUseCase;
  final FollowUserUseCase _followUserUseCase;

  bool isFollowing = false;

  /// Load user profile
  Future<void> loadProfile(String userId) async {
    setLoading(true);
    clearError();

    final result = await _getUserProfileUseCase(userId);
    result.when(
      success: (profile) {
        setState(profile);
        isFollowing = profile.isFollowing;
        notifyListeners();
      },
      failure: setError,
    );

    setLoading(false);
  }

  /// Update user profile
  Future<void> updateProfile(UserProfile profile) async {
    setLoading(true);
    clearError();

    final result = await _updateUserProfileUseCase(profile);
    result.when(
      success: setState,
      failure: setError,
    );

    setLoading(false);
  }

  /// Toggle follow status
  Future<void> toggleFollow(String userId) async {
    final result = isFollowing
        ? await _followUserUseCase.unfollow(userId)
        : await _followUserUseCase.follow(userId);

    result.when(
      success: (_) {
        isFollowing = !isFollowing;
        notifyListeners();
      },
      failure: setError,
    );
  }
}
```

## Step 9: Create UI Screen

```dart
// lib/features/user_profile/presentation/screens/user_profile_screen.dart

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  final String userId;

  @override
  State createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late UserProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UserProfileViewModel(
      getUserProfileUseCase: GetUserProfileUseCase(
        getIt<UserProfileRepository>(),
      ),
      // Initialize other use cases...
    );
    _viewModel.loadProfile(widget.userId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.error != null) {
            return Center(
              child: Text('Error: \${_viewModel.error?.message}'),
            );
          }

          final profile = _viewModel.state;
          if (profile == null) {
            return const Center(child: Text('No profile found'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile header
                ProfileHeader(profile: profile),

                // Stats
                StatsWidget(profile: profile),

                // Follow button
                ElevatedButton(
                  onPressed: () => _viewModel.toggleFollow(profile.id),
                  child: Text(_viewModel.isFollowing ? 'Unfollow' : 'Follow'),
                ),

                // Posts list
                FollowersList(userId: profile.id),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

## Step 10: Write Unit Tests

```dart
// test/features/user_profile/get_user_profile_usecase_test.dart

void main() {
  group('GetUserProfileUseCase', () {
    late MockUserProfileRepository mockRepository;
    late GetUserProfileUseCase useCase;

    setUp(() {
      mockRepository = MockUserProfileRepository();
      useCase = GetUserProfileUseCase(mockRepository);
    });

    test('should return user profile when successful', () async {
      final testProfile = TestUtils.createMockUserProfile();
      mockRepository.mockGetUserProfileSuccess(testProfile);

      final result = await useCase('user-1');

      expect(result.isSuccess(), true);
      expect(result.getOrNull(), testProfile);
    });

    test('should return failure when network error occurs', () async {
      mockRepository.mockGetUserProfileFailure(
        UserProfileFailure(message: 'Network error'),
      );

      final result = await useCase('user-1');

      expect(result.isFailure(), true);
      expect(result.getFailureOrNull()?.message, contains('Network'));
    });
  });
}
```

## Step 11: Setup Dependency Injection

// To be implemented - DI setup will follow this structure:
// class ServiceLocator {
//   static Future<void> setup() async {
//     // Repositories
//     getIt.registerSingleton<UserProfileRepository>(
//       UserProfileRepositoryImpl(
//         remoteDataSource: getIt<UserProfileRemoteDataSource>(),
//       ),
//     );
//
//     // Use Cases
//     getIt.registerSingleton<GetUserProfileUseCase>(
//       GetUserProfileUseCase(getIt<UserProfileRepository>()),
//     );
//   }
// }

*/

// ============================================================================
// PART 3: COMMON PATTERNS & TEMPLATES
// ============================================================================

/*
## Pattern 1: Optional Success with Loading State

```dart
class DataListViewModel extends ListViewModel<Item> {
  Future<void> loadItems() async {
    setLoading(true);
    final result = await useCase.call();
    result.when(
      success: setItems,
      failure: setError,
    );
    setLoading(false);
  }
}
```

## Pattern 2: Pagination

```dart
class PaginatedListViewModel extends ListViewModel<Item> {
  int _currentPage = 1;

  Future<void> loadMoreItems() async {
    if (isLoading) return;
    setLoading(true);

    final result = await useCase(page: _currentPage);
    result.when(
      success: (items) {
        addItems(items);
        _currentPage++;
      },
      failure: setError,
    );

    setLoading(false);
  }
}
```

## Pattern 3: Retry Logic

```dart
Future<Result<T, F>> retryAsync<T, F extends Failure>(
  Future<Result<T, F>> Function() operation, {
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 1),
}) async {
  for (int i = 0; i < maxRetries; i++) {
    final result = await operation();
    if (result.isSuccess()) return result;
    if (i < maxRetries - 1) await Future.delayed(delay);
  }
  return result;
}
```

## Pattern 4: Debounced Search

```dart
final searchDebouncer = Debouncer(duration: Duration(milliseconds: 500));

void onSearchChanged(String query) {
  searchDebouncer(() {
    _performSearch(query);
  });
}
```
*/

library;
