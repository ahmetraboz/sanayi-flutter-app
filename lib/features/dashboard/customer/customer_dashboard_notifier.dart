import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'customer_dashboard_repository.dart';
import 'models/dashboard_models.dart';

const _sentinel = Object();

class CustomerDashboardState {
  final bool loading;
  final String? error;
  final CustomerStats? stats;
  final List<ActiveJob> activeJobs;
  final List<RecentRequest> recentRequests;
  final List<RecentBid> recentBids;

  const CustomerDashboardState({
    this.loading = false,
    this.error,
    this.stats,
    this.activeJobs = const [],
    this.recentRequests = const [],
    this.recentBids = const [],
  });

  CustomerDashboardState copyWith({
    bool? loading,
    Object? error = _sentinel,
    Object? stats = _sentinel,
    List<ActiveJob>? activeJobs,
    List<RecentRequest>? recentRequests,
    List<RecentBid>? recentBids,
  }) {
    return CustomerDashboardState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      stats: identical(stats, _sentinel) ? this.stats : stats as CustomerStats?,
      activeJobs: activeJobs ?? this.activeJobs,
      recentRequests: recentRequests ?? this.recentRequests,
      recentBids: recentBids ?? this.recentBids,
    );
  }
}

class CustomerDashboardNotifier extends StateNotifier<CustomerDashboardState> {
  final CustomerDashboardRepository _repo;

  CustomerDashboardNotifier(this._repo)
    : super(const CustomerDashboardState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    if (!mounted) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await Future.wait([
        _repo.fetchStats(),
        _repo.fetchActiveJobs(),
        _repo.fetchRecentRequests(),
        _repo.fetchRecentBids(),
      ]);

      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        stats: results[0] as CustomerStats,
        activeJobs: results[1] as List<ActiveJob>,
        recentRequests: results[2] as List<RecentRequest>,
        recentBids: results[3] as List<RecentBid>,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        error: e is ApiException ? e.message : 'Veriler yüklenemedi',
      );
    }
  }
}

final customerDashboardProvider = StateNotifierProvider.autoDispose<
  CustomerDashboardNotifier,
  CustomerDashboardState
>((ref) {
  return CustomerDashboardNotifier(
    ref.read(customerDashboardRepositoryProvider),
  );
});
