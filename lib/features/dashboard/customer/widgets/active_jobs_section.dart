import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../models/dashboard_models.dart';
import 'animated_ping_dot.dart';

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
};

const _defaultStatus = _StatusConfig(
  label: 'Aktif',
  textColor: AppColors.gray600,
  bgColor: AppColors.gray100,
  borderColor: AppColors.gray200,
  icon: Icons.radio_button_unchecked,
);

class ActiveJobsSection extends StatelessWidget {
  final List<ActiveJob> jobs;

  const ActiveJobsSection({super.key, required this.jobs});

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
          if (jobs.isEmpty)
            _buildEmpty()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: jobs.length,
              separatorBuilder:
                  (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.gray100,
                  ),
              itemBuilder: (_, i) => _ActiveJobRow(job: jobs[i]),
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
          AnimatedPingDot(color: const Color(0xFF60A5FA)),
          const SizedBox(width: 8),
          const Text(
            'Aktif İşler',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary600,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              '${jobs.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/dashboard/requests'),
            child: const Text(
              'Tümünü Gör',
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

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'Aktif iş yok',
          style: TextStyle(fontSize: 14, color: AppColors.gray400),
        ),
      ),
    );
  }
}

class _ActiveJobRow extends StatelessWidget {
  final ActiveJob job;

  const _ActiveJobRow({required this.job});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig[job.status] ?? _defaultStatus;

    return InkWell(
      onTap: () => context.push('/dashboard/requests/${job.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: config.bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: config.borderColor),
              ),
              child: Icon(config.icon, size: 20, color: config.textColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${job.vehicleBrand} ${job.vehicleModel}'.trim(),
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
                color: config.bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                config.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: config.textColor,
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
