import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/shared_pagination.dart';
import 'provider_open_requests_notifier.dart';
import 'widgets/provider_request_card.dart';

const _categoryFilters = [
  {'key': 'all', 'label': 'Tümü', 'icon': Icons.grid_view},
  {'key': 'maintenance', 'label': 'Periyodik Bakım', 'icon': Icons.build_circle_outlined},
  {'key': 'engine', 'label': 'Motor & Mekanik', 'icon': Icons.settings_outlined},
  {'key': 'electrical', 'label': 'Elektrik & Elektronik', 'icon': Icons.bolt_outlined},
  {'key': 'body', 'label': 'Kaporta & Boya', 'icon': Icons.directions_car_outlined},
  {'key': 'tire', 'label': 'Lastik & Jant', 'icon': Icons.tire_repair_outlined},
  {'key': 'other', 'label': 'Diğer', 'icon': Icons.more_horiz_outlined},
];

class ProviderRequestsScreen extends ConsumerWidget {
  const ProviderRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerOpenRequestsProvider);
    final notifier = ref.read(providerOpenRequestsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Açık Talepler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            Text(
              'Müşterilerin servis taleplerini inceleyin',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray500,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (state.requests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // blue50
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${state.requests.length} talep',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _categoryFilters.map((filter) {
                  final isActive = state.activeCategory == filter['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Row(
                        children: [
                          Icon(
                            filter['icon'] as IconData,
                            size: 16,
                            color: isActive ? Colors.white : AppColors.gray500,
                          ),
                          const SizedBox(width: 6),
                          Text(filter['label'] as String),
                        ],
                      ),
                      selected: isActive,
                      onSelected: (_) => notifier.onCategoryChanged(filter['key'] as String),
                      selectedColor: AppColors.primary600,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isActive ? Colors.white : AppColors.gray700,
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isActive ? AppColors.primary600 : AppColors.gray200,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.gray200),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary600,
              onRefresh: () => notifier.fetchRequests(page: 1),
              child: _buildBody(state, notifier),
            ),
          ),
          if (state.totalPages > 1)
            SharedPagination(
              currentPage: state.currentPage,
              totalPages: state.totalPages,
              total: state.total,
              onPrevious: state.currentPage > 1 ? notifier.previousPage : null,
              onNext: state.currentPage < state.totalPages ? notifier.nextPage : null,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ProviderOpenRequestsState state, ProviderOpenRequestsNotifier notifier) {
    if (state.loading && state.requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary600, strokeWidth: 2),
      );
    }

    if (state.error != null && state.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(color: AppColors.gray500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.fetchRequests(page: 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
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
            const Icon(Icons.build_circle_outlined, size: 64, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              state.activeCategory == 'all' ? 'Açık talep yok' : 'Bu kategoride talep bulunamadı',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.activeCategory == 'all'
                  ? 'Şu an için size yönlendirilmiş açık servis talebi bulunmuyor.'
                  : 'Farklı bir kategori filtresi deneyin.',
              style: const TextStyle(color: AppColors.gray500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.requests.length,
      itemBuilder: (context, index) {
        final request = state.requests[index] as Map<String, dynamic>;
        return ProviderRequestCard(request: request);
      },
    );
  }
}
