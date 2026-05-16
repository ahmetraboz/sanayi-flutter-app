import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import 'customer_dashboard_notifier.dart';
import 'widgets/action_banner.dart';
import 'widgets/stat_cards.dart';
import 'widgets/welcome_banner.dart';

class CustomerDashboardScreen extends ConsumerWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerDashboardProvider);
    final notifier = ref.read(customerDashboardProvider.notifier);

    if (state.loading && state.stats == null) {
      return const Scaffold(
        backgroundColor: AppColors.gray50,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary600,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: RefreshIndicator(
        color: AppColors.primary600,
        onRefresh: notifier.loadAll,
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              backgroundColor: AppColors.gray50,
              floating: true,
              snap: true,
              elevation: 0,
              toolbarHeight: 0,
            ),
            if (state.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.red50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.red100),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 18,
                          color: AppColors.red700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.red700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(child: WelcomeBanner()),
            ),
            if (state.stats != null) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: StatCardsGrid(stats: state.stats!),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: ActionBanner(stats: state.stats!),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
