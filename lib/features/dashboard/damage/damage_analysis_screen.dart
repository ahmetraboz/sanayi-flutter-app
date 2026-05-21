import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../booking/widgets/damage_analysis_widget.dart';
import '../../booking/models/booking_form_data.dart';

class DamageAnalysisScreen extends StatefulWidget {
  const DamageAnalysisScreen({super.key});

  @override
  State<DamageAnalysisScreen> createState() => _DamageAnalysisScreenState();
}

class _DamageAnalysisScreenState extends State<DamageAnalysisScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        title: const Text(
          'AI Hasar Analizi',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_fix_high_outlined, size: 20, color: Color(0xFFD97706)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hasarlı bölgeyi seçin, fotoğraf yükleyin — yapay zeka hasar raporunu otomatik oluştursun.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DamageAnalysisWidget(
              onReportsChanged: (_) {},
            ),
          ],
        ),
      ),
    );
  }
}
