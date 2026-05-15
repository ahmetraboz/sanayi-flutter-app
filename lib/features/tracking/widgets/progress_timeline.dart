import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

const _kSteps = ['Talep Alındı', 'Teklifler', 'Onaylandı', 'Serviste', 'Tamamlandı'];

int _statusToStep(String status) => switch (status) {
      'new' => 0,
      'quotes' || 'bidding' => 1,
      'confirmed' || 'accepted' => 2,
      'in_progress' => 3,
      'completed' => 4,
      _ => 0,
    };

class ProgressTimeline extends StatelessWidget {
  final String status;

  const ProgressTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final currentStep = _statusToStep(status);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(5, (i) {
            final isCompleted = currentStep > i;
            final isActive = currentStep == i;
            return [
              _StepCircle(index: i, isCompleted: isCompleted, isActive: isActive),
              if (i < 4)
                Expanded(
                  child: Container(
                    height: 2,
                    color: currentStep > i ? AppColors.primary600 : AppColors.gray200,
                  ),
                ),
            ];
          }).expand((e) => e).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (i) {
            final isActive = currentStep == i;
            final isCompleted = currentStep > i;
            return [
              SizedBox(
                width: 40,
                child: Text(
                  _kSteps[i],
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive || isCompleted ? AppColors.primary600 : AppColors.gray400,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (i < 4) const Expanded(child: SizedBox()),
            ];
          }).expand((e) => e).toList(),
        ),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int index;
  final bool isCompleted;
  final bool isActive;

  const _StepCircle({required this.index, required this.isCompleted, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.primary600
            : isActive
                ? AppColors.success50
                : AppColors.gray100,
        shape: BoxShape.circle,
        border: isActive
            ? Border.all(color: AppColors.primary600, width: 2)
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.primary600 : AppColors.gray400,
                ),
              ),
      ),
    );
  }
}
