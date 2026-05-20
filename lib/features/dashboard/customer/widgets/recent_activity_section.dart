import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../models/dashboard_models.dart';

const _requestStatusLabels = <String, String>{
  'open': 'Açık',
  'accepted': 'Kabul Edildi',
  'in_progress': 'Devam Ediyor',
  'completed': 'Tamamlandı',
  'cancelled': 'İptal',
  'pending_review': 'Değerlendirme',
  'rejected': 'Reddedildi',
};

const _requestStatusColors = <String, Color>{
  'open': Color(0xFF3B82F6),
  'accepted': Color(0xFF059669),
  'in_progress': Color(0xFF2563EB),
  'completed': Color(0xFF6B7280),
  'cancelled': Color(0xFFB91C1C),
  'pending_review': Color(0xFFD97706),
  'rejected': Color(0xFFEF4444),
};

const _requestStatusBgColors = <String, Color>{
  'open': Color(0xFFEFF6FF),
  'accepted': Color(0xFFECFDF5),
  'in_progress': Color(0xFFEFF6FF),
  'completed': Color(0xFFF3F4F6),
  'cancelled': Color(0xFFFEF2F2),
  'pending_review': Color(0xFFFEF3C7),
  'rejected': Color(0xFFFEE2E2),
};

const _bidStatusLabels = <String, String>{
  'pending': 'Beklemede',
  'accepted': 'Kabul Edildi',
  'rejected': 'Reddedildi',
  'countered': 'Karşı Teklif',
};

const _bidStatusColors = <String, Color>{
  'pending': Color(0xFFD97706),
  'accepted': Color(0xFF059669),
  'rejected': Color(0xFFB91C1C),
  'countered': Color(0xFF7C3AED),
};

const _bidStatusBgColors = <String, Color>{
  'pending': Color(0xFFFEF3C7),
  'accepted': Color(0xFFECFDF5),
  'rejected': Color(0xFFFEF2F2),
  'countered': Color(0xFFF5F3FF),
};

// ── Recent Requests ─────────────────────────────────────────────────────────

class RecentActivitySection extends StatelessWidget {
  final List<RecentRequest> requests;

  const RecentActivitySection({super.key, required this.requests});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          if (requests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      size: 24,
                      color: AppColors.gray300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Henüz talep oluşturmadınız',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.gray500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.push('/dashboard/requests/new'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'İlk Talebini Oluştur',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder:
                  (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.gray100,
                  ),
              itemBuilder: (_, i) => _RequestRow(request: requests[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Icons.build_outlined,
            size: 16,
            color: AppColors.primary600,
          ),
          const SizedBox(width: 8),
          const Text(
            'Son Taleplerim',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/dashboard/requests'),
            child: const Text(
              'Tümü',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  final RecentRequest request;

  const _RequestRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final label = _requestStatusLabels[request.status] ?? request.status;
    final color = _requestStatusColors[request.status] ?? AppColors.gray500;
    final bgColor = _requestStatusBgColors[request.status] ?? AppColors.gray100;

    return InkWell(
      onTap: () => context.push('/dashboard/requests/${request.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  request.imageUrl != null && request.imageUrl!.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          request.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Icon(
                                Icons.description_outlined,
                                size: 18,
                                color: color,
                              ),
                        ),
                      )
                      : Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: color,
                      ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${request.vehicleBrand} ${request.vehicleModel}'.trim(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.gray300),
          ],
        ),
      ),
    );
  }
}

// ── Recent Bids ──────────────────────────────────────────────────────────────

class RecentBidsSection extends StatelessWidget {
  final List<RecentBid> bids;

  const RecentBidsSection({super.key, required this.bids});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          if (bids.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.inbox_outlined,
                      size: 24,
                      color: AppColors.gray300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Henüz gelen teklif yok',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.gray500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bids.length,
              separatorBuilder:
                  (_, __) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.gray100,
                  ),
              itemBuilder: (_, i) => _BidRow(bid: bids[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Icons.move_to_inbox_outlined,
            size: 16,
            color: AppColors.primary600,
          ),
          const SizedBox(width: 8),
          const Text(
            'Son Gelen Teklifler',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/dashboard/bids'),
            child: const Text(
              'Tümü',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BidRow extends StatelessWidget {
  final RecentBid bid;

  const _BidRow({required this.bid});

  @override
  Widget build(BuildContext context) {
    final label = _bidStatusLabels[bid.status] ?? bid.status;
    final color = _bidStatusColors[bid.status] ?? AppColors.gray500;
    final bgColor = _bidStatusBgColors[bid.status] ?? AppColors.gray100;

    return InkWell(
      onTap: () => context.push('/dashboard/requests/${bid.requestId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.success50,
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Icon(
                Icons.store_outlined,
                size: 18,
                color: AppColors.primary600,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bid.serviceCompanyName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bid.requestTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
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
                  bid.price != null
                      ? '${bid.price!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} ₺'
                      : '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
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
