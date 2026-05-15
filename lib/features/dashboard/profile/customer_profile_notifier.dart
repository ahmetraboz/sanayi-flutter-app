import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_notifier.dart';

class CustomerProfileNotifier extends StateNotifier<bool> {
  final ApiClient _api;
  final Ref _ref;

  CustomerProfileNotifier(this._api, this._ref) : super(false);

  Future<void> updateProfile({required String name, String? phone}) async {
    state = true;
    try {
      await _api.put(
        '/api/profile',
        data: {
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      // Invalidate the auth provider so it fetches the new user info on next read
      _ref.invalidate(authNotifierProvider);
    } catch (e) {
      throw e is DioException ? e.message ?? 'Hata' : 'Profil güncellenemedi';
    } finally {
      state = false;
    }
  }
}

final customerProfileProvider =
    StateNotifierProvider.autoDispose<CustomerProfileNotifier, bool>((ref) {
      return CustomerProfileNotifier(ref.read(apiClientProvider), ref);
    });
