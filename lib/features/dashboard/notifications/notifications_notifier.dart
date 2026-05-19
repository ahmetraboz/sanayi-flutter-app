import 'dart:async';
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
  Timer? _pollTimer;

  NotificationsNotifier(this._api) : super(const NotificationsState()) {
    load();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final list = await _api.getNotifications();
      if (mounted) state = state.copyWith(notifications: list);
    } catch (_) {}
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final list = await _api.getNotifications();
      state = state.copyWith(loading: false, notifications: list);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> markAsRead(int id) async {
    try {
      await _api.markAsRead(id);
      final newList = state.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
      state = state.copyWith(notifications: newList);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.markAllAsRead();
      final newList = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: newList);
    } catch (_) {}
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

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref.read(notificationApiProvider));
});
