import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../../shared/models/notification_model.dart';

class NotificationPollingState {
  final int unreadCount;
  final List<NotificationModel> pendingBanners;

  const NotificationPollingState({
    this.unreadCount = 0,
    this.pendingBanners = const [],
  });

  NotificationPollingState copyWith({
    int? unreadCount,
    List<NotificationModel>? pendingBanners,
  }) {
    return NotificationPollingState(
      unreadCount: unreadCount ?? this.unreadCount,
      pendingBanners: pendingBanners ?? this.pendingBanners,
    );
  }
}

class NotificationPollingNotifier
    extends StateNotifier<NotificationPollingState> {
  final ApiClient _api;
  Timer? _timer;
  int _highWaterMarkId = 0;
  bool _initialized = false;

  NotificationPollingNotifier(this._api)
      : super(const NotificationPollingState()) {
    _poll(isInitial: true);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
  }

  Future<void> _poll({bool isInitial = false}) async {
    if (!mounted) return;
    try {
      final res = await _api.get('/api/notifications',
          queryParameters: {'page': '1', 'limit': '20'});

      if (!mounted) return;

      final data = (res.data['data'] as List? ?? [])
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final unreadCount = data.where((n) => !n.isRead).length;

      if (!_initialized) {
        if (data.isNotEmpty) {
          _highWaterMarkId = data.map((n) => n.id).reduce(max);
        }
        _initialized = true;
        state = state.copyWith(unreadCount: unreadCount);
        return;
      }

      final newNotifs = data
          .where((n) => !n.isRead && n.id > _highWaterMarkId)
          .toList();

      if (newNotifs.isNotEmpty) {
        _highWaterMarkId = newNotifs.map((n) => n.id).reduce(max);
      }

      state = state.copyWith(
        unreadCount: unreadCount,
        pendingBanners: newNotifs.isNotEmpty
            ? [...state.pendingBanners, ...newNotifs]
            : state.pendingBanners,
      );
    } on DioException catch (_) {}
  }

  void consumeBanner() {
    if (state.pendingBanners.isEmpty) return;
    state = state.copyWith(
        pendingBanners: state.pendingBanners.sublist(1));
  }

  Future<void> refresh() => _poll();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final notificationPollingProvider = StateNotifierProvider.autoDispose<
    NotificationPollingNotifier, NotificationPollingState>(
  (ref) => NotificationPollingNotifier(ref.read(apiClientProvider)),
);
