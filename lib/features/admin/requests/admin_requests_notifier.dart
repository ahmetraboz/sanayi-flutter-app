import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/services/admin_api_service.dart';
import '../../../../shared/models/request_model.dart';

class AdminRequestsState {
  final bool loading;
  final String? error;
  final List<RequestModel> requests;

  const AdminRequestsState({
    this.loading = false,
    this.error,
    this.requests = const [],
  });

  AdminRequestsState copyWith({
    bool? loading,
    String? error,
    List<RequestModel>? requests,
    bool clearError = false,
  }) {
    return AdminRequestsState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      requests: requests ?? this.requests,
    );
  }
}

class AdminRequestsNotifier extends StateNotifier<AdminRequestsState> {
  final AdminApiService _api;

  AdminRequestsNotifier(this._api) : super(const AdminRequestsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final requests = await _api.getRequests();
      state = state.copyWith(loading: false, requests: requests);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final adminRequestsProvider = StateNotifierProvider.autoDispose<AdminRequestsNotifier, AdminRequestsState>((ref) {
  return AdminRequestsNotifier(ref.read(adminApiProvider));
});
