import 'package:go_router/go_router.dart';
import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/admin/shell/admin_shell.dart';
import '../../features/admin/users/admin_users_screen.dart';
import '../../features/admin/requests/admin_requests_screen.dart';
import '../../features/admin/providers/admin_providers_screen.dart';
import '../../features/admin/bids/admin_bids_screen.dart';
import '../../features/admin/reviews/admin_reviews_screen.dart';
import '../../features/admin/guest_bookings/admin_guest_bookings_screen.dart';
import '../../features/admin/services/admin_services_screen.dart';
import '../../features/admin/services/admin_service_detail_screen.dart';
import '../../features/admin/activity/admin_activity_screen.dart';

final adminShellRoute = ShellRoute(
  builder: (context, state, child) => AdminShell(child: child),
  routes: [
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const AdminUsersScreen(),
    ),
    GoRoute(
      path: '/admin/requests',
      builder: (context, state) => const AdminRequestsScreen(),
    ),
    GoRoute(
      path: '/admin/providers',
      builder: (context, state) => const AdminProvidersScreen(),
    ),
    GoRoute(
      path: '/admin/bids',
      builder: (context, state) => const AdminBidsScreen(),
    ),
    GoRoute(
      path: '/admin/reviews',
      builder: (context, state) => const AdminReviewsScreen(),
    ),
    GoRoute(
      path: '/admin/guest-bookings',
      builder: (context, state) => const AdminGuestBookingsScreen(),
    ),
    GoRoute(
      path: '/admin/services',
      builder: (context, state) => const AdminServicesScreen(),
    ),
    GoRoute(
      path: '/admin/services/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return AdminServiceDetailScreen(serviceId: id);
      },
    ),
    GoRoute(
      path: '/admin/activity',
      builder: (context, state) => const AdminActivityScreen(),
    ),
  ],
);
