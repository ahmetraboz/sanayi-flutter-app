import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

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
        indicatorColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF4F46E5)),
            label: 'Anasayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people, color: Color(0xFF4F46E5)),
            label: 'Kullanıcılar',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description, color: Color(0xFF4F46E5)),
            label: 'Talepler',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business, color: Color(0xFF4F46E5)),
            label: 'Sağlayıcılar',
          ),
        ],
      ),
    );
  }

  int _indexFromPath(String path) {
    if (path.startsWith('/admin/users')) return 1;
    if (path.startsWith('/admin/requests')) return 2;
    if (path.startsWith('/admin/providers')) return 3;
    return 0;
  }

  void _navigate(BuildContext context, int i) {
    const paths = [
      '/admin',
      '/admin/users',
      '/admin/requests',
      '/admin/providers',
    ];
    context.go(paths[i]);
  }
}

