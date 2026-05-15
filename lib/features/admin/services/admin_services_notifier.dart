import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/services/admin_api_service.dart';
import '../../../../shared/models/service_model.dart';

class AdminServicesState {
  final bool loading;
  final String? error;
  final List<ServiceModel> services;

  const AdminServicesState({
    this.loading = false,
    this.error,
    this.services = const [],
  });

  AdminServicesState copyWith({
    bool? loading,
    String? error,
    List<ServiceModel>? services,
    bool clearError = false,
  }) {
    return AdminServicesState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      services: services ?? this.services,
    );
  }
}

class AdminServicesNotifier extends StateNotifier<AdminServicesState> {
  final AdminApiService _api;

  AdminServicesNotifier(this._api) : super(const AdminServicesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final services = await _api.getServices();
      state = state.copyWith(loading: false, services: services);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final adminServicesProvider = StateNotifierProvider.autoDispose<AdminServicesNotifier, AdminServicesState>((ref) {
  return AdminServicesNotifier(ref.read(adminApiProvider));
});
