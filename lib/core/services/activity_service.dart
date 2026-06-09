import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_providers.dart';
import '../providers/repository_providers.dart';

final activityServiceProvider = Provider(ActivityService.new);

class ActivityService {
  ActivityService(this._ref);
  final Ref _ref;
  Timer? _sessionTimer;
  bool _isActiveFinalized = false;

  /// Starts tracking a session for the current user.
  void startSession() {
    _isActiveFinalized = false;
    // Track 2 minutes of usage
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(minutes: 2), _markAsActive);
  }

  /// Called when the user performs a high-value action (post, comment, etc.)
  void logAction() {
    _markAsActive();
  }

  Future<void> _markAsActive() async {
    if (_isActiveFinalized) return;

    final profile = _ref.read(currentUserProfileProvider).asData?.value;
    if (profile == null) return;

    // If the user was invited with a code and hasn't triggered the reward yet
    if (profile.joinedWithCode.isNotEmpty) {
      final success =
          await _ref.read(firestoreRepositoryProvider).finalizeInviteReward(
                uid: profile.uid,
                joinedWithCode: profile.joinedWithCode,
              );
      if (success) {
        _isActiveFinalized = true;
      }
    }
  }

  void dispose() {
    _sessionTimer?.cancel();
  }
}
