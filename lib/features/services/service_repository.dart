import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../shared/models/provider_model.dart';

class ServiceProfileSuggestion {
  final int id;
  final String companyName;
  final String? city;
  final String? district;

  const ServiceProfileSuggestion({
    required this.id,
    required this.companyName,
    this.city,
    this.district,
  });

  factory ServiceProfileSuggestion.fromJson(Map<String, dynamic> json) =>
      ServiceProfileSuggestion(
        id: json['id'] as int,
        companyName: json['companyName'] as String,
        city: json['city'] as String?,
        district: json['district'] as String?,
      );
}

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository(ref.read(apiClientProvider));
});

typedef ProvidersResult = ({List<ProviderModel> providers, Pagination pagination});
typedef ProviderDetailResult = ({ProviderModel provider, List<ReviewModel> reviews});

class ServiceRepository {
  final ApiClient _api;
  ServiceRepository(this._api);

  Future<ProvidersResult> fetchProviders({
    String? city,
    String? search,
    String? sort,
    double? minRating,
    int page = 1,
    int limit = 12,
  }) async {
    try {
      final res = await _api.get('/api/public/providers', queryParameters: {
        if (city != null && city.isNotEmpty) 'city': city,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        if (minRating != null) 'minRating': minRating,
        'page': page,
        'limit': limit,
      });
      final data = res.data as Map<String, dynamic>;
      final providers = (data['providers'] as List)
          .map((e) => ProviderModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = Pagination.fromJson(data['pagination'] as Map<String, dynamic>);
      return (providers: providers, pagination: pagination);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Servisler yüklenemedi');
    }
  }

  Future<ProviderDetailResult> fetchProviderDetail(int id) async {
    try {
      final res = await _api.get('/api/public/providers/$id');
      final data = res.data as Map<String, dynamic>;
      final provider = ProviderModel.fromJson(data['provider'] as Map<String, dynamic>);
      final reviews = (data['reviews'] as List? ?? [])
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (provider: provider, reviews: reviews);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Servis detayı yüklenemedi');
    }
  }

  Future<List<ServiceProfileSuggestion>> searchServiceProfiles(String q) async {
    try {
      final res = await _api.get('/api/service-profiles/search', queryParameters: {'q': q});
      final data = res.data as Map<String, dynamic>;
      return (data['data'] as List)
          .map((e) => ServiceProfileSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Arama başarısız');
    }
  }

  String placePhotoUrl(String placeId) {
    final base = _api.baseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base/api/public/place-photo?placeId=$placeId';
  }
}
