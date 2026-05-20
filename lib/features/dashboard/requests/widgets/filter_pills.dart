import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

typedef _Filter = ({String? value, String label, IconData icon, Color color});

const _kFilters = <_Filter>[
  (value: null, label: 'Tüm Talepler', icon: Icons.list_alt_outlined, color: Color(0xFF6B7280)),
  (value: 'open', label: 'Açık', icon: Icons.access_time_outlined, color: Color(0xFF3B82F6)),
  (value: 'info_requested', label: 'Yanıt Gerekiyor', icon: Icons.help_outline_rounded, color: Color(0xFFF59E0B)),
  (value: 'accepted', label: 'Devam Ediyor', icon: Icons.build_outlined, color: Color(0xFFD97706)),
  (value: 'pending_review', label: 'Değerlendir', icon: Icons.star_border_outlined, color: Color(0xFF8B5CF6)),
  (value: 'completed', label: 'Tamamlandı', icon: Icons.check_circle_outline, color: Color(0xFF059669)),
  (value: 'rejected', label: 'Reddedildi', icon: Icons.cancel_outlined, color: Color(0xFFEF4444)),
];

class FilterPills extends StatelessWidget {
  final String? activeFilter;
  final ValueChanged<String?> onChanged;

  const FilterPills({
    super.key,
    required this.activeFilter,
    required this.onChanged,
  });

  _Filter get _active => _kFilters.firstWhere(
        (f) => f.value == activeFilter,
        orElse: () => _kFilters.first,
      );

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetContext) => _FilterSheet(
        activeFilter: activeFilter,
        onChanged: (val) {
          Navigator.of(sheetContext).pop();
          onChanged(val);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    final isFiltered = activeFilter != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isFiltered) ...[
            GestureDetector(
              onTap: () => onChanged(null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.gray400),
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: () => _showSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isFiltered ? active.color.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFiltered ? active.color.withValues(alpha: 0.4) : AppColors.gray200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: isFiltered ? active.color : AppColors.gray500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isFiltered ? active.label : 'Filtrele',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isFiltered ? active.color : AppColors.gray600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: isFiltered ? active.color : AppColors.gray400,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final String? activeFilter;
  final ValueChanged<String?> onChanged;

  const _FilterSheet({required this.activeFilter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Durum Filtrele',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._kFilters.map((f) {
              final isActive = activeFilter == f.value;
              return InkWell(
                onTap: () => onChanged(f.value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: f.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(f.icon, size: 18, color: f.color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          f.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? f.color : AppColors.gray700,
                          ),
                        ),
                      ),
                      if (isActive)
                        Icon(Icons.check_rounded, size: 18, color: f.color),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: bottomPad + 12),
          ],
        ),
    );
  }
}
