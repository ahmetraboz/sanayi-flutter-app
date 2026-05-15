import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class StepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgress({super.key, required this.currentStep, this.totalSteps = 4});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final step = i + 1;
        final isCompleted = currentStep > step;
        final isActive = currentStep == step;
        return [
          _StepCircle(step: step, isCompleted: isCompleted, isActive: isActive),
          if (i < totalSteps - 1)
            Expanded(
              child: Container(
                height: 2,
                color: isCompleted ? AppColors.primary600 : AppColors.gray200,
              ),
            ),
        ];
      }).expand((e) => e).toList(),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int step;
  final bool isCompleted;
  final bool isActive;

  const _StepCircle({required this.step, required this.isCompleted, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Widget child;

    if (isCompleted) {
      bg = AppColors.primary600;
      child = const Icon(Icons.check, size: 16, color: Colors.white);
    } else if (isActive) {
      bg = AppColors.primary600;
      child = Text(
        '$step',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
      );
    } else {
      bg = AppColors.gray200;
      child = Text(
        '$step',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray500),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(child: child),
    );
  }
}
