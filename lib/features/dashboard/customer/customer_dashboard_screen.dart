import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/skeleton.dart';
import 'customer_dashboard_notifier.dart';
import 'models/dashboard_models.dart';
import 'widgets/action_banner.dart';
import 'widgets/stat_cards.dart';
import 'widgets/welcome_banner.dart';

class _NewRequestBanner extends StatelessWidget {
  const _NewRequestBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/dashboard/requests/new'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary600, AppColors.primaryTeal],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yeni Talep Oluştur',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Aracınız için servis teklifi alın',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

class CustomerDashboardScreen extends ConsumerWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerDashboardProvider);
    final notifier = ref.read(customerDashboardProvider.notifier);

    if (state.loading && state.stats == null) {
      return const _DashboardSkeleton();
    }

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: RefreshIndicator(
        color: AppColors.primary600,
        onRefresh: notifier.loadAll,
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              backgroundColor: AppColors.gray50,
              floating: true,
              snap: true,
              elevation: 0,
              toolbarHeight: 0,
            ),
            if (state.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.red50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.red100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: AppColors.red700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: const TextStyle(fontSize: 13, color: AppColors.red700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(child: WelcomeBanner()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: _NewRequestBanner()),
            ),
            if (state.stats != null) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: StatCardsGrid(stats: state.stats!),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: ActionBanner(stats: state.stats!),
                ),
              ),
            ],
            if (state.recentRequests.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Son Taleplerim',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gray900),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/dashboard/requests'),
                        child: const Row(
                          children: [
                            Text('Tümü', style: TextStyle(fontSize: 13, color: AppColors.primary600, fontWeight: FontWeight.w500)),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward, size: 14, color: AppColors.primary600),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final req = state.recentRequests[index];
                      return _RecentRequestRow(request: req);
                    },
                    childCount: state.recentRequests.length,
                  ),
                ),
              ),
            ],
            if (state.recentBids.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Son Gelen Teklifler',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gray900),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/dashboard/bids'),
                        child: const Row(
                          children: [
                            Text('Tümü', style: TextStyle(fontSize: 13, color: AppColors.primary600, fontWeight: FontWeight.w500)),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward, size: 14, color: AppColors.primary600),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final bid = state.recentBids[index];
                      return _RecentBidRow(bid: bid);
                    },
                    childCount: state.recentBids.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ─── Recent Request Row ───────────────────────────────────────────────────────

class _RecentRequestRow extends StatelessWidget {
  final RecentRequest request;
  const _RecentRequestRow({required this.request});

  static const _statusLabels = {
    'open': 'Açık',
    'bidding': 'Teklifte',
    'info_requested': 'Bilgi Bekleniyor',
    'info_provided': 'Bilgi Gönderildi',
    'accepted': 'Kabul Edildi',
    'in_progress': 'Devam Ediyor',
    'pending_review': 'İncelemede',
    'completed': 'Tamamlandı',
    'cancelled': 'İptal Edildi',
    'rejected': 'Reddedildi',
  };

  static const _statusColors = {
    'open': Color(0xFF16A34A),
    'bidding': Color(0xFF7C3AED),
    'info_requested': Color(0xFFD97706),
    'info_provided': Color(0xFF0891B2),
    'accepted': Color(0xFF059669),
    'in_progress': Color(0xFF2563EB),
    'pending_review': Color(0xFFD97706),
    'completed': Color(0xFF16A34A),
    'cancelled': Color(0xFF6B7280),
    'rejected': Color(0xFFEF4444),
  };

  static const _statusBgColors = {
    'open': Color(0xFFF0FDF4),
    'bidding': Color(0xFFF5F3FF),
    'info_requested': Color(0xFFFEF3C7),
    'info_provided': Color(0xFFECFEFF),
    'accepted': Color(0xFFECFDF5),
    'in_progress': Color(0xFFEFF6FF),
    'pending_review': Color(0xFFFEF3C7),
    'completed': Color(0xFFF0FDF4),
    'cancelled': Color(0xFFF3F4F6),
    'rejected': Color(0xFFFEE2E2),
  };

  @override
  Widget build(BuildContext context) {
    final label = _statusLabels[request.status] ?? request.status;
    final color = _statusColors[request.status] ?? AppColors.gray500;
    final bg = _statusBgColors[request.status] ?? AppColors.gray100;
    final dateStr = DateFormat('d MMM', 'tr').format(request.createdAt);

    return GestureDetector(
      onTap: () => context.push('/dashboard/requests/${request.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.build_outlined, size: 18, color: AppColors.gray500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${request.vehicleBrand} ${request.vehicleModel} · $dateStr',
                    style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
              child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent Bid Row ───────────────────────────────────────────────────────────

class _RecentBidRow extends StatelessWidget {
  final RecentBid bid;
  const _RecentBidRow({required this.bid});

  static const _statusLabels = {
    'pending':   'Beklemede',
    'quoted':    'Beklemede',
    'accepted':  'Kabul Edildi',
    'rejected':  'Reddedildi',
    'countered': 'Karşı Teklif',
    'expired':   'Süresi Doldu',
  };

  static const _statusColors = {
    'pending':   Color(0xFFD97706),
    'quoted':    Color(0xFFD97706),
    'accepted':  Color(0xFF059669),
    'rejected':  Color(0xFFDC2626),
    'countered': Color(0xFF7C3AED),
    'expired':   Color(0xFF6B7280),
  };

  static const _statusBgColors = {
    'pending':   Color(0xFFFEF3C7),
    'quoted':    Color(0xFFFEF3C7),
    'accepted':  Color(0xFFECFDF5),
    'rejected':  Color(0xFFFEE2E2),
    'countered': Color(0xFFF5F3FF),
    'expired':   Color(0xFFF3F4F6),
  };

  @override
  Widget build(BuildContext context) {
    final priceStr = bid.price != null
        ? '${NumberFormat('#,##0', 'tr').format(bid.price)} ₺'
        : '-';
    final label   = _statusLabels[bid.status]   ?? bid.status;
    final color   = _statusColors[bid.status]   ?? AppColors.gray500;
    final bgColor = _statusBgColors[bid.status] ?? AppColors.gray100;

    return GestureDetector(
      onTap: () => context.push('/dashboard/requests/${bid.requestId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront_outlined, size: 18, color: AppColors.gray500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bid.serviceCompanyName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    bid.requestTitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  priceStr,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray900),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: const [
                  Expanded(child: _StatCardSkeleton()),
                  SizedBox(width: 10),
                  Expanded(child: _StatCardSkeleton()),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Expanded(child: _StatCardSkeleton()),
                  SizedBox(width: 10),
                  Expanded(child: _StatCardSkeleton()),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 24),
              const SkeletonBox(height: 16, width: 130, radius: 5),
              const SizedBox(height: 12),
              ...List.generate(3, (_) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Row(
                  children: [
                    SkeletonBox(width: 40, height: 40, radius: 10),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(height: 13, radius: 4),
                          SizedBox(height: 6),
                          SkeletonBox(height: 11, width: 140, radius: 4),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    SkeletonBox(width: 55, height: 22, radius: 6),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 28, height: 28, radius: 8),
          SizedBox(height: 10),
          SkeletonBox(height: 18, width: 30, radius: 4),
          SizedBox(height: 5),
          SkeletonBox(height: 11, radius: 3),
        ],
      ),
    );
  }
}
