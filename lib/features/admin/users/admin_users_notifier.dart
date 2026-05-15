import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/services/admin_api_service.dart';
import '../../../../shared/models/user_model.dart';

class AdminUsersState {
  final bool loading;
  final String? error;
  final List<UserModel> users;
  final int? deletingId;

  const AdminUsersState({
    this.loading = false,
    this.error,
    this.users = const [],
    this.deletingId,
  });

  AdminUsersState copyWith({
    bool? loading,
    String? error,
    List<UserModel>? users,
    Object? deletingId = _unset,
    bool clearError = false,
  }) {
    return AdminUsersState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      users: users ?? this.users,
      deletingId: identical(deletingId, _unset) ? this.deletingId : deletingId as int?,
    );
  }
}

const _unset = Object();

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final AdminApiService _api;

  AdminUsersNotifier(this._api) : super(const AdminUsersState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final users = await _api.getUsers();
      state = state.copyWith(loading: false, users: users);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> deleteUser(int id) async {
    state = state.copyWith(deletingId: id);
    try {
      await _api.deleteUser(id);
      state = state.copyWith(
        deletingId: null,
        users: state.users.where((u) => u.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(deletingId: null, error: e.toString());
      return false;
    }
  }
}

final adminUsersProvider = StateNotifierProvider.autoDispose<AdminUsersNotifier, AdminUsersState>((ref) {
  return AdminUsersNotifier(ref.read(adminApiProvider));
});
