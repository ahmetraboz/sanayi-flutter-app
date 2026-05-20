import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../customer/customer_dashboard_notifier.dart';
import '../notifications/notifications_notifier.dart';
import 'models/customer_bid_item.dart';

class CustomerBidsState {
  final bool loading;
  final String? error;
  final List<CustomerBidItem> bids;

  const CustomerBidsState({
    this.loading = false,
    this.error,
    this.bids = const [],
  });

  CustomerBidsState copyWith({
    bool? loading,
    String? error,
    List<CustomerBidItem>? bids,
  }) {
    return CustomerBidsState(
      loading: loading ?? this.loading,
      error: error,
      bids: bids ?? this.bids,
    );
  }
}

class CustomerBidsNotifier extends StateNotifier<CustomerBidsState> {
  final ApiClient _api;
  final Ref _ref;

  CustomerBidsNotifier(this._api, this._ref) : super(const CustomerBidsState()) {
    load();
  }

  void _invalidateStats() {
    _ref.invalidate(customerDashboardProvider);
    _ref.invalidate(notificationsProvider);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.get(
        '/api/customer/bids',
        queryParameters: {'limit': 50},
      );
      final list = res.data['data'] as List? ?? [];

      state = state.copyWith(
        loading: false,
        bids: list.map((e) => CustomerBidItem.fromJson(e)).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e is DioException ? e.message : 'Teklifler yüklenemedi',
      );
    }
  }

  Future<void> acceptBid(int bidId) async {
    try {
      await _api.post('/api/bids/$bidId/accept');
      _invalidateStats();
      await load();
    } catch (e) {
      throw e is DioException ? e.message ?? 'Hata' : 'Teklif kabul edilemedi';
    }
  }

  Future<void> rejectBid(int bidId) async {
    try {
      await _api.post('/api/bids/$bidId/reject');
      _invalidateStats();
      await load();
    } catch (e) {
      throw e is DioException ? e.message ?? 'Hata' : 'Teklif reddedilemedi';
    }
  }

  Future<void> proposeDate(int bidId, String date) async {
    try {
      await _api.post('/api/bids/$bidId/propose-date', data: {'date': date});
      _invalidateStats();
      await load();
    } catch (e) {
      throw e is DioException ? e.message ?? 'Hata' : 'Tarih önerilemedi';
    }
  }
}

final customerBidsProvider =
    StateNotifierProvider.autoDispose<CustomerBidsNotifier, CustomerBidsState>((
      ref,
    ) {
      return CustomerBidsNotifier(ref.read(apiClientProvider), ref);
    });
