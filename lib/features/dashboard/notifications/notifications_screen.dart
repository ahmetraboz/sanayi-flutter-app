import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/providers/notification_polling_provider.dart';
import 'notifications_notifier.dart';
import '../../../../shared/models/notification_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/page_header.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(notificationsProvider.notifier).markAllAsRead();
      if (mounted) ref.read(notificationPollingProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    timeago.setLocaleMessages('tr', timeago.TrMessages());

    final unreadCount = state.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: 'Bildirimler',
              subtitle: state.notifications.isNotEmpty ? '$unreadCount okunmamış' : null,
              showBack: true,
              action: state.notifications.any((n) => !n.isRead)
                  ? GestureDetector(
                      onTap: () => notifier.markAllAsRead(),
                      child: const Icon(Icons.done_all, size: 22, color: AppColors.primary600),
                    )
                  : null,
            ),
            Expanded(child: _buildBody(context, state, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationsState state, NotificationsNotifier notifier) {
    if (state.loading && state.notifications.isEmpty) {
      return const _NotificationsSkeleton();
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red700),
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(color: AppColors.red700)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => notifier.load(),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.notifications_none, size: 40, color: AppColors.gray400),
              ),
              const SizedBox(height: 24),
              const Text(
                'Henüz bildirim yok',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900),
              ),
              const SizedBox(height: 12),
              const Text(
                'Size özel bildirimler ve güncellemeler burada görünecektir.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary600,
      onRefresh: notifier.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: state.notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          return _NotificationCard(
            notification: notification,
            onTap: () {
              if (!notification.isRead) {
                notifier.markAsRead(notification.id);
              }
              if (notification.link != null && notification.link!.isNotEmpty) {
                context.pop();
                context.push(notification.link!);
              }
            },
            onDelete: () => _showDeleteConfirm(context, notifier, notification),
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, NotificationsNotifier notifier, NotificationModel notification) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bildirimi Sil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: const Text('Bu bildirimi silmek istediğinize emin misiniz?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: AppColors.gray600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.deleteNotification(notification.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red700));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red700,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (notification.type) {
      case 'bid_received':
        icon = Icons.local_offer_outlined;
        iconColor = AppColors.blue600;
        bgColor = AppColors.info50;
        break;
      case 'request_update':
        icon = Icons.update;
        iconColor = AppColors.amber600;
        bgColor = AppColors.warning50;
        break;
      case 'system':
      default:
        icon = Icons.info_outline;
        iconColor = AppColors.primary600;
        bgColor = AppColors.success50;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray100),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 1)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!notification.isRead)
                Container(width: 3, color: iconColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: iconColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                                      color: AppColors.gray900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeago.format(notification.createdAt, locale: 'tr'),
                                  style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: const TextStyle(fontSize: 12, color: AppColors.gray500, height: 1.45),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 14, color: AppColors.gray300),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 40, height: 40, radius: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 13, radius: 5),
                  SizedBox(height: 6),
                  SkeletonBox(height: 12, radius: 4),
                  SizedBox(height: 5),
                  SkeletonBox(height: 11, width: 80, radius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
