import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import 'admin_users_notifier.dart';
import '../../../../shared/models/user_model.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminUsersProvider);
    final notifier = ref.read(adminUsersProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kullanıcılar',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
            ),
            if (state.users.isNotEmpty)
              Text(
                'Toplam ${state.users.length} kullanıcı',
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
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(BuildContext context, AdminUsersState state, AdminUsersNotifier notifier) {
    if (state.loading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary600));
    }

    if (state.error != null && state.users.isEmpty) {
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

    if (state.users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: AppColors.gray400),
            SizedBox(height: 16),
            Text('Kayıtlı kullanıcı bulunamadı.', style: TextStyle(color: AppColors.gray600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      color: AppColors.primary600,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.users.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = state.users[index];
          return _UserCard(
            user: user,
            deleting: state.deletingId == user.id,
            onDelete: () => _confirmDelete(context, user, notifier),
          );
        },
      ),
    );
  }
}

void _confirmDelete(BuildContext context, UserModel user, AdminUsersNotifier notifier) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.delete_outline, color: AppColors.red700),
          SizedBox(width: 8),
          Text('Kullanıcıyı Sil', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        ],
      ),
      content: Text(
        '${user.name} adlı kullanıcı kalıcı olarak silinecek. Bu işlem geri alınamaz.',
        style: const TextStyle(fontSize: 14, color: AppColors.gray600),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Vazgeç', style: TextStyle(color: AppColors.gray500)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            await notifier.deleteUser(user.id);
          },
          child: const Text('Sil'),
        ),
      ],
    ),
  );
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final bool deleting;
  final VoidCallback onDelete;

  const _UserCard({required this.user, required this.deleting, required this.onDelete});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.success50,
            foregroundColor: AppColors.primary700,
            radius: 24,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900),
                      ),
                    ),
                    _RoleBadge(role: user.role),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 13, color: AppColors.gray600),
                ),
                if (user.phone != null && user.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.phone!,
                    style: const TextStyle(fontSize: 13, color: AppColors.gray600),
                  ),
                ],
                if (user.serviceProfile != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Servis profili var', style: TextStyle(fontSize: 11, color: AppColors.primary600)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (user.role != 'admin')
            deleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.red700),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.red700, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Kullanıcıyı Sil',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (role) {
      case 'admin':
        bg = AppColors.red50;
        fg = AppColors.red700;
        label = 'Admin';
        break;
      case 'provider':
        bg = AppColors.info50;
        fg = AppColors.blue700;
        label = 'Sağlayıcı';
        break;
      case 'customer':
      default:
        bg = AppColors.green50;
        fg = AppColors.green700;
        label = 'Müşteri';
        break;
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
