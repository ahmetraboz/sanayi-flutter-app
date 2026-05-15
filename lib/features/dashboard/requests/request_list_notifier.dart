import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/provider_model.dart';
import 'models/request_item.dart';

const _sentinel = Object();

class RequestListState {
  final List<RequestItem> requests;
  final bool loading;
  final String? error;
  final String? activeFilter;
  final int currentPage;
  final int totalPages;
  final int total;

  const RequestListState({
    this.requests = const [],
    this.loading = false,
    this.error,
    this.activeFilter,
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
  });

  RequestListState copyWith({
    List<RequestItem>? requests,
    bool? loading,
    Object? error = _sentinel,
    Object? activeFilter = _sentinel,
    int? currentPage,
    int? totalPages,
    int? total,
  }) {
    return RequestListState(
      requests: requests ?? this.requests,
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      activeFilter:
          identical(activeFilter, _sentinel)
              ? this.activeFilter
              : activeFilter as String?,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
    );
  }
}

class RequestListNotifier extends StateNotifier<RequestListState> {
  final ApiClient _api;

  RequestListNotifier(this._api) : super(const RequestListState()) {
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final params = <String, dynamic>{'page': state.currentPage, 'limit': 10};
      if (state.activeFilter != null) params['status'] = state.activeFilter;

      final res = await _api.get('/api/requests', queryParameters: params);
      final data = res.data as Map<String, dynamic>;

      final items =
          (data['data'] as List? ?? [])
              .map((e) => RequestItem.fromJson(e as Map<String, dynamic>))
              .toList();
      final pagination = Pagination.fromJson(
        data['pagination'] as Map<String, dynamic>,
      );

      state = state.copyWith(
        loading: false,
        requests: items,
        currentPage: pagination.page,
        totalPages: pagination.totalPages,
        total: pagination.total,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.message ?? 'Talepler yüklenemedi',
      );
    }
  }

  void onFilterChanged(String? status) {
    state = state.copyWith(activeFilter: status, currentPage: 1);
    fetchRequests();
  }

  void nextPage() {
    if (state.currentPage < state.totalPages) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      fetchRequests();
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
      fetchRequests();
    }
  }
}

final requestListProvider =
    StateNotifierProvider.autoDispose<RequestListNotifier, RequestListState>((
      ref,
    ) {
      return RequestListNotifier(ref.read(apiClientProvider));
    });
