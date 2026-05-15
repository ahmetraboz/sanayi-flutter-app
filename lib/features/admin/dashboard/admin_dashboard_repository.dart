import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/admin_stats.dart';
import 'models/pending_provider.dart';

class AdminDashboardRepository {
  final ApiClient _api;

  AdminDashboardRepository(this._api);

  Future<AdminStats> fetchStats() async {
    try {
      final res = await _api.get('/api/admin/stats');
      return AdminStats.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'İstatistikler yüklenemedi');
    }
  }

  Future<List<PendingProvider>> fetchPendingApprovals() async {
    try {
      final res = await _api.get(
        '/api/service-profile',
        queryParameters: {'status': 'pending', 'limit': 10},
      );
      final data = res.data['data'] as List? ?? [];
      return data.map((e) => PendingProvider.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Onay bekleyenler yüklenemedi');
    }
  }

  Future<void> updateProviderStatus(int id, String status) async {
    try {
      await _api.put('/api/service-profile/$id/status', data: {'status': status});
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'İşlem başarısız');
    }
  }
}

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>((ref) {
  return AdminDashboardRepository(ref.read(apiClientProvider));
});
