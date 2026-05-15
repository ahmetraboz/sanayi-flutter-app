import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../models/guest_tracking_models.dart';

class QuoteCard extends StatelessWidget {
  final QuoteResponse quote;
  final bool responding;
  final ValueChanged<String> onRespond;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.responding,
    required this.onRespond,
  });

  bool get _isAccepted => quote.guestStatus == 'accepted';
  bool get _isRejected => quote.guestStatus == 'rejected';

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isRejected ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isAccepted ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isAccepted ? const Color(0xFF6EE7B7) : AppColors.gray200,
            width: _isAccepted ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (quote.note != null && quote.note!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                quote.note!,
                style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.5),
              ),
            ],
            if (quote.estimatedDuration != null && quote.estimatedDuration!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.access_time_outlined, size: 14, color: AppColors.gray400),
                const SizedBox(width: 4),
                Text(quote.estimatedDuration!,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
              ]),
            ],
            if (quote.guestStatus == null) ...[
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: responding ? null : () => _confirmReject(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gray600,
                      side: const BorderSide(color: AppColors.gray200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text('Reddet', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: responding ? null : () => _confirmAccept(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(0, 44),
                    ),
                    child: responding
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Kabul Et', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ],
            if (_isAccepted) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Kabul Edildi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quote.companyName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900),
              ),
              if (quote.city != null && quote.city!.isNotEmpty)
                Text(quote.city!, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
            ],
          ),
        ),
        Text(
          '₺${quote.price}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary600,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    if (quote.logoUrl != null && quote.logoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: CachedNetworkImageProvider(quote.logoUrl!),
        backgroundColor: AppColors.gray100,
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.info50,
      child: Text(
        quote.companyName.isNotEmpty ? quote.companyName[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6)),
      ),
    );
  }

  void _confirmAccept(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Teklifi Kabul Et', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          '${quote.companyName} firmasından ₺${quote.price} tutarındaki teklifi kabul etmek istediğinizden emin misiniz?',
          style: const TextStyle(fontSize: 14, color: AppColors.gray600, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç', style: TextStyle(color: AppColors.gray500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onRespond('accept');
            },
            child: const Text('Kabul Et', style: TextStyle(color: AppColors.primary600, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmReject(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Teklifi Reddet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
          'Bu teklifi reddetmek istediğinizden emin misiniz?',
          style: TextStyle(fontSize: 14, color: AppColors.gray600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç', style: TextStyle(color: AppColors.gray500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onRespond('reject');
            },
            child: const Text('Reddet', style: TextStyle(color: AppColors.red700, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
