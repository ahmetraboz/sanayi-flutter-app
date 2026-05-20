import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import 'admin_requests_notifier.dart';
import '../../../../shared/models/request_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminRequestsScreen extends ConsumerWidget {
  const AdminRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminRequestsProvider);
    final notifier = ref.read(adminRequestsProvider.notifier);

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
              'Talepler',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
            ),
            if (state.requests.isNotEmpty)
              Text(
                'Toplam ${state.requests.length} talep',
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

  Widget _buildBody(AdminRequestsState state, AdminRequestsNotifier notifier) {
    if (state.loading && state.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary600));
    }

    if (state.error != null && state.requests.isEmpty) {
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

    if (state.requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 48, color: AppColors.gray400),
            SizedBox(height: 16),
            Text('Kayıtlı talep bulunamadı.', style: TextStyle(color: AppColors.gray600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      color: AppColors.primary600,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final request = state.requests[index];
          return _RequestCard(request: request);
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RequestModel request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: Text(
                  request.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900),
                ),
              ),
              _StatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.description,
            style: const TextStyle(fontSize: 13, color: AppColors.gray600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.customerName ?? 'Bilinmeyen Müşteri',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.access_time, size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text(
                timeago.format(request.createdAt, locale: 'tr'),
                style: const TextStyle(fontSize: 12, color: AppColors.gray500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'open':
        bg = AppColors.info50;
        fg = AppColors.blue700;
        label = 'Açık';
        break;
      case 'in_progress':
        bg = AppColors.amber50;
        fg = AppColors.amber700;
        label = 'İşlemde';
        break;
      case 'completed':
        bg = AppColors.green50;
        fg = AppColors.green700;
        label = 'Tamamlandı';
        break;
      case 'cancelled':
        bg = AppColors.red50;
        fg = AppColors.red700;
        label = 'İptal';
        break;
      case 'rejected':
        bg = AppColors.red50;
        fg = AppColors.red700;
        label = 'Reddedildi';
        break;
      default:
        bg = AppColors.gray100;
        fg = AppColors.gray700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
