import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_notifier.dart';

class ProfileState {
  final bool isSavingProfile;
  final bool isUploadingAvatar;
  final bool isChangingPassword;

  const ProfileState({
    this.isSavingProfile = false,
    this.isUploadingAvatar = false,
    this.isChangingPassword = false,
  });

  ProfileState copyWith({
    bool? isSavingProfile,
    bool? isUploadingAvatar,
    bool? isChangingPassword,
  }) => ProfileState(
    isSavingProfile: isSavingProfile ?? this.isSavingProfile,
    isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
    isChangingPassword: isChangingPassword ?? this.isChangingPassword,
  );
}

class CustomerProfileNotifier extends StateNotifier<ProfileState> {
  final ApiClient _api;
  final Ref _ref;

  CustomerProfileNotifier(this._api, this._ref) : super(const ProfileState());

  Future<void> updateProfile({required String name, String? phone}) async {
    state = state.copyWith(isSavingProfile: true);
    try {
      await _api.put(
        '/api/profile',
        data: {
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      _ref.invalidate(authNotifierProvider);
    } catch (e) {
      throw e is DioException ? e.message ?? 'Hata' : 'Profil güncellenemedi';
    } finally {
      state = state.copyWith(isSavingProfile: false);
    }
  }

  Future<void> uploadAvatar(XFile file) async {
    state = state.copyWith(isUploadingAvatar: true);
    try {
      final bytes = await file.readAsBytes();
      // image_picker imageQuality ile aldığında çıktı her zaman JPEG bytes olur
      // (iOS HEIC dahil). MIME ve filename'i zorla JPEG yapıyoruz.
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'avatar.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });
      final res = await _api.postFormData('/api/upload', formData);
      final url = res.data['url'] as String;
      final currentUser = _ref.read(authNotifierProvider).valueOrNull;
      await _api.put('/api/profile', data: {
        'name': currentUser?.name ?? '',
        if (currentUser?.phone != null) 'phone': currentUser!.phone,
        'avatarUrl': url,
      });
      _ref.invalidate(authNotifierProvider);
    } catch (e) {
      throw e is DioException ? e.message ?? 'Hata' : 'Fotoğraf yüklenemedi';
    } finally {
      state = state.copyWith(isUploadingAvatar: false);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isChangingPassword: true);
    try {
      await _api.put(
        '/api/profile/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      throw e is DioException ? e.message ?? 'Hata' : 'Şifre değiştirilemedi';
    } finally {
      state = state.copyWith(isChangingPassword: false);
    }
  }
}

final customerProfileProvider =
    StateNotifierProvider.autoDispose<CustomerProfileNotifier, ProfileState>((ref) {
      return CustomerProfileNotifier(ref.read(apiClientProvider), ref);
    });
