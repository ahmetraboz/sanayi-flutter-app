import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/services/notification_api_service.dart';
import '../../../../shared/models/notification_model.dart';

class NotificationsState {
  final bool loading;
  final String? error;
  final List<NotificationModel> notifications;

  const NotificationsState({
    this.loading = false,
    this.error,
    this.notifications = const [],
  });

  NotificationsState copyWith({
    bool? loading,
    String? error,
    List<NotificationModel>? notifications,
    bool clearError = false,
  }) {
    return NotificationsState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      notifications: notifications ?? this.notifications,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationApiService _api;

  NotificationsNotifier(this._api) : super(const NotificationsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final list = await _api.getNotifications();
      state = state.copyWith(loading: false, notifications: list);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _api.markAsRead(id);
      final newList = state.notifications.map((n) {
        if (n.id == id) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      state = state.copyWith(notifications: newList);
    } catch (e) {
      // Handle error implicitly or show message
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.markAllAsRead();
      final newList = state.notifications.map((n) {
        return NotificationModel(
          id: n.id,
          userId: n.userId,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      state = state.copyWith(notifications: newList);
    } catch (e) {
      // Handle error implicitly or show message
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      await _api.deleteNotification(id);
      final newList = state.notifications.where((n) => n.id != id).toList();
      state = state.copyWith(notifications: newList);
    } catch (e) {
      throw Exception('Bildirim silinemedi');
    }
  }
}

final notificationsProvider = StateNotifierProvider.autoDispose<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref.read(notificationApiProvider));
});
