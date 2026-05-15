import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/services/admin_api_service.dart';
import '../../../../shared/models/provider_model.dart';

class AdminProvidersState {
  final bool loading;
  final String? error;
  final List<ProviderModel> providers;

  const AdminProvidersState({
    this.loading = false,
    this.error,
    this.providers = const [],
  });

  AdminProvidersState copyWith({
    bool? loading,
    String? error,
    List<ProviderModel>? providers,
    bool clearError = false,
  }) {
    return AdminProvidersState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      providers: providers ?? this.providers,
    );
  }
}

class AdminProvidersNotifier extends StateNotifier<AdminProvidersState> {
  final AdminApiService _api;

  AdminProvidersNotifier(this._api) : super(const AdminProvidersState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final providers = await _api.getProviders();
      state = state.copyWith(loading: false, providers: providers);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final adminProvidersProvider =
    StateNotifierProvider.autoDispose<AdminProvidersNotifier, AdminProvidersState>((ref) {
  return AdminProvidersNotifier(ref.read(adminApiProvider));
});
