import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../features/booking/models/booking_form_data.dart';
import '../../features/dashboard/damage/damage_analysis_screen.dart';
import '../../features/services/service_directory_screen.dart';

final customerShellRoute = ShellRoute(
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
          preselectedServiceCity: extra?['serviceCity'] as String?,
          preselectedServiceAreas:
              (extra?['serviceAreas'] as List?)?.cast<String>(),
          preselectedVehicleId: extra?['vehicleId'] as int?,
          preselectedCategory: extra?['category'] as String?,
          initialDamageReports:
              (extra?['damageReports'] as List?)?.cast<DamageReport>(),
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
      builder: (context, state) => const ServiceDirectoryScreen(asTab: true),
    ),
  ],
);

final customerStandaloneRoutes = [
  GoRoute(
    path: '/dashboard/profile',
    builder: (context, state) => const CustomerProfileScreen(),
  ),
  GoRoute(
    path: '/dashboard/notifications',
    builder: (context, state) => const NotificationsScreen(),
  ),
  GoRoute(
    path: '/dashboard/damage-analysis',
    builder: (context, state) => const DamageAnalysisScreen(),
  ),
];
