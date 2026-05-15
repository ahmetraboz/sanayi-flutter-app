import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/services/admin_api_service.dart';
import '../../../../shared/models/guest_booking_model.dart';

class AdminGuestBookingsState {
  final bool loading;
  final String? error;
  final List<GuestBookingModel> bookings;

  const AdminGuestBookingsState({
    this.loading = false,
    this.error,
    this.bookings = const [],
  });

  AdminGuestBookingsState copyWith({
    bool? loading,
    String? error,
    List<GuestBookingModel>? bookings,
    bool clearError = false,
  }) {
    return AdminGuestBookingsState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      bookings: bookings ?? this.bookings,
    );
  }
}

class AdminGuestBookingsNotifier extends StateNotifier<AdminGuestBookingsState> {
  final AdminApiService _api;

  AdminGuestBookingsNotifier(this._api) : super(const AdminGuestBookingsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final bookings = await _api.getGuestBookings();
      state = state.copyWith(loading: false, bookings: bookings);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final adminGuestBookingsProvider = StateNotifierProvider.autoDispose<AdminGuestBookingsNotifier, AdminGuestBookingsState>((ref) {
  return AdminGuestBookingsNotifier(ref.read(adminApiProvider));
});
