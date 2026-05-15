import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/theme.dart';
import '../booking/booking_repository.dart';

class GuestBookingLookupScreen extends ConsumerStatefulWidget {
  const GuestBookingLookupScreen({super.key});

  @override
  ConsumerState<GuestBookingLookupScreen> createState() => _GuestBookingLookupScreenState();
}

class _GuestBookingLookupScreenState extends ConsumerState<GuestBookingLookupScreen> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final name = _nameCtrl.text.trim();
    final code = _codeCtrl.text.trim();

    if (name.isEmpty || code.isEmpty) {
      setState(() => _error = 'Lütfen tüm alanları doldurun.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(bookingRepositoryProvider);
      final token = await repo.lookupBooking(name: name, code: code);
      if (!mounted) return;
      context.go('/talebim/$token?name=${Uri.encodeComponent(name)}&code=${Uri.encodeComponent(code)}');
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : 'Talep bulunamadı. Bilgilerinizi kontrol edin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Talep Sorgula',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary600, AppColors.primaryTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, size: 32, color: Colors.white),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Taleplerinizi Sorgulayın',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ad ve referans kodunuzu girerek talebinizi bulun.',
                          style: TextStyle(fontSize: 12, color: AppColors.emerald200),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Ad Soyad',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700),
            ),
            const SizedBox(height: 8),
            _InputField(
              controller: _nameCtrl,
              hint: 'Örn: Ahmet Yılmaz',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            const Text(
              'Referans Kodu',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700),
            ),
            const SizedBox(height: 8),
            _InputField(
              controller: _codeCtrl,
              hint: 'Örn: REF-2024-001',
              icon: Icons.confirmation_number_outlined,
              textCapitalization: TextCapitalization.characters,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.red100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: AppColors.red700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(fontSize: 13, color: AppColors.red700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loading ? null : _lookup,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: _loading
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.primary600, AppColors.primaryTeal],
                        ),
                  color: _loading ? AppColors.gray200 : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary600,
                          ),
                        )
                      : const Text(
                          'Talebi Bul',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () => context.go('/servisler'),
                child: const Text(
                  'Servis sağlayıcılarını keşfet →',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextCapitalization textCapitalization;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.textCapitalization = TextCapitalization.words,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.gray400),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary600),
        ),
        hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
      ),
    );
  }
}
