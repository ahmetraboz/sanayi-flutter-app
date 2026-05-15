import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';

class CustomerShell extends StatelessWidget {
  final Widget child;

  const CustomerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexFromPath(path);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _navigate(context, i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary600.withValues(alpha: 0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary600),
            label: 'Anasayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: AppColors.primary600),
            label: 'Keşfet',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description, color: AppColors.primary600),
            label: 'Talepler',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(
              Icons.directions_car,
              color: AppColors.primary600,
            ),
            label: 'Araçlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary600),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  int _indexFromPath(String path) {
    if (path.startsWith('/dashboard/workplaces')) return 1;
    if (path.startsWith('/dashboard/requests')) return 2;
    if (path.startsWith('/dashboard/vehicles')) return 3;
    if (path.startsWith('/dashboard/profile')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int i) {
    const paths = [
      '/dashboard',
      '/dashboard/workplaces',
      '/dashboard/requests',
      '/dashboard/vehicles',
      '/dashboard/profile',
    ];
    context.go(paths[i]);
  }
}
