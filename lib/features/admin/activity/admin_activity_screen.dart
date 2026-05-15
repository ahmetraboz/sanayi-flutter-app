import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import 'admin_activity_notifier.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminActivityScreen extends ConsumerWidget {
  const AdminActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminActivityProvider);
    final notifier = ref.read(adminActivityProvider.notifier);

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
              'Aktivite',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
            ),
            if (state.activities.isNotEmpty)
              Text(
                'Son ${state.activities.length} aktivite',
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

  Widget _buildBody(AdminActivityState state, AdminActivityNotifier notifier) {
    if (state.loading && state.activities.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary600));
    }

    if (state.error != null && state.activities.isEmpty) {
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

    if (state.activities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: AppColors.gray400),
            SizedBox(height: 16),
            Text('Kayıtlı aktivite bulunamadı.', style: TextStyle(color: AppColors.gray600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      color: AppColors.primary600,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.activities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final activity = state.activities[index] as Map<String, dynamic>;
          return _ActivityCard(activity: activity);
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final type = activity['type'] as String? ?? 'system';
    final description = activity['description'] as String? ?? 'Aktivite detayı bulunmuyor.';
    final dateStr = activity['createdAt'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    
    final user = activity['user'] as Map<String, dynamic>?;
    final userName = user?['name'] as String? ?? 'Sistem';

    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (type) {
      case 'user_action':
        icon = Icons.person_outline;
        iconColor = AppColors.blue600;
        bgColor = AppColors.info50;
        break;
      case 'system_error':
        icon = Icons.error_outline;
        iconColor = AppColors.red700;
        bgColor = AppColors.red50;
        break;
      case 'request_created':
        icon = Icons.description_outlined;
        iconColor = AppColors.green700;
        bgColor = AppColors.green50;
        break;
      case 'bid_placed':
        icon = Icons.price_check_outlined;
        iconColor = AppColors.amber600;
        bgColor = AppColors.amber50;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = AppColors.gray600;
        bgColor = AppColors.gray100;
    }

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: AppColors.gray700, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 12, color: AppColors.gray400),
                    const SizedBox(width: 4),
                    Text(
                      userName,
                      style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                    const Spacer(),
                    if (date != null)
                      Text(
                        timeago.format(date, locale: 'tr'),
                        style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
