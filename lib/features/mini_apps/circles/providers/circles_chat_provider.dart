import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/circle_message.dart';
import '../services/circles_firestore_service.dart';
import '../services/circles_local_cache_service.dart';
import 'circles_onboarding_provider.dart';

class CirclesChatState {
  CirclesChatState({
    required this.messages,
    required this.isLoading,
    required this.isThrottled,
    this.error,
  });

  factory CirclesChatState.initial() => CirclesChatState(
        messages: [],
        isLoading: false,
        isThrottled: false,
      );
  final List<CircleMessage> messages;
  final bool isLoading;
  final bool isThrottled;
  final String? error;

  CirclesChatState copyWith({
    List<CircleMessage>? messages,
    bool? isLoading,
    bool? isThrottled,
    String? error,
  }) =>
      CirclesChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        isThrottled: isThrottled ?? this.isThrottled,
        error: error ?? this.error,
      );
}

class CirclesChatNotifier extends StateNotifier<CirclesChatState> {
  CirclesChatNotifier(this._firestoreService, String circleId)
      : super(CirclesChatState.initial()) {
    loadCachedMessages(circleId).then((_) => streamMessages(circleId));
  }
  final CirclesFirestoreService _firestoreService;
  StreamSubscription? _chatSub;

  // Load local offline cached messages immediately
  Future<void> loadCachedMessages(String circleId) async {
    final cached =
        await CirclesLocalCacheService.instance.getCachedMessages(circleId);
    if (cached.isNotEmpty && state.messages.isEmpty) {
      state = state.copyWith(messages: cached);
    }
  }

  // Stream Firestore Realtime updates
  void streamMessages(String circleId) {
    _chatSub?.cancel();
    state = state.copyWith(isLoading: true);

    _chatSub =
        _firestoreService.streamChatMessages(circleId).listen((rawMsgs) async {
      // Filter out messages from Blocked Users
      final blocked = await _firestoreService.getBlockedUsers();
      final filtered =
          rawMsgs.where((m) => !blocked.contains(m.senderId)).toList();

      state = state.copyWith(
        messages: filtered,
        isLoading: false,
        isThrottled: _firestoreService.isThrottled,
      );

      // Cache locally
      await CirclesLocalCacheService.instance.cacheMessages(circleId, filtered);
    }, onError: (err) {
      state = state.copyWith(isLoading: false, error: err.toString());
    });
  }

  // Send message
  Future<void> sendMessage(String circleId, String text) async {
    await _firestoreService.sendChatMessage(circleId, text);
  }

  // Pin a location
  Future<void> pinLocation(String circleId, String title, double lat,
      double lng, String style) async {
    final pin = {
      'lat': lat,
      'lng': lng,
      'title': title,
      'style': style,
    };
    await _firestoreService.sendChatMessage(
      circleId,
      '📍 Meetup Pinned: $title',
      pinLocation: pin,
    );
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    super.dispose();
  }
}

final circlesChatProvider =
    StateNotifierProvider.family<CirclesChatNotifier, CirclesChatState, String>(
        (ref, circleId) {
  final service = ref.watch(circlesFirestoreServiceProvider);
  return CirclesChatNotifier(service, circleId);
});
