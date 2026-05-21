import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/date_picker_sheet.dart';
import '../models/request_detail.dart';

class BidCard extends StatelessWidget {
  final BidItem bid;
  final bool canAccept;
  final bool accepting;
  final bool rejecting;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final Future<bool> Function(DateTime date)? onCounterDate;
  final Future<bool> Function()? onAcceptDate;

  const BidCard({
    super.key,
    required this.bid,
    required this.canAccept,
    required this.accepting,
    this.rejecting = false,
    this.onAccept,
    this.onReject,
    this.onCounterDate,
    this.onAcceptDate,
  });

  @override
  Widget build(BuildContext context) {
    final isAccepted = bid.status == 'accepted';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isAccepted
                  ? AppColors.primary600.withValues(alpha: 0.4)
                  : AppColors.gray200,
          width: isAccepted ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(isAccepted),
          const Divider(height: 1, thickness: 1, color: AppColors.gray100),
          _buildBody(context),
          if (canAccept && (bid.status == 'quoted' || bid.status == 'pending')) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.gray100),
            _buildActions(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(bool isAccepted) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bid.companyName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 2),
                if (bid.city != null) Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      bid.city!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _BidStatusBadge(status: bid.status),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (bid.logoUrl != null && bid.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: bid.logoUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.info50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.business_outlined,
        size: 22,
        color: Color(0xFF3B82F6),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₺${bid.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary600,
                ),
              ),
              const SizedBox(width: 8),
              if (bid.estimatedDuration.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_outlined,
                      size: 14,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bid.estimatedDuration,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (bid.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bid.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray600,
                height: 1.5,
              ),
            ),
          ],
          if (bid.proposedDate != null) ...[
            const SizedBox(height: 10),
            _ProposedDateRow(
              proposedDate: bid.proposedDate!,
              dateProposedBy: bid.dateProposedBy,
              canCounter: canAccept,
              onCounterDate: onCounterDate,
              onAcceptDate: onAcceptDate,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final busy = accepting || rejecting;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: busy ? null : () => _confirmReject(context),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: busy ? AppColors.gray100 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: busy ? AppColors.gray200 : AppColors.red100,
                  ),
                ),
                child: Center(
                  child:
                      rejecting
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.red700,
                            ),
                          )
                          : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.red700,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Reddet',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.red700,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: busy ? null : () => _confirmAccept(context),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient:
                      busy
                          ? null
                          : const LinearGradient(
                            colors: [
                              AppColors.primary600,
                              AppColors.primaryTeal,
                            ],
                          ),
                  color: busy ? AppColors.gray200 : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      busy
                          ? null
                          : [
                            BoxShadow(
                              color: AppColors.primary600.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                ),
                child: Center(
                  child:
                      accepting
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Kabul Et',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAccept(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Teklifi Kabul Et',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            content: Text(
              '${bid.companyName} firmasından gelen ₺${bid.price.toStringAsFixed(0)} tutarındaki teklifi kabul etmek istediğinizden emin misiniz?',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray600,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Vazgeç',
                  style: TextStyle(color: AppColors.gray500),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onAccept?.call();
                },
                child: const Text(
                  'Kabul Et',
                  style: TextStyle(
                    color: AppColors.primary600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _confirmReject(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Teklifi Reddet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            content: Text(
              '${bid.companyName} firmasının teklifini reddetmek istediğinizden emin misiniz?',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray600,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Vazgeç',
                  style: TextStyle(color: AppColors.gray500),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onReject?.call();
                },
                child: const Text(
                  'Reddet',
                  style: TextStyle(
                    color: AppColors.red700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

// ─── Proposed Date Row ────────────────────────────────────────────────────────

class _ProposedDateRow extends StatelessWidget {
  final DateTime proposedDate;
  final String? dateProposedBy;
  final bool canCounter;
  final Future<bool> Function(DateTime date)? onCounterDate;
  final Future<bool> Function()? onAcceptDate;

  const _ProposedDateRow({
    required this.proposedDate,
    required this.canCounter,
    this.dateProposedBy,
    this.onCounterDate,
    this.onAcceptDate,
  });

  static const _kMonths = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  String _fmt(DateTime dt) => '${dt.day} ${_kMonths[dt.month - 1]} ${dt.year}';

  String _toIsoDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  void _pickCounterDate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DatePickerSheet(
          title: 'Farklı Tarih Seçin',
          initialDate: _toIsoDate(
            proposedDate.isAfter(DateTime.now()) ? proposedDate : DateTime.now().add(const Duration(days: 1)),
          ),
          onSelected: (dateStr) {
            final parts = dateStr.split('-');
            if (parts.length < 3) return;
            final picked = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
            onCounterDate?.call(picked);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAgreed = dateProposedBy == 'agreed';
    final proposedByCustomer = dateProposedBy == 'customer';

    if (isAgreed) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.event_available, size: 18, color: Color(0xFF16A34A)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tarihte Uzlaşıldı',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmt(proposedDate),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF14532D)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Onaylandı ✓',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.swap_vert_rounded, size: 15, color: Color(0xFF7C3AED)),
              SizedBox(width: 6),
              Text(
                'Tarih Görüşmesi',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (proposedByCustomer) ...[
            _DateStep(
              icon: Icons.person_outline,
              iconColor: const Color(0xFFD97706),
              bgColor: const Color(0xFFFEF3C7),
              label: 'Önerdiğiniz Tarih',
              labelColor: const Color(0xFFD97706),
              date: _fmt(proposedDate),
              dateColor: const Color(0xFF92400E),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Yanıt Bekleniyor',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                ),
              ),
            ),
          ] else ...[
            // dateProposedBy == 'provider'
            _DateStep(
              icon: Icons.build_outlined,
              iconColor: const Color(0xFF7C3AED),
              bgColor: const Color(0xFFEDE9FE),
              label: 'Ustanın Önerdiği Tarih',
              labelColor: const Color(0xFF7C3AED),
              date: _fmt(proposedDate),
              dateColor: const Color(0xFF4C1D95),
            ),
            if (canCounter) ...[
              Padding(
                padding: const EdgeInsets.only(left: 17),
                child: Container(width: 1.5, height: 14, color: const Color(0xFFDDD6FE)),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickCounterDate(context),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDDD6FE)),
                        ),
                        child: const Center(
                          child: Text(
                            'Farklı Tarih Öner',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onAcceptDate?.call(),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            'Tarihi Kabul Et',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DateStep extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final Color labelColor;
  final String date;
  final Color dateColor;
  final Widget? trailing;

  const _DateStep({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.labelColor,
    required this.date,
    required this.dateColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: labelColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: dateColor,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _BidStatusBadge extends StatelessWidget {
  final String status;
  const _BidStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      'accepted' => (
        'Kabul Edildi',
        const Color(0xFF059669),
        const Color(0xFFECFDF5),
      ),
      'rejected' => ('Reddedildi', AppColors.red700, AppColors.red50),
      _ => ('Teklif Verildi', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
