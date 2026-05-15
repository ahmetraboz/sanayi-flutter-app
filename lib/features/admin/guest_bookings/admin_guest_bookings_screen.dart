import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import 'admin_guest_bookings_notifier.dart';
import '../../../../shared/models/guest_booking_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminGuestBookingsScreen extends ConsumerWidget {
  const AdminGuestBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminGuestBookingsProvider);
    final notifier = ref.read(adminGuestBookingsProvider.notifier);

    timeago.setLocaleMessages('tr', timeago.TrMessages());

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Misafir Rezervasyonları',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
            ),
            if (state.bookings.isNotEmpty)
              Text(
                'Toplam ${state.bookings.length} rezervasyon',
                style: const TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (!state.loading)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.gray600),
              onPressed: () => notifier.load(),
            ),
        ],
      ),
      body: _buildBody(state, notifier),
    );
  }

  Widget _buildBody(AdminGuestBookingsState state, AdminGuestBookingsNotifier notifier) {
    if (state.loading && state.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary600));
    }

    if (state.error != null && state.bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red700),
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(color: AppColors.red700)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => notifier.load(),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (state.bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.gray400),
            SizedBox(height: 16),
            Text('Kayıtlı rezervasyon bulunamadı.', style: TextStyle(color: AppColors.gray600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      color: AppColors.primary600,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final booking = state.bookings[index];
          return _BookingCard(booking: booking);
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final GuestBookingModel booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900),
                ),
              ),
              _StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            booking.description,
            style: const TextStyle(fontSize: 13, color: AppColors.gray600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  booking.name,
                  style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.access_time, size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text(
                timeago.format(booking.createdAt, locale: 'tr'),
                style: const TextStyle(fontSize: 12, color: AppColors.gray500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'pending':
        bg = AppColors.amber50;
        fg = AppColors.amber700;
        label = 'Bekliyor';
        break;
      case 'accepted':
        bg = AppColors.info50;
        fg = AppColors.blue700;
        label = 'Kabul Edildi';
        break;
      case 'completed':
        bg = AppColors.green50;
        fg = AppColors.green700;
        label = 'Tamamlandı';
        break;
      case 'cancelled':
        bg = AppColors.red50;
        fg = AppColors.red700;
        label = 'İptal';
        break;
      default:
        bg = AppColors.gray100;
        fg = AppColors.gray700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
