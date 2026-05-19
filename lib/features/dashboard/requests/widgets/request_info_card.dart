import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../models/request_detail.dart';

const _kMonths = [
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];
String _fmtDate(DateTime dt) =>
    '${dt.day} ${_kMonths[dt.month - 1]} ${dt.year}';

class RequestInfoCard extends StatelessWidget {
  final RequestDetail request;

  const RequestInfoCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        if (request.description.isNotEmpty) ...[
          Text(
            request.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.gray600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (request.imageUrl != null && request.imageUrl!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: request.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildVehicleCard(),
        const SizedBox(height: 8),
        _buildMetaRow(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            request.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _StatusBadge(status: request.status),
      ],
    );
  }

  Widget _buildVehicleCard() {
    final fields = <({String label, String value})>[
      if (request.vehicleBrand.isNotEmpty || request.vehicleModel.isNotEmpty)
        (
          label: 'Araç',
          value: '${request.vehicleBrand} ${request.vehicleModel}'.trim(),
        ),
      if (request.vehicleYear != null)
        (label: 'Yıl', value: '${request.vehicleYear}'),
      if (request.vehiclePlate != null && request.vehiclePlate!.isNotEmpty)
        (label: 'Plaka', value: request.vehiclePlate!),
      if (request.vehicleFuelType != null &&
          request.vehicleFuelType!.isNotEmpty)
        (label: 'Yakıt', value: _capitalize(request.vehicleFuelType!)),
      if (request.vehicleTransmissionType != null &&
          request.vehicleTransmissionType!.isNotEmpty)
        (
          label: 'Şanzıman',
          value: _capitalize(request.vehicleTransmissionType!),
        ),
      if (request.vehicleEngineDisplacement != null &&
          request.vehicleEngineDisplacement!.isNotEmpty)
        (label: 'Motor', value: '${request.vehicleEngineDisplacement!} L'),
    ];

    if (fields.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children:
            fields
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            f.label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            f.value,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.gray700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildMetaRow() {
    String? preferredDateLabel;
    if (request.preferredDateFrom != null) {
      final from = _fmtDate(request.preferredDateFrom!);
      if (request.preferredDateTo != null &&
          request.preferredDateTo != request.preferredDateFrom) {
        preferredDateLabel = '$from – ${_fmtDate(request.preferredDateTo!)}';
      } else {
        preferredDateLabel = from;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _MetaChip(
          icon: Icons.calendar_today_outlined,
          label: _fmtDate(request.createdAt),
        ),
        if (preferredDateLabel != null)
          _MetaChip(
            icon: Icons.event_available_outlined,
            label: preferredDateLabel,
          ),
        if (request.urgencyLevel != null && request.urgencyLevel!.isNotEmpty)
          _UrgencyChip(level: request.urgencyLevel!),
        if (request.problemCategory != null &&
            request.problemCategory!.isNotEmpty)
          _MetaChip(
            icon: Icons.category_outlined,
            label: _capitalize(request.problemCategory!),
          ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static const _labels = <String, String>{
    'open': 'Açık',
    'bidding': 'Teklifte',
    'info_requested': 'Bilgi Bekleniyor',
    'info_provided': 'Bilgi Gönderildi',
    'accepted': 'Kabul Edildi',
    'in_progress': 'Devam Ediyor',
    'pending_review': 'Değerlendirme',
    'completed': 'Tamamlandı',
    'cancelled': 'İptal',
  };

  static const _colors = <String, Color>{
    'open': Color(0xFF2563EB),
    'bidding': Color(0xFF7C3AED),
    'info_requested': Color(0xFFD97706),
    'info_provided': Color(0xFF0891B2),
    'accepted': Color(0xFF059669),
    'in_progress': Color(0xFF2563EB),
    'pending_review': Color(0xFFD97706),
    'completed': AppColors.gray500,
    'cancelled': AppColors.red700,
  };

  static const _bgColors = <String, Color>{
    'open': Color(0xFFEFF6FF),
    'bidding': Color(0xFFF5F3FF),
    'info_requested': Color(0xFFFEF3C7),
    'info_provided': Color(0xFFECFEFF),
    'accepted': Color(0xFFECFDF5),
    'in_progress': Color(0xFFEFF6FF),
    'pending_review': Color(0xFFFEF3C7),
    'completed': AppColors.gray100,
    'cancelled': AppColors.red50,
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[status] ?? status;
    final color = _colors[status] ?? AppColors.gray500;
    final bg = _bgColors[status] ?? AppColors.gray100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
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
    );
  }
}

class _UrgencyChip extends StatelessWidget {
  final String level;
  const _UrgencyChip({required this.level});

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (level) {
      'urgent' => (Icons.priority_high, AppColors.amber600, AppColors.amber50),
      'critical' => (
        Icons.warning_amber_outlined,
        AppColors.red700,
        AppColors.red50,
      ),
      _ => (Icons.remove_circle_outline, AppColors.gray500, AppColors.gray100),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            level == 'urgent'
                ? 'Acil'
                : level == 'critical'
                ? 'Kritik'
                : 'Normal',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.gray500),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.gray600),
          ),
        ],
      ),
    );
  }
}
