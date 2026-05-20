import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../customer/customer_dashboard_notifier.dart';
import '../notifications/notifications_notifier.dart';
import '../bids/customer_bids_notifier.dart';
import 'models/request_detail.dart';

const _sentinel = Object();

class RequestDetailState {
  final bool loading;
  final String? error;
  final RequestDetail? request;
  final List<BidItem> bids;
  final List<JobUpdate> updates;
  final bool accepting;
  final String? acceptError;
  final int? acceptedBidId;
  final bool rejecting;
  final String? rejectError;
  final InfoRequestData? infoRequest;
  final bool submittingInfo;
  final bool rejectingInfo;
  final bool completing;
  final bool reviewing;
  final bool cancelling;
  final String? actionError;

  const RequestDetailState({
    this.loading = false,
    this.error,
    this.request,
    this.bids = const [],
    this.updates = const [],
    this.infoRequest,
    this.accepting = false,
    this.acceptError,
    this.acceptedBidId,
    this.rejecting = false,
    this.rejectError,
    this.submittingInfo = false,
    this.rejectingInfo = false,
    this.completing = false,
    this.reviewing = false,
    this.cancelling = false,
    this.actionError,
  });

  String? get status => request?.status;
  bool get isInfoRequested => status == 'info_requested';
  bool get canComplete => status == 'accepted' || status == 'in_progress';
  bool get isPendingReview => status == 'pending_review';
  bool get canCancel => status != null && status != 'cancelled' && status != 'completed' && status != 'rejected';

  JobUpdate? get completionUpdate {
    try {
      return updates.lastWhere(
        (u) => u.updateType == 'completion' && u.hasInvoice,
      );
    } catch (_) {
      return null;
    }
  }

  RequestDetailState copyWith({
    bool? loading,
    Object? error = _sentinel,
    Object? request = _sentinel,
    List<BidItem>? bids,
    List<JobUpdate>? updates,
    bool? accepting,
    Object? acceptError = _sentinel,
    Object? acceptedBidId = _sentinel,
    bool? rejecting,
    Object? rejectError = _sentinel,
    Object? infoRequest = _sentinel,
    bool? submittingInfo,
    bool? rejectingInfo,
    bool? completing,
    bool? reviewing,
    bool? cancelling,
    Object? actionError = _sentinel,
  }) {
    return RequestDetailState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      request: identical(request, _sentinel) ? this.request : request as RequestDetail?,
      bids: bids ?? this.bids,
      updates: updates ?? this.updates,
      infoRequest: identical(infoRequest, _sentinel) ? this.infoRequest : infoRequest as InfoRequestData?,
      accepting: accepting ?? this.accepting,
      acceptError: identical(acceptError, _sentinel) ? this.acceptError : acceptError as String?,
      acceptedBidId: identical(acceptedBidId, _sentinel) ? this.acceptedBidId : acceptedBidId as int?,
      rejecting: rejecting ?? this.rejecting,
      rejectError: identical(rejectError, _sentinel) ? this.rejectError : rejectError as String?,
      submittingInfo: submittingInfo ?? this.submittingInfo,
      rejectingInfo: rejectingInfo ?? this.rejectingInfo,
      completing: completing ?? this.completing,
      reviewing: reviewing ?? this.reviewing,
      cancelling: cancelling ?? this.cancelling,
      actionError: identical(actionError, _sentinel) ? this.actionError : actionError as String?,
    );
  }
}

class RequestDetailNotifier extends StateNotifier<RequestDetailState> {
  final ApiClient _api;
  final int requestId;
  final Ref _ref;

  RequestDetailNotifier(this._api, this.requestId, this._ref)
    : super(const RequestDetailState()) {
    loadDetail();
  }

  void _invalidateStats() {
    _ref.invalidate(customerDashboardProvider);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(customerBidsProvider);
  }

  Future<void> loadDetail() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.get('/api/requests/$requestId');
      final data = res.data as Map<String, dynamic>;
      final detail = RequestDetail.fromJson(
        data['request'] as Map<String, dynamic>,
      );
      final bids =
          (data['bids'] as List? ?? [])
              .map((e) => BidItem.fromJson(e as Map<String, dynamic>))
              .toList();
      final infoRequestRaw = data['infoRequest'] as Map<String, dynamic>?;
      final infoRequest = infoRequestRaw != null ? InfoRequestData.fromJson(infoRequestRaw) : null;
      final updates = (data['updates'] as List? ?? [])
          .map((e) => JobUpdate.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        loading: false,
        request: detail,
        bids: bids,
        updates: updates,
        infoRequest: infoRequest,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.message ?? 'Talep yüklenemedi',
      );
    }
  }

  Future<bool> acceptBid(int bidId) async {
    state = state.copyWith(accepting: true, acceptError: null);
    try {
      await _api.post('/api/bids/$bidId/accept');
      state = state.copyWith(accepting: false, acceptedBidId: bidId);
      _invalidateStats();
      await loadDetail();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        accepting: false,
        acceptError: e.message ?? 'Teklif kabul edilemedi',
      );
      return false;
    }
  }

  Future<bool> rejectBid(int bidId) async {
    state = state.copyWith(rejecting: true, rejectError: null);
    try {
      await _api.post('/api/bids/$bidId/reject');
      state = state.copyWith(rejecting: false);
      _invalidateStats();
      await loadDetail();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        rejecting: false,
        rejectError: e.message ?? 'Teklif reddedilemedi',
      );
      return false;
    }
  }

  Future<bool> submitInfo(Map<String, dynamic> data) async {
    state = state.copyWith(submittingInfo: true, actionError: null);
    try {
      await _api.post('/api/requests/$requestId/submit-info', data: data);
      state = state.copyWith(submittingInfo: false);
      _invalidateStats();
      await loadDetail();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(submittingInfo: false, actionError: e.message ?? 'Bilgi gönderilemedi');
      return false;
    }
  }

  Future<bool> rejectInfo() async {
    state = state.copyWith(rejectingInfo: true, actionError: null);
    try {
      await _api.post('/api/requests/$requestId/reject-info');
      state = state.copyWith(rejectingInfo: false);
      _invalidateStats();
      await loadDetail();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(rejectingInfo: false, actionError: e.message ?? 'İşlem başarısız');
      return false;
    }
  }

  Future<bool> completeRequest() async {
    state = state.copyWith(completing: true, actionError: null);
    try {
      await _api.post('/api/requests/$requestId/complete');
      state = state.copyWith(completing: false);
      _invalidateStats();
      await loadDetail();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(completing: false, actionError: e.message ?? 'İşlem başarısız');
      return false;
    }
  }

  Future<bool> cancelRequest() async {
    state = state.copyWith(cancelling: true, actionError: null);
    try {
      await _api.post('/api/requests/$requestId/cancel');
      state = state.copyWith(cancelling: false);
      _invalidateStats();
      await loadDetail();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(cancelling: false, actionError: e.message ?? 'Talep iptal edilemedi');
      return false;
    }
  }

  Future<bool> submitReview({required int rating, String? comment}) async {
    state = state.copyWith(reviewing: true, actionError: null);
    try {
      await _api.post('/api/requests/$requestId/review', data: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
      state = state.copyWith(reviewing: false);
      _invalidateStats();
      await loadDetail();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(reviewing: false, actionError: e.message ?? 'Değerlendirme gönderilemedi');
      return false;
    }
  }
}

final requestDetailProvider = StateNotifierProvider.autoDispose
    .family<RequestDetailNotifier, RequestDetailState, int>((ref, id) {
      return RequestDetailNotifier(ref.read(apiClientProvider), id, ref);
    });
