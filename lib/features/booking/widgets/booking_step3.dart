import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../guest_booking_notifier.dart';

class BookingStep3 extends ConsumerStatefulWidget {
  const BookingStep3({super.key});

  @override
  ConsumerState<BookingStep3> createState() => _BookingStep3State();
}

class _BookingStep3State extends ConsumerState<BookingStep3> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final form = ref.read(guestBookingProvider).form;
    _nameCtrl = TextEditingController(text: form.name);
    _phoneCtrl = TextEditingController(text: form.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guestBookingProvider);
    final notifier = ref.read(guestBookingProvider.notifier);
    final errors = state.errors;
    final form = state.form;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Ad Soyad'),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          onChanged: notifier.updateName,
          decoration: _inputDecoration(hint: 'Ahmet Yılmaz', error: errors['name']),
        ),
        const SizedBox(height: 20),
        _label('Telefon Numarası'),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onChanged: notifier.updatePhone,
          decoration: _inputDecoration(hint: '05xx xxx xx xx', error: errors['phone']),
        ),
        const SizedBox(height: 24),
        _SummaryBox(form: form),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.blue600),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Talebiniz servis sağlayıcılara iletilecek ve en kısa sürede fiyat teklifi alacaksınız.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E40AF), height: 1.5),
                ),
              ),
            ],
          ),
        ),
        if (state.submitError != null) ...[
          const SizedBox(height: 12),
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
                  child: Text(state.submitError!, style: const TextStyle(fontSize: 13, color: AppColors.red700)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: state.submitting ? null : notifier.previousStep,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: const Center(
                    child: Text('Geri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: state.submitting ? null : notifier.validateAndNext,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: state.submitting
                        ? null
                        : const LinearGradient(colors: [AppColors.primary600, AppColors.primaryTeal]),
                    color: state.submitting ? AppColors.gray200 : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: state.submitting
                        ? null
                        : [BoxShadow(color: AppColors.primary600.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
                  ),
                  child: Center(
                    child: state.submitting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Gönder', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final dynamic form;
  const _SummaryBox({required this.form});

  @override
  Widget build(BuildContext context) {
    final serviceCount = (form.selectedServiceIds as List).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Özet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
          const SizedBox(height: 12),
          if ((form.title as String).isNotEmpty)
            _SummaryRow(icon: Icons.title, text: form.title as String),
          if ((form.brand as String).isNotEmpty)
            _SummaryRow(icon: Icons.directions_car_outlined, text: '${form.brand} ${form.model}'.trim()),
          if ((form.selectedCity as String?) != null)
            _SummaryRow(icon: Icons.location_on_outlined, text: form.selectedCity as String),
          if (serviceCount > 0)
            _SummaryRow(icon: Icons.build_outlined, text: '$serviceCount servis sağlayıcı seçildi'),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SummaryRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.gray400),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.gray700))),
        ],
      ),
    );
  }
}

Widget _label(String text) => Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700),
    );

InputDecoration _inputDecoration({String? hint, String? error}) => InputDecoration(
      hintText: hint,
      errorText: error,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary600)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.red700)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.red700)),
      hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
    );
