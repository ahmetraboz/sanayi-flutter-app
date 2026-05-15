import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../models/pending_provider.dart';

class PendingApprovalsSection extends StatelessWidget {
  final List<PendingProvider> providers;
  final int? actioningId;
  final String? actionError;
  final void Function(int id) onApprove;
  final void Function(int id) onReject;

  const PendingApprovalsSection({
    super.key,
    required this.providers,
    this.actioningId,
    this.actionError,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            const Text(
              'Onay Bekleyen Servisler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900),
            ),
            if (providers.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '${providers.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (actionError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.red50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.red100),
            ),
            child: Text(
              actionError!,
              style: const TextStyle(fontSize: 13, color: AppColors.red700),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gray200),
          ),
          child: providers.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 36, color: AppColors.green700),
                        SizedBox(height: 8),
                        Text(
                          'Onay bekleyen servis yok',
                          style: TextStyle(fontSize: 14, color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: providers.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, thickness: 1, color: AppColors.gray100),
                  itemBuilder: (context, index) {
                    final p = providers[index];
                    return _ProviderRow(
                      provider: p,
                      isActioning: actioningId == p.id,
                      onApprove: () => onApprove(p.id),
                      onReject: () => onReject(p.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ProviderRow extends StatelessWidget {
  final PendingProvider provider;
  final bool isActioning;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ProviderRow({
    required this.provider,
    required this.isActioning,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.business_outlined, size: 18, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.companyName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                Text(
                  provider.city ?? 'Şehir bilgisi yok',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isActioning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF4F46E5),
              ),
            )
          else
            Row(
              children: [
                _ActionButton(
                  label: 'Onayla',
                  color: const Color(0xFF059669),
                  bg: const Color(0xFFECFDF5),
                  onTap: onApprove,
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  label: 'Reddet',
                  color: AppColors.red700,
                  bg: AppColors.red50,
                  onTap: onReject,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}
