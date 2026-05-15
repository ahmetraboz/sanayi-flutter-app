import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../guest_booking_notifier.dart';
import 'damage_analysis_widget.dart';
import 'image_upload_area.dart';
import 'service_provider_picker.dart';

class BookingStep1 extends ConsumerStatefulWidget {
  const BookingStep1({super.key});

  @override
  ConsumerState<BookingStep1> createState() => _BookingStep1State();
}

class _BookingStep1State extends ConsumerState<BookingStep1> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    final form = ref.read(guestBookingProvider).form;
    _titleCtrl = TextEditingController(text: form.title);
    _descCtrl = TextEditingController(text: form.description);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guestBookingProvider);
    final notifier = ref.read(guestBookingProvider.notifier);
    final errors = state.errors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Talebinizin Başlığı'),
        const SizedBox(height: 6),
        TextField(
          controller: _titleCtrl,
          textInputAction: TextInputAction.next,
          onChanged: notifier.updateTitle,
          style: const TextStyle(color: AppColors.gray900, fontSize: 14),
          decoration: _inputDecoration(hint: 'Örn: Motor arızası', error: errors['title']),
        ),
        const SizedBox(height: 20),
        _label('Açıklama'),
        const SizedBox(height: 6),
        TextField(
          controller: _descCtrl,
          minLines: 3,
          maxLines: 6,
          onChanged: notifier.updateDescription,
          style: const TextStyle(color: AppColors.gray900, fontSize: 14),
          decoration: _inputDecoration(
            hint: 'Problemi detaylı açıklayın...',
            error: errors['description'],
          ),
        ),
        const SizedBox(height: 20),
        _label('Görsel (İsteğe Bağlı)'),
        const SizedBox(height: 6),
        ImageUploadArea(
          imageUrl: state.form.imageUrl,
          isUploading: state.imageUploading,
          onImageSelected: notifier.uploadImage,
        ),
        const SizedBox(height: 20),
        DamageAnalysisWidget(onReportsChanged: notifier.updateDamageReports),
        const SizedBox(height: 20),
        _label('Servis Sağlayıcı'),
        const SizedBox(height: 6),
        ServiceProviderPickerWidget(
          selectedCity: state.form.selectedCity,
          selectedIds: state.form.selectedServiceIds,
          providers: state.availableProviders,
          providersLoading: state.providersLoading,
          onCityChanged: notifier.updateCity,
          onToggleService: notifier.toggleService,
          cityError: errors['city'],
          servicesError: errors['services'],
        ),
        const SizedBox(height: 32),
        _primaryButton(
          label: 'İleri',
          onTap: notifier.validateAndNext,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

Widget _label(String text) => Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.gray700,
      ),
    );

InputDecoration _inputDecoration({String? hint, String? error}) => InputDecoration(
      hintText: hint,
      errorText: error,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red700),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red700),
      ),
      hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
    );

Widget _primaryButton({required String label, required VoidCallback onTap, bool loading = false}) {
  return GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: loading
            ? null
            : const LinearGradient(colors: [AppColors.primary600, AppColors.primaryTeal]),
        color: loading ? AppColors.gray200 : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: loading
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary600.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    ),
  );
}
