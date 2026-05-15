import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/services/admin_api_service.dart';

class AdminReviewsState {
  final bool loading;
  final String? error;
  final List<dynamic> reviews;

  const AdminReviewsState({
    this.loading = false,
    this.error,
    this.reviews = const [],
  });

  AdminReviewsState copyWith({
    bool? loading,
    String? error,
    List<dynamic>? reviews,
    bool clearError = false,
  }) {
    return AdminReviewsState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      reviews: reviews ?? this.reviews,
    );
  }
}

class AdminReviewsNotifier extends StateNotifier<AdminReviewsState> {
  final AdminApiService _api;

  AdminReviewsNotifier(this._api) : super(const AdminReviewsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final reviews = await _api.getReviews();
      state = state.copyWith(loading: false, reviews: reviews);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final adminReviewsProvider = StateNotifierProvider.autoDispose<AdminReviewsNotifier, AdminReviewsState>((ref) {
  return AdminReviewsNotifier(ref.read(adminApiProvider));
});
