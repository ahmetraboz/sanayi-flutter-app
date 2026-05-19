import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/header_actions.dart';
import '../../../shared/widgets/shared_pagination.dart';
import '../../../shared/widgets/skeleton.dart';
import 'request_list_notifier.dart';
import 'widgets/filter_pills.dart';
import 'widgets/request_card.dart';

class RequestListScreen extends ConsumerWidget {
  const RequestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(requestListProvider);
    final notifier = ref.read(requestListProvider.notifier);

    final bottomInset = MediaQuery.of(context).padding.bottom + 90;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 56,
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/dashboard/requests/new'),
          backgroundColor: AppColors.primary600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: 'Taleplerim',
              action: const HeaderActions(),
            ),
            const SizedBox(height: 16),
            ColoredBox(
              color: AppColors.gray50,
              child: FilterPills(
                activeFilter: state.activeFilter,
                onChanged: notifier.onFilterChanged,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary600,
                onRefresh: notifier.fetchRequests,
                child: _buildBody(state, notifier, bottomInset),
              ),
            ),
            SharedPagination(
              currentPage: state.currentPage,
              totalPages: state.totalPages,
              total: state.total,
              onPrevious: state.currentPage > 1 ? notifier.previousPage : null,
              onNext:
                  state.currentPage < state.totalPages ? notifier.nextPage : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(RequestListState state, RequestListNotifier notifier, double bottomInset) {
    if (state.loading && state.requests.isEmpty) {
      return const _RequestListSkeleton();
    }

    if (state.error != null && state.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: const TextStyle(color: AppColors.gray500, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: notifier.fetchRequests,
              child: const Text(
                'Tekrar Dene',
                style: TextStyle(color: AppColors.primary600),
              ),
            ),
          ],
        ),
      );
    }

    if (state.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 48,
              color: AppColors.gray300,
            ),
            const SizedBox(height: 12),
            Text(
              state.activeFilter != null
                  ? 'Bu filtrede talep yok.'
                  : 'Henüz talep oluşturmadınız.',
              style: const TextStyle(color: AppColors.gray500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
          itemCount: state.requests.length,
          itemBuilder: (context, i) => RequestCard(request: state.requests[i]),
        ),
        if (state.loading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              color: AppColors.primary600,
              backgroundColor: AppColors.gray100,
              minHeight: 2,
            ),
          ),
      ],
    );
  }
}

class _RequestListSkeleton extends StatelessWidget {
  const _RequestListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const SkeletonBox(width: 44, height: 44, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(height: 14, radius: 5),
                  const SizedBox(height: 6),
                  const SkeletonBox(height: 12, width: 160, radius: 4),
                  const SizedBox(height: 5),
                  const SkeletonBox(height: 11, width: 100, radius: 4),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const SkeletonBox(width: 60, height: 26, radius: 8),
          ],
        ),
      ),
    );
  }
}
