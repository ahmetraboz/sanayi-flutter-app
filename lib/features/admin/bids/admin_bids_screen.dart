import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import 'admin_bids_notifier.dart';
import '../../../../shared/models/bid_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminBidsScreen extends ConsumerWidget {
  const AdminBidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminBidsProvider);
    final notifier = ref.read(adminBidsProvider.notifier);

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
              'Teklifler',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
            ),
            if (state.bids.isNotEmpty)
              Text(
                'Toplam ${state.bids.length} teklif',
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

  Widget _buildBody(AdminBidsState state, AdminBidsNotifier notifier) {
    if (state.loading && state.bids.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary600));
    }

    if (state.error != null && state.bids.isEmpty) {
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

    if (state.bids.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.price_check_outlined, size: 48, color: AppColors.gray400),
            SizedBox(height: 16),
            Text('Kayıtlı teklif bulunamadı.', style: TextStyle(color: AppColors.gray600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      color: AppColors.primary600,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.bids.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final bid = state.bids[index];
          return _BidCard(bid: bid);
        },
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  final BidModel bid;

  const _BidCard({required this.bid});

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
                  '₺${bid.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary700),
                ),
              ),
              _StatusBadge(status: bid.status),
            ],
          ),
          const SizedBox(height: 8),
          if (bid.description.isNotEmpty) ...[
            Text(
              bid.description,
              style: const TextStyle(fontSize: 13, color: AppColors.gray600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              const Icon(Icons.build_circle_outlined, size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  bid.companyName ?? bid.providerName ?? 'Bilinmeyen Sağlayıcı',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.access_time, size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text(
                timeago.format(bid.createdAt, locale: 'tr'),
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
        bg = AppColors.green50;
        fg = AppColors.green700;
        label = 'Kabul Edildi';
        break;
      case 'rejected':
        bg = AppColors.red50;
        fg = AppColors.red700;
        label = 'Reddedildi';
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
