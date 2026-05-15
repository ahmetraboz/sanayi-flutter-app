import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import 'models/vehicle_detail.dart';

class VehicleDetailRepository {
  final ApiClient _api;

  VehicleDetailRepository(this._api);

  Future<VehicleDetailResponse> fetchVehicleDetail(int vehicleId) async {
    try {
      final res = await _api.get('/api/vehicles/$vehicleId');
      return VehicleDetailResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Araç detayları yüklenemedi');
    }
  }

  Future<void> updateVehicle(int vehicleId, Map<String, dynamic> data) async {
    try {
      await _api.put('/api/vehicles/$vehicleId', data: data);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Araç güncellenemedi');
    }
  }

  Future<void> deleteVehicle(int vehicleId) async {
    try {
      await _api.delete('/api/vehicles/$vehicleId');
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Araç silinemedi');
    }
  }
}

final vehicleDetailRepositoryProvider = Provider<VehicleDetailRepository>((
  ref,
) {
  return VehicleDetailRepository(ref.read(apiClientProvider));
});
