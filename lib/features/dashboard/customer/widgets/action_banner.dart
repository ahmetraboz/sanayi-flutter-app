import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../models/dashboard_models.dart';

class ActionBanner extends StatelessWidget {
  final CustomerStats stats;

  const ActionBanner({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final hasBids = stats.pendingBids > 0;
    final hasOpenRequests = stats.openRequests > 0;

    if (!hasBids && !hasOpenRequests) return const SizedBox.shrink();

    final String title;
    final String subtitle;
    final Color bgColor;
    final Color borderColor;
    final Color iconBgColor;
    final Color iconColor;
    final Color titleColor;
    final Color subtitleColor;
    final IconData icon;

    if (hasBids) {
      title = '${stats.pendingBids} teklif değerlendirme bekliyor';
      subtitle = hasOpenRequests
          ? '${stats.openRequests} açık talebiniz var'
          : 'Teklifleri inceleyip onaylayın';
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      iconBgColor = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFD97706);
      titleColor = const Color(0xFF92400E);
      subtitleColor = const Color(0xFFB45309);
      icon = Icons.local_offer_outlined;
    } else {
      title = '${stats.openRequests} açık talebiniz var';
      subtitle = 'Henüz teklif gelmedi, bekleniyor...';
      bgColor = AppColors.info50;
      borderColor = const Color(0xFFBFDBFE);
      iconBgColor = const Color(0xFFDEF0FF);
      iconColor = const Color(0xFF2563EB);
      titleColor = const Color(0xFF1D4ED8);
      subtitleColor = const Color(0xFF3B82F6);
      icon = Icons.access_time_outlined;
    }

    return GestureDetector(
      onTap: () => context.push('/dashboard/requests'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: subtitleColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: iconColor),
          ],
        ),
      ),
    );
  }
}
