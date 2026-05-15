import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import 'models/vehicle_detail.dart';

class VehiclesListState {
  final bool loading;
  final String? error;
  final List<VehicleDetail> vehicles; // Reusing VehicleDetail since fields match mostly

  const VehiclesListState({
    this.loading = false,
    this.error,
    this.vehicles = const [],
  });

  VehiclesListState copyWith({
    bool? loading,
    String? error,
    List<VehicleDetail>? vehicles,
  }) {
    return VehiclesListState(
      loading: loading ?? this.loading,
      error: error, // Clear error if not provided
      vehicles: vehicles ?? this.vehicles,
    );
  }
}

class VehiclesListNotifier extends StateNotifier<VehiclesListState> {
  final ApiClient _api;

  VehiclesListNotifier(this._api) : super(const VehiclesListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.get('/api/vehicles');
      final list = res.data['data'] as List? ?? [];
      
      state = state.copyWith(
        loading: false,
        vehicles: list.map((e) => VehicleDetail.fromJson(e)).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e is DioException ? e.message : 'Araçlar yüklenemedi',
      );
    }
  }

  Future<void> deleteVehicle(int id) async {
    try {
      await _api.delete('/api/vehicles/$id');
      state = state.copyWith(
        vehicles: state.vehicles.where((v) => v.id != id).toList(),
      );
    } catch (e) {
      throw e is DioException ? e.message ?? 'Hata' : 'Araç silinemedi';
    }
  }

  Future<void> createVehicle(Map<String, dynamic> data) async {
    try {
      await _api.post('/api/vehicles', data: data);
      await load();
    } catch (e) {
      throw e is DioException ? e.message ?? 'Hata' : 'Araç eklenemedi';
    }
  }

  Future<void> updateVehicle(int id, Map<String, dynamic> data) async {
    try {
      await _api.put('/api/vehicles/$id', data: data);
      await load();
    } catch (e) {
      throw e is DioException ? e.message ?? 'Hata' : 'Araç güncellenemedi';
    }
  }
}

final vehiclesListProvider = StateNotifierProvider.autoDispose<VehiclesListNotifier, VehiclesListState>((ref) {
  return VehiclesListNotifier(ref.read(apiClientProvider));
});
