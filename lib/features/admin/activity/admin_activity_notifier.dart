import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/services/admin_api_service.dart';

class AdminActivityState {
  final bool loading;
  final String? error;
  final List<dynamic> activities;

  const AdminActivityState({
    this.loading = false,
    this.error,
    this.activities = const [],
  });

  AdminActivityState copyWith({
    bool? loading,
    String? error,
    List<dynamic>? activities,
    bool clearError = false,
  }) {
    return AdminActivityState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      activities: activities ?? this.activities,
    );
  }
}

class AdminActivityNotifier extends StateNotifier<AdminActivityState> {
  final AdminApiService _api;

  AdminActivityNotifier(this._api) : super(const AdminActivityState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final activities = await _api.getActivity();
      state = state.copyWith(loading: false, activities: activities);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final adminActivityProvider = StateNotifierProvider.autoDispose<AdminActivityNotifier, AdminActivityState>((ref) {
  return AdminActivityNotifier(ref.read(adminApiProvider));
});
