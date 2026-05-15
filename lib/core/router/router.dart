import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../../shared/models/user_model.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/booking/guest_booking_screen.dart';
import '../../features/dashboard/bids/customer_bids_screen.dart';
import '../../features/dashboard/customer/customer_dashboard_screen.dart';
import '../../features/dashboard/notifications/notifications_screen.dart';
import '../../features/dashboard/profile/customer_profile_screen.dart';
import '../../features/dashboard/requests/create_request_screen.dart';
import '../../features/dashboard/requests/request_detail_screen.dart';
import '../../features/dashboard/requests/request_list_screen.dart';
import '../../features/dashboard/shell/customer_shell.dart';
import '../../features/dashboard/vehicles/vehicle_detail_screen.dart';
import '../../features/dashboard/vehicles/vehicles_screen.dart';
import '../../features/dashboard/workplaces/workplaces_screen.dart';
import '../../features/landing/landing_screen.dart';
import '../../features/services/service_directory_screen.dart';
import '../../features/tracking/guest_booking_lookup_screen.dart';
import '../../features/tracking/guest_tracking_screen.dart';
import '../../features/provider/dashboard/provider_dashboard_screen.dart';
import '../../features/provider/requests/provider_requests_screen.dart';
import '../../features/provider/requests/provider_request_detail_screen.dart';
import '../../features/provider/bids/provider_bids_screen.dart';
import '../../features/provider/jobs/provider_jobs_screen.dart';
import '../../features/provider/notifications/provider_notifications_screen.dart';
import '../../features/provider/profile/provider_profile_screen.dart';
import '../../features/provider/reviews/provider_reviews_screen.dart';
import '../../features/provider/guest_bookings/provider_guest_bookings_screen.dart';
import '../../features/provider/guest_bookings/provider_guest_booking_detail_screen.dart';
import '../../features/provider/shell/provider_shell.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) => notifier.redirect(state),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/servisler', builder: (context, state) => const ServiceDirectoryScreen()),
      GoRoute(
        path: '/book',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return GuestBookingScreen(
            preselectedServiceId: extra?['serviceId'] as int?,
            preselectedCity: extra?['city'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/talebim',
        builder: (context, state) => const GuestBookingLookupScreen(),
        routes: [
          GoRoute(
            path: ':token',
            builder: (context, state) {
              final token = state.pathParameters['token'] ?? '';
              final q = state.uri.queryParameters;
              return GuestTrackingScreen(
                token: token,
                name: q['name'] ?? '',
                code: q['code'] ?? '',
              );
            },
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const CustomerDashboardScreen(),
          ),
          GoRoute(
            path: '/dashboard/requests',
            builder: (context, state) => const RequestListScreen(),
          ),
          GoRoute(
            path: '/dashboard/requests/new',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CreateRequestScreen(
                preselectedServiceId: extra?['serviceId'] as int?,
                preselectedServiceName: extra?['serviceName'] as String?,
              );
            },
          ),
          GoRoute(
            path: '/dashboard/requests/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return RequestDetailScreen(requestId: id);
            },
          ),
          GoRoute(
            path: '/dashboard/vehicles',
            builder: (context, state) => const VehiclesScreen(),
          ),
          GoRoute(
            path: '/dashboard/vehicles/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return VehicleDetailScreen(vehicleId: id);
            },
          ),
          GoRoute(
            path: '/dashboard/bids',
            builder: (context, state) => const CustomerBidsScreen(),
          ),
          GoRoute(
            path: '/dashboard/workplaces',
            builder: (context, state) => const WorkplacesScreen(),
          ),
          GoRoute(
            path: '/dashboard/profile',
            builder: (context, state) => const CustomerProfileScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => ProviderShell(child: child),
        routes: [
          GoRoute(
            path: '/provider',
            builder: (context, state) => const ProviderDashboardScreen(),
          ),
          GoRoute(
            path: '/provider/requests',
            builder: (context, state) => const ProviderRequestsScreen(),
          ),
          GoRoute(
            path: '/provider/requests/:id',
            builder: (context, state) => ProviderRequestDetailScreen(
              requestId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/provider/jobs',
            builder: (context, state) => const ProviderJobsScreen(),
          ),
          GoRoute(
            path: '/provider/notifications',
            builder: (context, state) => const ProviderNotificationsScreen(),
          ),
          GoRoute(
            path: '/provider/bids',
            builder: (context, state) => const ProviderBidsScreen(),
          ),
          GoRoute(
            path: '/provider/profile',
            builder: (context, state) => const ProviderProfileScreen(),
          ),
          GoRoute(
            path: '/provider/reviews',
            builder: (context, state) => const ProviderReviewsScreen(),
          ),
          GoRoute(
            path: '/provider/guest-bookings',
            builder: (context, state) => const ProviderGuestBookingsScreen(),
          ),
          GoRoute(
            path: '/provider/guest-bookings/:id',
            builder: (context, state) => ProviderGuestBookingDetailScreen(
              bookingId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      ShellRoute(
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
      ),
    ],
  );
});

class _AuthRouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _AuthRouterNotifier(this._ref) {
    _ref.listen<AsyncValue<UserModel?>>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }

  String? redirect(GoRouterState state) {
    final authState = _ref.read(authNotifierProvider);
    if (authState.isLoading) return null;

    final user = authState.valueOrNull;
    const publicRoutes = ['/', '/login', '/register', '/servisler', '/book', '/talebim'];
    final onAuthRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/register';
    final isPublic = publicRoutes.any((r) => state.matchedLocation.startsWith(r));

    if (user == null && !isPublic) return '/';
    if (user != null && state.matchedLocation == '/') return user.redirectPath;
    if (user != null && onAuthRoute) return user.redirectPath;
    return null;
  }
}
