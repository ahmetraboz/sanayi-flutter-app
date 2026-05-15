import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/provider_model.dart';

class WorkplacesState {
  final List<ProviderModel> providers;
  final bool loading;
  final String? error;
  final String? selectedCity;

  const WorkplacesState({
    this.providers = const [],
    this.loading = false,
    this.error,
    this.selectedCity,
  });

  WorkplacesState copyWith({
    List<ProviderModel>? providers,
    bool? loading,
    String? error,
    String? selectedCity,
  }) {
    return WorkplacesState(
      providers: providers ?? this.providers,
      loading: loading ?? this.loading,
      error: error,
      selectedCity: selectedCity ?? this.selectedCity,
    );
  }
}

final workplacesProvider = StateNotifierProvider.autoDispose<WorkplacesNotifier, WorkplacesState>((ref) {
  return WorkplacesNotifier(ref.read(apiClientProvider));
});

class WorkplacesNotifier extends StateNotifier<WorkplacesState> {
  final ApiClient _api;

  WorkplacesNotifier(this._api) : super(const WorkplacesState());

  void selectCity(String city) {
    state = state.copyWith(selectedCity: city, loading: true, error: null);
    _fetchProviders(city);
  }

  Future<void> _fetchProviders(String city) async {
    try {
      final res = await _api.get('/api/service-profiles/by-city', queryParameters: {'city': city});
      final List data = res.data['data'] ?? [];
      final providers = data.map((e) => ProviderModel.fromJson(e)).toList();
      if (!mounted) return;
      state = state.copyWith(loading: false, providers: providers);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
