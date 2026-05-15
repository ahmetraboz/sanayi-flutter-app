import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import 'guest_booking_notifier.dart';
import 'widgets/booking_step1.dart';
import 'widgets/booking_step2.dart';
import 'widgets/booking_step3.dart';
import 'widgets/booking_step4.dart';
import 'widgets/step_progress.dart';

const _kStepTitles = [
  'Talebinizi Oluşturun',
  'Araç Bilgisi',
  'İletişim Bilgileri',
  'Tamamlandı',
];

class GuestBookingScreen extends ConsumerStatefulWidget {
  final int? preselectedServiceId;
  final String? preselectedCity;

  const GuestBookingScreen({
    super.key,
    this.preselectedServiceId,
    this.preselectedCity,
  });

  @override
  ConsumerState<GuestBookingScreen> createState() => _GuestBookingScreenState();
}

class _GuestBookingScreenState extends ConsumerState<GuestBookingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(guestBookingProvider.notifier).init(
            preselectedServiceId: widget.preselectedServiceId,
            preselectedCity: widget.preselectedCity,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guestBookingProvider);
    final titleIndex = (state.currentStep - 1).clamp(0, 3);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _kStepTitles[titleIndex],
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
        ),
        leading: state.currentStep > 1 && state.currentStep < 4
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
                onPressed: ref.read(guestBookingProvider.notifier).previousStep,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
                onPressed: () => context.canPop() ? context.pop() : context.go('/'),
              ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.currentStep < 4) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: StepProgress(currentStep: state.currentStep),
              ),
            ],
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(state.currentStep),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 672),
                        child: _buildStep(state.currentStep),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    return switch (step) {
      1 => const BookingStep1(),
      2 => const BookingStep2(),
      3 => const BookingStep3(),
      4 => const BookingStep4(),
      _ => const SizedBox.shrink(),
    };
  }
}
