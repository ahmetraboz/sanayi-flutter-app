import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/theme.dart';

class ImageUploadArea extends StatelessWidget {
  final String? imageUrl;
  final bool isUploading;
  final ValueChanged<XFile> onImageSelected;

  const ImageUploadArea({
    super.key,
    required this.imageUrl,
    required this.isUploading,
    required this.onImageSelected,
  });

  Future<void> _pick() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) onImageSelected(file);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: isUploading ? null : _pick,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: hasImage ? AppColors.primary600 : AppColors.gray300,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildContent(hasImage),
        ),
      ),
    );
  }

  Widget _buildContent(bool hasImage) {
    if (isUploading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary600),
        ),
      );
    }
    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
      );
    }
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.upload_outlined, size: 32, color: AppColors.gray400),
        SizedBox(height: 8),
        Text(
          'Görsel Yükle',
          style: TextStyle(fontSize: 14, color: AppColors.gray400, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 4),
        Text(
          'Galeriden seçin',
          style: TextStyle(fontSize: 12, color: AppColors.gray400),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 2.0;
    const dashLength = 8.0;
    const gapLength = 4.0;
    const radius = 12.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      const Radius.circular(radius),
    );

    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gapLength;
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => color != old.color;
}
