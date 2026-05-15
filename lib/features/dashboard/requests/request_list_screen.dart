import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/shared_pagination.dart';
import 'request_list_notifier.dart';
import 'widgets/filter_pills.dart';
import 'widgets/request_card.dart';

class RequestListScreen extends ConsumerWidget {
  const RequestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(requestListProvider);
    final notifier = ref.read(requestListProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Talepler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
      ),
      body: Column(
        children: [
          ColoredBox(
            color: Colors.white,
            child: FilterPills(
              activeFilter: state.activeFilter,
              onChanged: notifier.onFilterChanged,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary600,
              onRefresh: notifier.fetchRequests,
              child: _buildBody(state, notifier),
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
    );
  }

  Widget _buildBody(RequestListState state, RequestListNotifier notifier) {
    if (state.loading && state.requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary600,
          strokeWidth: 2,
        ),
      );
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
