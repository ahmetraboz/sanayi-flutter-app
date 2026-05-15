import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class ReviewForm extends StatefulWidget {
  final bool submitting;
  final bool submitted;
  final String? error;
  final void Function(int rating, String comment) onSubmit;

  const ReviewForm({
    super.key,
    required this.submitting,
    required this.submitted,
    this.error,
    required this.onSubmit,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  int _rating = 0;
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.submitted) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.emerald200),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, size: 32, color: AppColors.primary600),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Değerlendirmeniz Alındı!',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary600)),
                  SizedBox(height: 2),
                  Text('Geri bildiriminiz için teşekkürler.',
                      style: TextStyle(fontSize: 13, color: AppColors.primary600)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Servisini Değerlendir',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aldığınız hizmeti puanlayın.',
            style: TextStyle(fontSize: 13, color: AppColors.gray500),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: i < _rating ? const Color(0xFFFBBF24) : AppColors.gray200,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Yorumunuzu yazın (isteğe bağlı)...',
              contentPadding: const EdgeInsets.all(14),
              filled: true,
              fillColor: AppColors.gray50,
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
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 10),
            Text(widget.error!,
                style: const TextStyle(fontSize: 13, color: AppColors.red700)),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: (_rating == 0 || widget.submitting)
                ? null
                : () => widget.onSubmit(_rating, _commentCtrl.text.trim()),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: (_rating == 0 || widget.submitting)
                    ? null
                    : const LinearGradient(colors: [AppColors.primary600, AppColors.primaryTeal]),
                color: (_rating == 0 || widget.submitting) ? AppColors.gray200 : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: widget.submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        _rating == 0 ? 'Puan seçin' : 'Değerlendirmeyi Gönder',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _rating == 0 ? AppColors.gray400 : Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
