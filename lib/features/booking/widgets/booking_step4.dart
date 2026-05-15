import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../guest_booking_notifier.dart';

class BookingStep4 extends ConsumerWidget {
  const BookingStep4({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(guestBookingProvider);
    final referenceCode = state.referenceCode ?? '—';
    final accessToken = state.accessToken ?? '';

    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle, size: 48, color: AppColors.primary600),
        ),
        const SizedBox(height: 24),
        const Text(
          'Rezervasyonunuz Alındı!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.gray900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Servis sağlayıcılar talebinizi inceleyecek ve size ulaşacak.',
          style: TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Referans Kodu',
                      style: TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      referenceCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 20, color: AppColors.gray500),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: referenceCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Referans kodu kopyalandı'), duration: Duration(seconds: 2)),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (accessToken.isNotEmpty)
          _CtaButton(
            label: 'Talebimi Görüntüle',
            icon: Icons.search_outlined,
            primary: true,
            onTap: () => context.push('/talebim/$accessToken'),
          ),
        const SizedBox(height: 12),
        _CtaButton(
          label: 'Hesap Oluştur',
          icon: Icons.person_add_outlined,
          primary: false,
          onTap: () => context.go('/register'),
        ),
        const SizedBox(height: 12),
        _CtaButton(
          label: 'Ana Sayfa',
          icon: Icons.home_outlined,
          primary: false,
          onTap: () => context.go('/servisler'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _CtaButton({required this.label, required this.icon, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary600, AppColors.primaryTeal]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary600.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.gray600),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.gray700)),
          ],
        ),
      ),
    );
  }
}
