import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import 'models/guest_tracking_models.dart';

const _sentinel = Object();

class GuestTrackingState {
  final bool loading;
  final String? error;
  final GuestBookingTracking? booking;
  final bool responding;
  final String? respondError;
  final bool submittingReview;
  final bool reviewSubmitted;
  final String? reviewError;

  const GuestTrackingState({
    this.loading = false,
    this.error,
    this.booking,
    this.responding = false,
    this.respondError,
    this.submittingReview = false,
    this.reviewSubmitted = false,
    this.reviewError,
  });

  GuestTrackingState copyWith({
    bool? loading,
    Object? error = _sentinel,
    Object? booking = _sentinel,
    bool? responding,
    Object? respondError = _sentinel,
    bool? submittingReview,
    bool? reviewSubmitted,
    Object? reviewError = _sentinel,
  }) {
    return GuestTrackingState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      booking: identical(booking, _sentinel) ? this.booking : booking as GuestBookingTracking?,
      responding: responding ?? this.responding,
      respondError: identical(respondError, _sentinel) ? this.respondError : respondError as String?,
      submittingReview: submittingReview ?? this.submittingReview,
      reviewSubmitted: reviewSubmitted ?? this.reviewSubmitted,
      reviewError: identical(reviewError, _sentinel) ? this.reviewError : reviewError as String?,
    );
  }
}

class GuestTrackingNotifier extends StateNotifier<GuestTrackingState> {
  final ApiClient _api;
  final String token;

  GuestTrackingNotifier(this._api, this.token) : super(const GuestTrackingState());

  Future<void> loadBooking({String? name, String? code}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final params = <String, dynamic>{};
      if (name != null && name.isNotEmpty) params['name'] = name;
      if (code != null && code.isNotEmpty) params['code'] = code;

      final res = await _api.get('/api/guest/booking/$token', queryParameters: params);
      final data = res.data as Map<String, dynamic>;
      final booking = GuestBookingTracking.fromJson(data['booking'] as Map<String, dynamic>);
      state = state.copyWith(loading: false, booking: booking);
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: e.message ?? 'Talep bulunamadı');
    }
  }

  Future<void> respondToQuote(int responseId, String action) async {
    state = state.copyWith(responding: true, respondError: null);
    try {
      await _api.post(
        '/api/guest/booking/$token/respond',
        data: {'responseId': responseId, 'action': action},
      );
      state = state.copyWith(responding: false);
      // Re-fetch with stored params — pass empty to reload without name/code
      await loadBooking();
    } on DioException catch (e) {
      state = state.copyWith(
        responding: false,
        respondError: e.message ?? 'İşlem gerçekleştirilemedi',
      );
    }
  }

  Future<void> submitReview({required int rating, required String comment}) async {
    state = state.copyWith(submittingReview: true, reviewError: null);
    try {
      await _api.post(
        '/api/guest/booking/$token/review',
        data: {'rating': rating, 'comment': comment},
      );
      state = state.copyWith(submittingReview: false, reviewSubmitted: true);
    } on DioException catch (e) {
      state = state.copyWith(
        submittingReview: false,
        reviewError: e.message ?? 'Değerlendirme gönderilemedi',
      );
    }
  }
}

final guestTrackingProvider = StateNotifierProvider.autoDispose
    .family<GuestTrackingNotifier, GuestTrackingState, String>((ref, token) {
  return GuestTrackingNotifier(ref.read(apiClientProvider), token);
});
