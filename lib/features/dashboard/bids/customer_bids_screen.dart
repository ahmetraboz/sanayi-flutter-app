import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/date_picker_sheet.dart';
import '../../../shared/widgets/header_actions.dart';
import '../../../shared/widgets/skeleton.dart';
import 'customer_bids_notifier.dart';
import 'models/customer_bid_item.dart';
import 'widgets/bid_filter_pills.dart';

class CustomerBidsScreen extends ConsumerStatefulWidget {
  const CustomerBidsScreen({super.key});

  @override
  ConsumerState<CustomerBidsScreen> createState() => _CustomerBidsScreenState();
}

class _CustomerBidsScreenState extends ConsumerState<CustomerBidsScreen> {
  String? _activeFilter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerBidsProvider);
    final notifier = ref.read(customerBidsProvider.notifier);

    final filteredBids =
        _activeFilter == null
            ? state.bids
            : state.bids.where((b) => b.status == _activeFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gelen Teklifler',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            Text(
              'Taleplerinize gelen teklifleri yönetin',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray500,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: const [
          HeaderActions(),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.gray50,
            child: BidFilterPills(
              activeFilter: _activeFilter,
              onChanged: (val) => setState(() => _activeFilter = val),
            ),
          ),
          Expanded(child: _buildBody(state, notifier, filteredBids)),
        ],
      ),
    );
  }

  Widget _buildBody(
    CustomerBidsState state,
    CustomerBidsNotifier notifier,
    List<CustomerBidItem> filteredBids,
  ) {
    if (state.loading && state.bids.isEmpty) {
      return const _BidListSkeleton();
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
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Henüz teklif yok',
        description:
            'Taleplerinize iş yerlerinden teklif geldiğinde burada görünecektir.',
      );
    }

    if (filteredBids.isEmpty) {
      return _buildEmptyState(
        icon: Icons.filter_alt_outlined,
        title: 'Bu filtrede teklif bulunmuyor',
        description: 'Filtreyi değiştirerek diğer teklifleri görebilirsiniz.',
        action: TextButton(
          onPressed: () => setState(() => _activeFilter = null),
          child: const Text('Tüm teklifleri göster'),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary600,
      onRefresh: notifier.load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredBids.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _BidCard(
            bid: filteredBids[index],
            onAccept: () => _handleAccept(notifier, filteredBids[index].id),
            onReject: () => _handleReject(notifier, filteredBids[index].id),
            onProposeDate: (date) => _handleProposeDate(notifier, filteredBids[index].id, date),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 32, color: AppColors.gray400),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray500,
                height: 1.5,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }

  Future<void> _handleAccept(CustomerBidsNotifier notifier, int bidId) async {
    try {
      await notifier.acceptBid(bidId);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teklif kabul edildi'),
            backgroundColor: AppColors.green700,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.red700,
          ),
        );
    }
  }

  Future<void> _handleReject(CustomerBidsNotifier notifier, int bidId) async {
    try {
      await notifier.rejectBid(bidId);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teklif reddedildi'),
            backgroundColor: AppColors.gray700,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.red700,
          ),
        );
    }
  }

  Future<void> _handleProposeDate(CustomerBidsNotifier notifier, int bidId, String date) async {
    try {
      await notifier.proposeDate(bidId, date);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarih öneriniz gönderildi'),
            backgroundColor: AppColors.green700,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.red700,
          ),
        );
    }
  }
}

class _BidCard extends StatefulWidget {
  final CustomerBidItem bid;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final Future<void> Function(String date) onProposeDate;

  const _BidCard({
    required this.bid,
    required this.onAccept,
    required this.onReject,
    required this.onProposeDate,
  });

  @override
  State<_BidCard> createState() => _BidCardState();
}

class _BidCardState extends State<_BidCard> {
  bool _proposing = false;

  void _openProposeDateSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DatePickerSheet(
        title: 'Farklı Tarih Öner',
        initialDate: widget.bid.proposedDate,
        onSelected: (date) async {
          setState(() => _proposing = true);
          await widget.onProposeDate(date);
          if (mounted) setState(() => _proposing = false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bid = widget.bid;
    final isPending = bid.status == 'pending';
    final isAccepted = bid.status == 'accepted';
    final isRejected = bid.status == 'rejected';

    Color borderColor = AppColors.gray200;
    if (isPending) borderColor = AppColors.amber50;
    if (isAccepted) borderColor = AppColors.emerald200;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isPending
                      ? AppColors.amber50
                      : (isAccepted ? AppColors.green50 : AppColors.gray50),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap:
                        () => context.push(
                          '/dashboard/requests/${bid.requestId}',
                        ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: AppColors.primary600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bid.requestTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(bid.status),
              ],
            ),
          ),

          // Proposed date banner
          if (bid.proposedDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                border: Border(bottom: BorderSide(color: AppColors.emerald200)),
              ),
              child: Row(children: [
                const Icon(Icons.event_available_outlined, size: 16, color: AppColors.green700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Usta bu tarihe uygun: ${formatDateTr(bid.proposedDate)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.green700),
                  ),
                ),
              ]),
            ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        isAccepted
                            ? AppColors.green50
                            : (isRejected
                                ? AppColors.gray100
                                : AppColors.success50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.storefront_outlined,
                    color:
                        isAccepted
                            ? AppColors.green700
                            : (isRejected
                                ? AppColors.gray400
                                : AppColors.primary600),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bid.companyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                      if (bid.description != null &&
                          bid.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          bid.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${bid.price} TL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color:
                            isAccepted
                                ? AppColors.green700
                                : (isRejected
                                    ? AppColors.gray400
                                    : AppColors.primary600),
                        decoration:
                            isRejected ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (bid.estimatedDuration != null &&
                        bid.estimatedDuration!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            bid.estimatedDuration!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Actions
          if (isPending) ...[
            const Divider(height: 1, color: AppColors.gray100),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onReject,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reddet'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gray600,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onAccept,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Kabul Et'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _proposing ? null : _openProposeDateSheet,
                      icon: _proposing
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary600),
                            )
                          : const Icon(Icons.event_outlined, size: 16),
                      label: Text(bid.proposedDate != null ? 'Farklı Tarih Öner' : 'Tarih Öner'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary600,
                        side: const BorderSide(color: AppColors.primary600),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isAccepted) ...[
            const Divider(height: 1, color: AppColors.green50),
            InkWell(
              onTap: () => context.push('/dashboard/requests/${bid.requestId}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Talep detayını görüntüle',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.green700,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg, text;
    String label;
    IconData icon;

    switch (status) {
      case 'accepted':
        bg = AppColors.green50;
        text = AppColors.green700;
        label = 'Kabul Edildi';
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        bg = AppColors.gray100;
        text = AppColors.gray600;
        label = 'Reddedildi';
        icon = Icons.cancel_outlined;
        break;
      case 'pending':
      default:
        bg = AppColors.amber50;
        text = AppColors.amber700;
        label = 'Bekleyen';
        icon = Icons.access_time;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

class _BidListSkeleton extends StatelessWidget {
  const _BidListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonBox(width: 40, height: 40, radius: 10),
                const SizedBox(width: 12),
                const Expanded(child: SkeletonBox(height: 14, radius: 5)),
                const SizedBox(width: 12),
                const SkeletonBox(width: 70, height: 24, radius: 8),
              ],
            ),
            const SizedBox(height: 10),
            const SkeletonBox(height: 12, radius: 4),
            const SizedBox(height: 5),
            const SkeletonBox(height: 12, width: 200, radius: 4),
            const SizedBox(height: 12),
            const Row(
              children: [
                SkeletonBox(width: 80, height: 22, radius: 6),
                SizedBox(width: 8),
                SkeletonBox(width: 70, height: 22, radius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
