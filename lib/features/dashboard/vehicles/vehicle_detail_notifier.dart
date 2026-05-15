import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import 'models/vehicle_detail.dart';
import 'vehicle_detail_repository.dart';

const _sentinel = Object();

class VehicleDetailState {
  final bool loading;
  final String? error;
  final VehicleDetail? vehicle;
  final List<VehicleRequestItem> requests;

  const VehicleDetailState({
    this.loading = false,
    this.error,
    this.vehicle,
    this.requests = const [],
  });

  VehicleDetailState copyWith({
    bool? loading,
    Object? error = _sentinel,
    Object? vehicle = _sentinel,
    List<VehicleRequestItem>? requests,
  }) {
    return VehicleDetailState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      vehicle:
          identical(vehicle, _sentinel)
              ? this.vehicle
              : vehicle as VehicleDetail?,
      requests: requests ?? this.requests,
    );
  }
}

class VehicleDetailNotifier extends StateNotifier<VehicleDetailState> {
  final VehicleDetailRepository _repo;
  final int vehicleId;

  VehicleDetailNotifier(this._repo, this.vehicleId)
    : super(const VehicleDetailState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _repo.fetchVehicleDetail(vehicleId);
      state = state.copyWith(
        loading: false,
        vehicle: res.vehicle,
        requests: res.requests,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e is ApiException ? e.message : 'Araç detayları yüklenemedi',
      );
    }
  }

  Future<void> deleteVehicle() async {
    try {
      await _repo.deleteVehicle(vehicleId);
    } catch (e) {
      throw e is ApiException ? e.message : 'Araç silinemedi';
    }
  }
}

final vehicleDetailProvider = StateNotifierProvider.family
    .autoDispose<VehicleDetailNotifier, VehicleDetailState, int>((ref, id) {
      return VehicleDetailNotifier(
        ref.read(vehicleDetailRepositoryProvider),
        id,
      );
    });
