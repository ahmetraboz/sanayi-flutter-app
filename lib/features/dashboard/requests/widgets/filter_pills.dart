import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

typedef _Filter = ({String? value, String label, IconData icon});

const _kFilters = <_Filter>[
  (value: null, label: 'Tümü', icon: Icons.list),
  (value: 'open', label: 'Açık', icon: Icons.radio_button_unchecked),
  (value: 'in_progress', label: 'Devam Eden', icon: Icons.build_outlined),
  (
    value: 'pending_review',
    label: 'Değerlendirme',
    icon: Icons.star_border_outlined,
  ),
  (value: 'completed', label: 'Tamamlandı', icon: Icons.check_circle_outline),
];

class FilterPills extends StatelessWidget {
  final String? activeFilter;
  final ValueChanged<String?> onChanged;

  const FilterPills({
    super.key,
    required this.activeFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children:
            _kFilters.map((f) {
              final active = activeFilter == f.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onChanged(f.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary600 : Colors.white,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color:
                            active ? AppColors.primary600 : AppColors.gray200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          f.icon,
                          size: 15,
                          color: active ? Colors.white : AppColors.gray500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          f.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: active ? Colors.white : AppColors.gray700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
