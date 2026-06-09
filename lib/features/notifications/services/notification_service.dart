import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_providers.dart';
import '../models/notification_model.dart';

final notificationServiceProvider = Provider<NotificationService>(
    (ref) => NotificationService(FirebaseFirestore.instance));

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);

  final service = ref.watch(notificationServiceProvider);
  return service.getUnreadCount(user.uid);
});

class NotificationsState {
  NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDoc,
  });
  final List<NotificationModel> notifications;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
  }) =>
      NotificationsState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        lastDoc: lastDoc ?? this.lastDoc,
      );
}

final userNotificationsNotifierProvider =
    StateNotifierProvider<UserNotificationsNotifier, NotificationsState>(
        UserNotificationsNotifier.new);

class UserNotificationsNotifier extends StateNotifier<NotificationsState> {
  UserNotificationsNotifier(this._ref) : super(NotificationsState()) {
    fetchNextBatch();
  }
  final Ref _ref;

  Future<void> fetchNextBatch() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(isLoading: false, hasMore: false);
      return;
    }

    try {
      final service = _ref.read(notificationServiceProvider);
      final result =
          await service.getNotificationsPaged(user.uid, lastDoc: state.lastDoc);

      final newNotifications = result.docs
          .map((doc) => NotificationModel.fromMap(
              doc.id, doc.data()! as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        notifications: [...state.notifications, ...newNotifications],
        isLoading: false,
        hasMore: newNotifications.length == 20,
        lastDoc: result.docs.isNotEmpty ? result.docs.last : state.lastDoc,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = NotificationsState();
    await fetchNextBatch();
  }
}

class NotificationService {
  NotificationService(this._firestore);
  final FirebaseFirestore _firestore;

  Future<QuerySnapshot> getNotificationsPaged(String uid,
      {DocumentSnapshot? lastDoc}) async {
    var query = _firestore
        .collection('notifications')
        .doc(uid)
        .collection('userNotifications')
        .orderBy('createdAt', descending: true)
        .limit(20);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.get();
  }

  Stream<int> getUnreadCount(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => (snap.data()?['unreadNotificationsCount'] as int?) ?? 0);

  Future<void> markAsRead(String uid, String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(uid)
        .collection('userNotifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String uid) async {
    final batch = _firestore.batch();
    final query = await _firestore
        .collection('notifications')
        .doc(uid)
        .collection('userNotifications')
        .where('isRead', isEqualTo: false)
        .limit(500)
        .get();

    for (final doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
