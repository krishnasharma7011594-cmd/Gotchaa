import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gotchaa_empty_state.dart';
import '../../../../core/widgets/gotchaa_skeleton_loader.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(userNotificationsNotifierProvider.notifier).fetchNextBatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userNotificationsNotifierProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        foregroundColor: context.textPrimary,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        actions: [
          if (user != null)
            TextButton(
              onPressed: () {
                ref.read(notificationServiceProvider).markAllAsRead(user.uid);
              },
              child: const Text('Mark all read',
                  style: TextStyle(color: AppColors.primaryBlue)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(userNotificationsNotifierProvider.notifier).refresh(),
        child: Builder(builder: (context) {
          // Show skeleton while initially loading (no data yet)
          if (state.isLoading && state.notifications.isEmpty) {
            return const GotchaaSkeletonLoader.notification(itemCount: 6);
          }

          // Empty state
          if (state.notifications.isEmpty && !state.isLoading) {
            return ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                const GotchaaEmptyState.notifications(),
              ],
            );
          }

          // List with optional load-more spinner
          return ListView.builder(
            controller: _scrollController,
            itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.notifications.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return _buildNotificationTile(
                  context, ref, state.notifications[index]);
            },
          );
        }),
      ),
    );
  }

  Widget _buildNotificationTile(
      BuildContext context, WidgetRef ref, NotificationModel notif) {
    IconData icon;
    Color iconColor;
    String text;

    switch (notif.type) {
      case 'like':
      case 'commentLike':
        icon = Icons.favorite;
        iconColor = Colors.red;
        text = '${notif.fromUsername} liked your post/comment 🔥';
        break;
      case 'comment':
        icon = Icons.comment;
        iconColor = Colors.purple;
        text = '${notif.fromUsername} commented: "${notif.message ?? ''}"';
        break;
      case 'follow':
        icon = Icons.person_add;
        iconColor = AppColors.primaryBlue;
        text = '${notif.fromUsername} started following you';
        break;
      case 'vybzMilestone':
        icon = Icons.local_fire_department;
        iconColor = AppColors.karmaOrange;
        text = 'Milestone! Your Vybz reached ${notif.message} views! 🏆';
        break;
      case 'tip':
        icon = Icons.monetization_on;
        iconColor = Colors.green;
        text = '${notif.fromUsername} tipped you \$${notif.message} 💸';
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
        text = notif.message ?? 'New notification';
    }

    final String timeStr = _formatTimeAgo(notif.createdAt);

    return InkWell(
      onTap: () {
        final user = ref.read(currentUserProvider);
        if (user != null && !notif.isRead) {
          ref.read(notificationServiceProvider).markAsRead(user.uid, notif.id);
        }
        // Navigate to target if needed
      },
      child: Container(
        color: !notif.isRead
            ? AppColors.primaryBlue.withValues(alpha: 0.06)
            : Colors.transparent,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: iconColor.withValues(alpha: 0.12),
                backgroundImage: notif.fromAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(notif.fromAvatar)
                    : null,
                child: notif.fromAvatar.isEmpty
                    ? Icon(icon, color: iconColor, size: 24)
                    : null,
              ),
              if (notif.fromAvatar.isNotEmpty)
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 14),
                  ),
                ),
            ],
          ),
          title: Text(
            text,
            style: GoogleFonts.outfit(
              fontWeight: !notif.isRead ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              color: context.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              Text(notif.fromNationFlag, style: const TextStyle(fontSize: 12)),
              const Spacer(),
              Text(timeStr,
                  style: GoogleFonts.outfit(
                      color: context.textHint, fontSize: 11)),
            ]),
          ),
          trailing:
              notif.targetImageUrl != null && notif.targetImageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: notif.targetImageUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : (!notif.isRead
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle),
                        )
                      : null),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.month}/${time.day}';
  }
}
