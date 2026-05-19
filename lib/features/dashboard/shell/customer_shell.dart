import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../notifications/notifications_notifier.dart';

class CustomerShell extends ConsumerWidget {
  final Widget child;

  const CustomerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexFromPath(path);

    final unreadNotifications = ref
        .watch(notificationsProvider)
        .notifications
        .where((n) => !n.isRead)
        .toList();

    int tabBadge(String prefix) =>
        unreadNotifications.where((n) => n.link != null && n.link!.startsWith(prefix)).length;

    final badges = [
      0,
      tabBadge('/dashboard/workplaces'),
      tabBadge('/dashboard/requests'),
      tabBadge('/dashboard/bids'),
      tabBadge('/dashboard/vehicles'),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingNavBar(
              selectedIndex: selectedIndex,
              badges: badges,
              onTap: (i) => _navigate(context, i),
            ),
          ),
        ],
      ),
    );
  }

  int _indexFromPath(String path) {
    if (path.startsWith('/dashboard/workplaces')) return 1;
    if (path.startsWith('/dashboard/requests')) return 2;
    if (path.startsWith('/dashboard/bids')) return 3;
    if (path.startsWith('/dashboard/vehicles')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int i) {
    const paths = [
      '/dashboard',
      '/dashboard/workplaces',
      '/dashboard/requests',
      '/dashboard/bids',
      '/dashboard/vehicles',
    ];
    context.go(paths[i]);
  }
}

// ─── Floating Nav Bar ─────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<int> badges;
  final void Function(int) onTap;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.badges,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    const items = [
      (icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Anasayfa'),
      (icon: Icons.store_outlined, selectedIcon: Icons.store_rounded, label: 'Servisler'),
      (icon: Icons.description_outlined, selectedIcon: Icons.description_rounded, label: 'Talepler'),
      (icon: Icons.gavel_outlined, selectedIcon: Icons.gavel_rounded, label: 'Teklifler'),
      (icon: Icons.directions_car_outlined, selectedIcon: Icons.directions_car_rounded, label: 'Araçlar'),
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(12, 8, 12, bottomPad + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final item = items[i];
            return _NavItem(
              icon: item.icon,
              selectedIcon: item.selectedIcon,
              label: item.label,
              isSelected: selectedIndex == i,
              badge: badges[i],
              onTap: () => onTap(i),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary600 : AppColors.gray400;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary600.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 21,
                  color: color,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ],
            ),
            if (badge > 0)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.red700,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
