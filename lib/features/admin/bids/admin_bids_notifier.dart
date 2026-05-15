import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/services/admin_api_service.dart';
import '../../../../shared/models/bid_model.dart';

class AdminBidsState {
  final bool loading;
  final String? error;
  final List<BidModel> bids;

  const AdminBidsState({
    this.loading = false,
    this.error,
    this.bids = const [],
  });

  AdminBidsState copyWith({
    bool? loading,
    String? error,
    List<BidModel>? bids,
    bool clearError = false,
  }) {
    return AdminBidsState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      bids: bids ?? this.bids,
    );
  }
}

class AdminBidsNotifier extends StateNotifier<AdminBidsState> {
  final AdminApiService _api;

  AdminBidsNotifier(this._api) : super(const AdminBidsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final bids = await _api.getBids();
      state = state.copyWith(loading: false, bids: bids);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final adminBidsProvider = StateNotifierProvider.autoDispose<AdminBidsNotifier, AdminBidsState>((ref) {
  return AdminBidsNotifier(ref.read(adminApiProvider));
});
