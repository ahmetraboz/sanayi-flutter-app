import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/header_actions.dart';

class WelcomeBanner extends ConsumerWidget {
  const WelcomeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final firstName = user?.firstName ?? 'Kullanıcı';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Merhaba, $firstName',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Bugün ne yapmak istersiniz?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const HeaderActions(),
      ],
    );
  }
}
