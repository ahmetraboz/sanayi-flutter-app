import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../models/request_item.dart';

class _StatusConfig {
  final String label;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;

  const _StatusConfig({
    required this.label,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
  });
}

const _statusConfig = <String, _StatusConfig>{
  'open': _StatusConfig(
    label: 'Açık',
    textColor: Color(0xFF2563EB),
    bgColor: Color(0xFFEFF6FF),
    borderColor: Color(0xFFBFDBFE),
    icon: Icons.radio_button_unchecked,
  ),
  'bidding': _StatusConfig(
    label: 'Teklifte',
    textColor: Color(0xFF7C3AED),
    bgColor: Color(0xFFF5F3FF),
    borderColor: Color(0xFFDDD6FE),
    icon: Icons.gavel_outlined,
  ),
  'info_requested': _StatusConfig(
    label: 'Bilgi Bekleniyor',
    textColor: Color(0xFFD97706),
    bgColor: Color(0xFFFEF3C7),
    borderColor: Color(0xFFFDE68A),
    icon: Icons.help_outline,
  ),
  'info_provided': _StatusConfig(
    label: 'Bilgi Gönderildi',
    textColor: Color(0xFF0891B2),
    bgColor: Color(0xFFECFEFF),
    borderColor: Color(0xFFA5F3FC),
    icon: Icons.check_circle_outline,
  ),
  'accepted': _StatusConfig(
    label: 'Kabul Edildi',
    textColor: Color(0xFF059669),
    bgColor: Color(0xFFECFDF5),
    borderColor: Color(0xFFD1FAE5),
    icon: Icons.check_circle_outline,
  ),
  'in_progress': _StatusConfig(
    label: 'Devam Ediyor',
    textColor: Color(0xFF2563EB),
    bgColor: Color(0xFFEFF6FF),
    borderColor: Color(0xFFBFDBFE),
    icon: Icons.build_outlined,
  ),
  'pending_review': _StatusConfig(
    label: 'Değerlendirme',
    textColor: Color(0xFFD97706),
    bgColor: Color(0xFFFEF3C7),
    borderColor: Color(0xFFFDE68A),
    icon: Icons.star_border_outlined,
  ),
  'completed': _StatusConfig(
    label: 'Tamamlandı',
    textColor: AppColors.gray500,
    bgColor: AppColors.gray100,
    borderColor: AppColors.gray200,
    icon: Icons.check_circle,
  ),
  'cancelled': _StatusConfig(
    label: 'İptal',
    textColor: AppColors.red700,
    bgColor: AppColors.red50,
    borderColor: AppColors.red100,
    icon: Icons.cancel_outlined,
  ),
  'rejected': _StatusConfig(
    label: 'Reddedildi',
    textColor: AppColors.red700,
    bgColor: AppColors.red50,
    borderColor: AppColors.red100,
    icon: Icons.cancel_outlined,
  ),
};

const _defaultStatus = _StatusConfig(
  label: 'Bilinmiyor',
  textColor: AppColors.gray500,
  bgColor: AppColors.gray100,
  borderColor: AppColors.gray200,
  icon: Icons.help_outline,
);

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

String _formatDate(DateTime dt) =>
    '${dt.day} ${_kMonths[dt.month - 1]} ${dt.year}';

class RequestCard extends StatelessWidget {
  final RequestItem request;

  const RequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig[request.status] ?? _defaultStatus;

    return GestureDetector(
      onTap: () => context.push('/dashboard/requests/${request.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: config.bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: config.borderColor),
              ),
              child: Icon(config.icon, size: 22, color: config.textColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(request.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: config.bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    config.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: config.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.gray300,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
