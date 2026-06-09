import 'dart:async';
import 'package:gotchaa/core/logging/app_logger.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/profile_providers.dart';
import '../models/vibe_game.dart';
import '../models/vibe_message.dart';
import '../services/vibetalk_game_service.dart';
import '../services/vibetalk_match_service.dart';
import '../services/vibetalk_webrtc_service.dart';

enum VibeTalkStatus { idle, matching, connected, disconnected }

class VibeTalkState {

  const VibeTalkState({
    this.status = VibeTalkStatus.idle,
    this.roomId,
    this.isMuted = false,
    this.partnerDisconnected = false,
    this.currentUserId,
    this.anonymousUsername,
    this.isCaller = false,
    this.activeGame,
    this.matchCount = 0,
    this.isOnCooldown = false,
    this.isVideo = false,
    this.reconnectionState = 'stable',
    this.lastSessionDuration,
    this.lastSessionGamesPlayed = 0,
    this.sessionStartTime,
    this.currentSessionGamesPlayed = 0,
  });
  final VibeTalkStatus status;
  final String? roomId;
  final bool isMuted;
  final bool partnerDisconnected;
  final String? currentUserId;
  final String? anonymousUsername;
  final bool isCaller;
  final VibeGameContext? activeGame;
  final int matchCount;
  final bool isOnCooldown;
  final bool isVideo;
  final String reconnectionState;
  final Duration? lastSessionDuration;
  final int lastSessionGamesPlayed;
  final DateTime? sessionStartTime;
  final int currentSessionGamesPlayed;

  VibeTalkState copyWith({
    VibeTalkStatus? status,
    String? roomId,
    bool? isMuted,
    bool? partnerDisconnected,
    String? currentUserId,
    String? anonymousUsername,
    bool? isCaller,
    VibeGameContext? activeGame,
    int? matchCount,
    bool? isOnCooldown,
    bool? isVideo,
    String? reconnectionState,
    Duration? lastSessionDuration,
    int? lastSessionGamesPlayed,
    DateTime? sessionStartTime,
    int? currentSessionGamesPlayed,
  }) => VibeTalkState(
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      isMuted: isMuted ?? this.isMuted,
      partnerDisconnected: partnerDisconnected ?? this.partnerDisconnected,
      currentUserId: currentUserId ?? this.currentUserId,
      anonymousUsername: anonymousUsername ?? this.anonymousUsername,
      isCaller: isCaller ?? this.isCaller,
      activeGame: activeGame ?? this.activeGame,
      matchCount: matchCount ?? this.matchCount,
      isOnCooldown: isOnCooldown ?? this.isOnCooldown,
      isVideo: isVideo ?? this.isVideo,
      reconnectionState: reconnectionState ?? this.reconnectionState,
      lastSessionDuration: lastSessionDuration ?? this.lastSessionDuration,
      lastSessionGamesPlayed: lastSessionGamesPlayed ?? this.lastSessionGamesPlayed,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      currentSessionGamesPlayed: currentSessionGamesPlayed ?? this.currentSessionGamesPlayed,
    );
}

class VibeTalkNotifier extends StateNotifier<VibeTalkState> {

  VibeTalkNotifier(this.ref, this._webRTCService) : super(const VibeTalkState());
  final Ref ref;
  final VibeMatchService _matchService = VibeMatchService();
  final VibeWebRTCService _webRTCService;
  StreamSubscription? _roomSub;

  Future<void> startMatching({bool isVideo = false}) async {
    final currentUid = _matchService.uid;
    if (currentUid == 'unauthenticated') {
      
      return;
    }

    final currentLocale = ref.read(languageProvider);
    final userProfile = ref.read(currentUserProfileProvider).asData?.value;

    state = state.copyWith(
      status: VibeTalkStatus.matching, 
      isVideo: isVideo,
      currentUserId: currentUid,
      currentSessionGamesPlayed: 0, // Reset games played
    );
    
    try {
      final result = await _matchService.findMatch(
        languageCode: currentLocale.languageCode,
        continent: userProfile?.nation?['continent'] ?? 'Global',
        wantsGames: true,
        wantsVideo: isVideo,
        preferSameLanguage: true,
        preferSameContinent: false,
      );
      
      state = state.copyWith(
        status: VibeTalkStatus.connected, 
        roomId: result.roomId,
        isCaller: result.isCaller,
        sessionStartTime: DateTime.now(), // Set start time
      );
      
      _listenToRoom(result.roomId);
      await _webRTCService.init(result.roomId, currentUid, result.isCaller, isVideo);
    } catch (e) {
      
      state = state.copyWith(status: VibeTalkStatus.idle);
    }
  }

  void _listenToRoom(String roomId) {
    _roomSub = FirebaseFirestore.instance.collection('vibetalk_rooms').doc(roomId).snapshots().listen((snap) {
      if (snap.exists) {
        final data = snap.data();
        if (data != null) {
          state = state.copyWith(
            partnerDisconnected: data['status'] == 'ended',
            reconnectionState: data['reconnectionState'] ?? 'stable',
            activeGame: data['activeGame'] != null ? VibeGameContext.fromMap(data['activeGame']) : null,
          );
        }
      } else {
        state = state.copyWith(status: VibeTalkStatus.disconnected);
      }
    });
  }

  void toggleMute() {
    final muted = !state.isMuted;
    _webRTCService.toggleMute(muted);
    state = state.copyWith(isMuted: muted);
  }

  Future<void> endChat() async {
    _webRTCService.dispose();
    _roomSub?.cancel();
    await _matchService.cancelMatch();
    
    final duration = state.sessionStartTime != null 
        ? DateTime.now().difference(state.sessionStartTime!) 
        : Duration.zero;
        
    final roomId = state.roomId;
    
    state = state.copyWith(
      status: VibeTalkStatus.disconnected,
      lastSessionDuration: duration,
      lastSessionGamesPlayed: state.currentSessionGamesPlayed,
    );

    // Delete data from server
    if (roomId != null) {
      try {
        final messages = await FirebaseFirestore.instance
            .collection('vibetalk_rooms')
            .doc(roomId)
            .collection('messages')
            .get();
            
        for (var doc in messages.docs) {
          await doc.reference.delete();
        }
        
        await FirebaseFirestore.instance
            .collection('vibetalk_rooms')
            .doc(roomId)
            .delete();
      } catch (e) {
        // Log error or handle silently if it fails due to permissions
        AppLogger.e('Error deleting session data', e);
      }
    }
  }

  Future<void> submitGameAnswer(String answer) async {
    if (state.roomId == null) return;
    // Call Cloud Function to submit vote atomically
    await FirebaseFirestore.instance.collection('vibetalk_rooms').doc(state.roomId).update({
      'activeGame.userAnswers.${state.currentUserId}': answer,
    });
  }

  Future<void> startGame(String type) async {
    final uid = state.currentUserId;
    if (state.roomId == null || uid == null) return;
    final game = VibeTalkGameService.getRandomGame(type, uid);
    
    // Increment games played
    state = state.copyWith(currentSessionGamesPlayed: state.currentSessionGamesPlayed + 1);
    
    await FirebaseFirestore.instance.collection('vibetalk_rooms').doc(state.roomId).update({
      'activeGame': game.toMap(),
    });
  }

  Future<void> endGame() async {
    if (state.roomId == null) return;
    await FirebaseFirestore.instance.collection('vibetalk_rooms').doc(state.roomId).update({
      'activeGame': FieldValue.delete(),
    });
  }

  Future<void> sendMessage(String text) async {
    final uid = state.currentUserId;
    if (state.roomId == null || uid == null) return;
    await FirebaseFirestore.instance
        .collection('vibetalk_rooms')
        .doc(state.roomId)
        .collection('messages')
        .add({
      'senderId': uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isSystemMessage': false,
    });
  }

  Future<void> skipToNext() async {
    await endChat();
    await startMatching(isVideo: state.isVideo);
  }

  void resetToIdle() {
    state = state.copyWith(status: VibeTalkStatus.idle);
  }
}

final vibeWebRTCServiceProvider = Provider((ref) => VibeWebRTCService());

final vibeTalkProvider = StateNotifierProvider<VibeTalkNotifier, VibeTalkState>((ref) {
  // Watch auth state to ensure notifier is recreated on account switch
  ref.watch(authStateProvider);
  final service = ref.watch(vibeWebRTCServiceProvider);
  return VibeTalkNotifier(ref, service);
});
final vibeMessagesProvider = StreamProvider.autoDispose<List<VibeMessage>>((ref) {
  final state = ref.watch(vibeTalkProvider);
  if (state.roomId == null) return Stream.value([]);
  return FirebaseFirestore.instance.collection('vibetalk_rooms').doc(state.roomId).collection('messages').orderBy('timestamp', descending: true).snapshots().map((s) => s.docs.map((d) => VibeMessage.fromMap(d.data(), d.id)).toList());
});
