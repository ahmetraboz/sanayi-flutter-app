import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../models/dashboard_models.dart';

class StatCardsGrid extends StatelessWidget {
  final CustomerStats stats;

  const StatCardsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        _StatCard(
          icon: Icons.directions_car_outlined,
          iconBgColor: AppColors.info50,
          iconColor: const Color(0xFF3B82F6),
          value: '${stats.vehicles}',
          label: 'Kayıtlı Araç',
          route: '/dashboard/vehicles',
        ),
        _StatCard(
          icon: Icons.description_outlined,
          iconBgColor: AppColors.violet50,
          iconColor: const Color(0xFF8B5CF6),
          value: '${stats.totalRequests}',
          label: 'Toplam Talep',
          route: '/dashboard/requests',
        ),
        _StatCard(
          icon: Icons.access_time_outlined,
          iconBgColor: AppColors.warning50,
          iconColor: const Color(0xFFEAB308),
          value: '${stats.openRequests}',
          label: 'Açık Talep',
          borderColor: const Color(0xFFFEF08A),
          valueColor: const Color(0xFFCA8A04),
          route: '/dashboard/requests',
        ),
        _StatCard(
          icon: Icons.move_to_inbox_outlined,
          iconBgColor: AppColors.success50,
          iconColor: AppColors.primary600,
          value: '${stats.pendingBids}',
          label: 'Gelen Teklif',
          borderColor: AppColors.primary600.withValues(alpha: 0.2),
          valueColor: AppColors.primary600,
          route: '/dashboard/requests',
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
  final String? route;
  final Color? borderColor;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.value,
    required this.label,
    this.route,
    this.borderColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: route != null ? () => context.push(route!) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? AppColors.gray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                if (route != null)
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.gray300,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.gray900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}
