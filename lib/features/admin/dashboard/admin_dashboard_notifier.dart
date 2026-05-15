import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'admin_dashboard_repository.dart';
import 'models/admin_stats.dart';
import 'models/pending_provider.dart';

const _sentinel = Object();

class AdminDashboardState {
  final bool loading;
  final String? error;
  final AdminStats? stats;
  final List<PendingProvider> pendingApprovals;
  final int? actioningId;
  final String? actionError;

  const AdminDashboardState({
    this.loading = false,
    this.error,
    this.stats,
    this.pendingApprovals = const [],
    this.actioningId,
    this.actionError,
  });

  AdminDashboardState copyWith({
    bool? loading,
    Object? error = _sentinel,
    Object? stats = _sentinel,
    List<PendingProvider>? pendingApprovals,
    Object? actioningId = _sentinel,
    Object? actionError = _sentinel,
  }) {
    return AdminDashboardState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      stats: identical(stats, _sentinel) ? this.stats : stats as AdminStats?,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      actioningId: identical(actioningId, _sentinel) ? this.actioningId : actioningId as int?,
      actionError: identical(actionError, _sentinel) ? this.actionError : actionError as String?,
    );
  }
}

class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  final AdminDashboardRepository _repo;

  AdminDashboardNotifier(this._repo) : super(const AdminDashboardState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await Future.wait([
        _repo.fetchStats(),
        _repo.fetchPendingApprovals(),
      ]);
      state = state.copyWith(
        loading: false,
        stats: results[0] as AdminStats,
        pendingApprovals: results[1] as List<PendingProvider>,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e is ApiException ? e.message : 'Veriler yüklenemedi',
      );
    }
  }

  Future<void> approveProvider(int id) => _updateStatus(id, 'approved');
  Future<void> rejectProvider(int id) => _updateStatus(id, 'rejected');

  Future<void> _updateStatus(int id, String status) async {
    state = state.copyWith(actioningId: id, actionError: null);
    try {
      await _repo.updateProviderStatus(id, status);
      state = state.copyWith(
        actioningId: null,
        pendingApprovals: state.pendingApprovals.where((p) => p.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        actioningId: null,
        actionError: e is ApiException ? e.message : 'İşlem başarısız',
      );
    }
  }
}

final adminDashboardProvider =
    StateNotifierProvider.autoDispose<AdminDashboardNotifier, AdminDashboardState>((ref) {
  return AdminDashboardNotifier(ref.read(adminDashboardRepositoryProvider));
});
