import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../features/dashboard/notifications/notifications_notifier.dart';

class HeaderActions extends ConsumerWidget {
  const HeaderActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider).notifications.where((n) => !n.isRead).length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BadgeIconBtn(
          icon: Icons.notifications_outlined,
          badge: unread,
          onTap: () => context.push('/dashboard/notifications'),
        ),
        const SizedBox(width: 4),
        _BadgeIconBtn(
          icon: Icons.person_outline_rounded,
          onTap: () => context.push('/dashboard/profile'),
        ),
      ],
    );
  }
}

class _BadgeIconBtn extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  const _BadgeIconBtn({required this.icon, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Icon(icon, size: 20, color: AppColors.gray700),
          ),
          if (badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.red700,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
