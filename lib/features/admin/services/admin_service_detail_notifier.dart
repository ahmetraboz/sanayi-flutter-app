import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/services/admin_api_service.dart';

class AdminServiceDetailState {
  final bool loading;
  final String? error;
  final Map<String, dynamic>? profile;
  final List<dynamic> reviews;
  final List<dynamic> bids;
  final List<dynamic> requests;
  final bool updating;
  final String? updateError;
  final String? updateSuccess;

  const AdminServiceDetailState({
    this.loading = true,
    this.error,
    this.profile,
    this.reviews = const [],
    this.bids = const [],
    this.requests = const [],
    this.updating = false,
    this.updateError,
    this.updateSuccess,
  });

  AdminServiceDetailState copyWith({
    bool? loading,
    Object? error = _sentinel,
    Object? profile = _sentinel,
    List<dynamic>? reviews,
    List<dynamic>? bids,
    List<dynamic>? requests,
    bool? updating,
    Object? updateError = _sentinel,
    Object? updateSuccess = _sentinel,
  }) {
    return AdminServiceDetailState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      profile: identical(profile, _sentinel) ? this.profile : profile as Map<String, dynamic>?,
      reviews: reviews ?? this.reviews,
      bids: bids ?? this.bids,
      requests: requests ?? this.requests,
      updating: updating ?? this.updating,
      updateError: identical(updateError, _sentinel) ? this.updateError : updateError as String?,
      updateSuccess: identical(updateSuccess, _sentinel) ? this.updateSuccess : updateSuccess as String?,
    );
  }
}

const _sentinel = Object();

class AdminServiceDetailNotifier extends StateNotifier<AdminServiceDetailState> {
  final AdminApiService _api;
  final int serviceId;

  AdminServiceDetailNotifier(this._api, this.serviceId)
      : super(const AdminServiceDetailState()) {
    loadDetail();
  }

  Future<void> loadDetail() async {
    state = state.copyWith(loading: true, error: null, updateError: null, updateSuccess: null);
    try {
      final data = await _api.getServiceDetail(serviceId);
      state = state.copyWith(
        loading: false,
        profile: data['profile'] as Map<String, dynamic>?,
        reviews: (data['reviews'] as List?) ?? [],
        bids: (data['bids'] as List?) ?? [],
        requests: (data['requests'] as List?) ?? [],
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Servis detayı yüklenemedi.');
    }
  }

  Future<bool> updateStatus(String newStatus) async {
    state = state.copyWith(updating: true, updateError: null, updateSuccess: null);
    try {
      await _api.updateServiceStatus(serviceId, newStatus);
      final label = newStatus == 'approved' ? 'onaylandı' : 'reddedildi';
      state = state.copyWith(updating: false, updateSuccess: 'Servis $label.');
      await loadDetail();
      return true;
    } catch (e) {
      state = state.copyWith(updating: false, updateError: 'İşlem başarısız oldu. Lütfen tekrar deneyin.');
      return false;
    }
  }
}

final adminServiceDetailProvider = StateNotifierProvider.family<
    AdminServiceDetailNotifier, AdminServiceDetailState, int>((ref, id) {
  return AdminServiceDetailNotifier(ref.watch(adminApiProvider), id);
});
