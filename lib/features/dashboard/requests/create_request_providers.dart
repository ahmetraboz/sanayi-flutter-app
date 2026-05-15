import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../shared/models/provider_model.dart';
import '../../services/service_repository.dart';

class SimpleVehicle {
  final int id;
  final String brand;
  final String model;
  final String? licensePlate;

  SimpleVehicle({
    required this.id,
    required this.brand,
    required this.model,
    this.licensePlate,
  });

  factory SimpleVehicle.fromJson(Map<String, dynamic> json) => SimpleVehicle(
    id: json['id'] as int,
    brand: json['brand'] as String,
    model: json['model'] as String,
    licensePlate: json['licensePlate'] as String?,
  );
}

final userVehiclesProvider = FutureProvider.autoDispose<List<SimpleVehicle>>((
  ref,
) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/api/vehicles');
  final list = res.data['data'] as List? ?? [];
  return list.map((e) => SimpleVehicle.fromJson(e)).toList();
});

final submitRequestProvider = FutureProvider.autoDispose
    .family<void, Map<String, dynamic>>((ref, data) async {
      final api = ref.read(apiClientProvider);
      await api.post('/api/requests', data: data);
    });

final providersByCityProvider = FutureProvider.autoDispose
    .family<List<ProviderModel>, String>((ref, city) async {
      final repo = ref.read(serviceRepositoryProvider);
      final result = await repo.fetchProviders(city: city, limit: 30);
      return result.providers;
    });
