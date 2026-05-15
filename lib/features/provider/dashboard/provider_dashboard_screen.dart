import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import 'provider_dashboard_notifier.dart';
import 'widgets/active_jobs_section.dart';
import 'widgets/provider_banner.dart';
import 'widgets/provider_stat_cards.dart';
import 'widgets/recent_requests_section.dart';
import 'widgets/status_alert.dart';
import 'widgets/acceptance_rate_widget.dart';
import 'widgets/quick_actions_grid.dart';

class ProviderDashboardScreen extends ConsumerWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerDashboardProvider);
    final notifier = ref.read(providerDashboardProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Sağlayıcı Paneli',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.gray600),
            onPressed: () => context.push('/provider/notifications'),
          ),
          if (!state.loading)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, color: AppColors.gray600),
              onPressed: notifier.load,
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.blue600,
        onRefresh: notifier.load,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(ProviderDashboardState state) {
    if (state.loading && state.stats == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue600, strokeWidth: 2),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const ProviderStatusAlert(),
              const SizedBox(height: 16),
              ProviderBanner(stats: state.stats),
              const SizedBox(height: 20),
              if (state.error != null && state.stats == null) ...[
                _ErrorCard(message: state.error!),
                const SizedBox(height: 16),
              ],
              if (state.stats != null) ...[
                const Text(
                  'İstatistikler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 12),
                ProviderStatCards(stats: state.stats!),
                const SizedBox(height: 16),
                AcceptanceRateWidget(stats: state.stats!),
                const SizedBox(height: 24),
              ],
              if (state.activeJobs.isNotEmpty || state.stats != null) ...[
                ActiveJobsSection(jobs: state.activeJobs),
                const SizedBox(height: 24),
                RecentRequestsSection(requests: state.recentRequests),
                const SizedBox(height: 24),
                const QuickActionsGrid(),
              ],
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red100),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20, color: AppColors.red700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.red700)),
          ),
        ],
      ),
    );
  }
}
