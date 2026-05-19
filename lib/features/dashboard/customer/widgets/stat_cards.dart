import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../models/dashboard_models.dart';

class StatCardsGrid extends StatelessWidget {
  final CustomerStats stats;

  const StatCardsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.directions_car_outlined,
                iconBgColor: AppColors.info50,
                iconColor: const Color(0xFF3B82F6),
                value: '${stats.vehicles}',
                label: 'Kayıtlı Araç',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.list_alt_outlined,
                iconBgColor: AppColors.gray100,
                iconColor: AppColors.gray500,
                value: '${stats.totalRequests}',
                label: 'Toplam Talep',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.access_time_outlined,
                iconBgColor: AppColors.warning50,
                iconColor: const Color(0xFFEAB308),
                value: '${stats.openRequests}',
                label: 'Açık Talep',
                valueColor: const Color(0xFFCA8A04),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.move_to_inbox_outlined,
                iconBgColor: AppColors.success50,
                iconColor: AppColors.primary600,
                value: '${stats.pendingBids}',
                label: 'Gelen Teklif',
                valueColor: AppColors.primary600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String value;
  final String label;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.gray900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.gray500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
