import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import 'admin_dashboard_notifier.dart';
import 'models/admin_stats.dart';
import 'widgets/pending_approvals_section.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardProvider);
    final notifier = ref.read(adminDashboardProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Paneli',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
        ),
        actions: [
          if (!state.loading)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, color: AppColors.gray600),
              onPressed: notifier.load,
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF4F46E5),
        onRefresh: notifier.load,
        child: _buildBody(state, notifier),
      ),
    );
  }

  Widget _buildBody(AdminDashboardState state, AdminDashboardNotifier notifier) {
    if (state.loading && state.stats == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5), strokeWidth: 2),
      );
    }

    if (state.error != null && state.stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: const TextStyle(fontSize: 14, color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryBanner(),
          const SizedBox(height: 20),
          const Text(
            'Genel Bakış',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900),
          ),
          const SizedBox(height: 12),
          if (state.stats != null) _AdminStatGrid(stats: state.stats!),
          const SizedBox(height: 24),
          PendingApprovalsSection(
            providers: state.pendingApprovals,
            actioningId: state.actioningId,
            actionError: state.actionError,
            onApprove: notifier.approveProvider,
            onReject: notifier.rejectProvider,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yönetim Paneli',
                style: TextStyle(
                  color: Color(0xFFC7D2FE),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'OtoSanayiRandevu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tüm kullanıcı ve talep verilerini buradan yönetin.',
                style: TextStyle(
                  color: Color(0xFFC7D2FE),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminStatGrid extends StatelessWidget {
  final AdminStats stats;

  const _AdminStatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatConfig(
        label: 'Toplam Kullanıcı',
        value: '${stats.totalUsers}',
        icon: Icons.people_outlined,
        iconColor: const Color(0xFF4F46E5),
        bgColor: const Color(0xFFEEF2FF),
      ),
      _StatConfig(
        label: 'Servis Sağlayıcı',
        value: '${stats.totalProviders}',
        icon: Icons.business_outlined,
        iconColor: AppColors.blue600,
        bgColor: AppColors.info50,
      ),
      _StatConfig(
        label: 'Toplam Talep',
        value: '${stats.totalRequests}',
        icon: Icons.description_outlined,
        iconColor: AppColors.gray700,
        bgColor: AppColors.gray100,
      ),
      _StatConfig(
        label: 'Açık Talepler',
        value: '${stats.openRequests}',
        icon: Icons.pending_actions_outlined,
        iconColor: AppColors.amber600,
        bgColor: AppColors.amber50,
      ),
      _StatConfig(
        label: 'Değerlendirme',
        value: '${stats.pendingReview}',
        icon: Icons.rate_review_outlined,
        iconColor: AppColors.amber700,
        bgColor: AppColors.warning50,
      ),
      _StatConfig(
        label: 'Tamamlanan',
        value: '${stats.completed}',
        icon: Icons.check_circle_outlined,
        iconColor: AppColors.green700,
        bgColor: AppColors.green50,
      ),
      _StatConfig(
        label: 'Teklifler',
        value: '${stats.totalBids}',
        icon: Icons.price_check_outlined,
        iconColor: AppColors.violet700,
        bgColor: AppColors.violet50,
      ),
      _StatConfig(
        label: 'Değerlendirmeler',
        value: '${stats.totalReviews}',
        icon: Icons.star_outline,
        iconColor: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFFFBEB),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards.map((c) => _StatCard(config: c)).toList(),
    );
  }
}

class _StatConfig {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatConfig({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

class _StatCard extends StatelessWidget {
  final _StatConfig config;

  const _StatCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: config.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(config.icon, size: 18, color: config.iconColor),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              Text(
                config.label,
                style: const TextStyle(fontSize: 12, color: AppColors.gray500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
