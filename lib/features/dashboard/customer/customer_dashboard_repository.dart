import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/dashboard_models.dart';

class CustomerDashboardRepository {
  final ApiClient _api;

  CustomerDashboardRepository(this._api);

  Future<CustomerStats> fetchStats() async {
    try {
      final res = await _api.get('/api/customer/stats');
      return CustomerStats.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'İstatistikler yüklenemedi');
    } catch (_) {
      throw ApiException('İstatistikler yüklenemedi');
    }
  }

  Future<List<ActiveJob>> fetchActiveJobs() async {
    try {
      final res = await _api.get('/api/requests/active');
      final data = res.data as Map<String, dynamic>;
      final jobs = data['jobs'] as List? ?? [];
      return jobs
          .map((e) => ActiveJob.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Aktif işler yüklenemedi');
    } catch (_) {
      throw ApiException('Aktif işler yüklenemedi');
    }
  }

  Future<List<RecentRequest>> fetchRecentRequests() async {
    try {
      final res = await _api.get(
        '/api/requests',
        queryParameters: {'limit': 5},
      );
      final data = res.data as Map<String, dynamic>;
      final list = data['data'] as List? ?? [];
      return list
          .map((e) => RecentRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Son talepler yüklenemedi');
    } catch (_) {
      throw ApiException('Son talepler yüklenemedi');
    }
  }

  Future<List<RecentBid>> fetchRecentBids() async {
    try {
      final res = await _api.get(
        '/api/customer/bids',
        queryParameters: {'limit': 5},
      );
      final data = res.data as Map<String, dynamic>;
      final list = data['data'] as List? ?? [];
      return list
          .map((e) => RecentBid.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Son teklifler yüklenemedi');
    } catch (_) {
      throw ApiException('Son teklifler yüklenemedi');
    }
  }
}

final customerDashboardRepositoryProvider =
    Provider<CustomerDashboardRepository>((ref) {
      return CustomerDashboardRepository(ref.read(apiClientProvider));
    });
