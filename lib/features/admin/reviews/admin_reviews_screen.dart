import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import 'admin_reviews_notifier.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminReviewsScreen extends ConsumerWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminReviewsProvider);
    final notifier = ref.read(adminReviewsProvider.notifier);

    timeago.setLocaleMessages('tr', timeago.TrMessages());

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Değerlendirmeler',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
            ),
            if (state.reviews.isNotEmpty)
              Text(
                'Toplam ${state.reviews.length} değerlendirme',
                style: const TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (!state.loading)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.gray600),
              onPressed: () => notifier.load(),
            ),
        ],
      ),
      body: _buildBody(state, notifier),
    );
  }

  Widget _buildBody(AdminReviewsState state, AdminReviewsNotifier notifier) {
    if (state.loading && state.reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary600));
    }

    if (state.error != null && state.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red700),
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(color: AppColors.red700)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => notifier.load(),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (state.reviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 48, color: AppColors.gray400),
            SizedBox(height: 16),
            Text('Kayıtlı değerlendirme bulunamadı.', style: TextStyle(color: AppColors.gray600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      color: AppColors.primary600,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.reviews.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final review = state.reviews[index] as Map<String, dynamic>;
          return _ReviewCard(review: review);
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = (review['rating'] ?? 0).toString();
    final comment = review['comment'] as String? ?? 'Yorum yapılmamış.';
    final dateStr = review['createdAt'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    
    final customer = review['customer'] as Map<String, dynamic>?;
    final customerName = customer?['name'] as String? ?? 'Bilinmeyen Müşteri';
    
    final provider = review['provider'] as Map<String, dynamic>?;
    final providerName = provider?['name'] as String? ?? 'Bilinmeyen Sağlayıcı';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    rating,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900),
                  ),
                ],
              ),
              if (date != null)
                Text(
                  timeago.format(date, locale: 'tr'),
                  style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: const TextStyle(fontSize: 14, color: AppColors.gray700),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.gray200),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Müşteri', style: TextStyle(fontSize: 11, color: AppColors.gray400)),
                    const SizedBox(height: 2),
                    Text(
                      customerName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 16, color: AppColors.gray300),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sağlayıcı', style: TextStyle(fontSize: 11, color: AppColors.gray400)),
                    const SizedBox(height: 2),
                    Text(
                      providerName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
