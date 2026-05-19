import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../../shared/models/user_model.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/booking/guest_booking_screen.dart';
import '../../features/landing/landing_screen.dart';
import '../../features/services/service_directory_screen.dart';
import '../../features/tracking/guest_booking_lookup_screen.dart';
import '../../features/tracking/guest_tracking_screen.dart';
import 'customer_routes.dart';
import 'admin_routes.dart';

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
      customerShellRoute,
      ...customerStandaloneRoutes,
      adminShellRoute,
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
