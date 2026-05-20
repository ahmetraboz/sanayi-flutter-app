import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/theme.dart';
import '../booking_repository.dart';
import '../models/booking_form_data.dart';

class DamageAnalysisWidget extends ConsumerStatefulWidget {
  final ValueChanged<List<DamageReport>> onReportsChanged;

  const DamageAnalysisWidget({super.key, required this.onReportsChanged});

  @override
  ConsumerState<DamageAnalysisWidget> createState() => _DamageAnalysisWidgetState();
}

const _kCarParts = [
  'Ön Tampon',
  'Arka Tampon',
  'Ön Kaput',
  'Sol Ön Kapı',
  'Sağ Ön Kapı',
  'Sol Arka Kapı',
  'Sağ Arka Kapı',
  'Sol Çamurluk',
  'Sağ Çamurluk',
  'Tavan',
  'Bagaj Kapağı',
  'Ön Cam',
  'Arka Cam',
];

class _DamageAnalysisWidgetState extends ConsumerState<DamageAnalysisWidget> {
  bool _loading = false;
  String? _error;
  List<DamageReport> _reports = [];
  String? _selectedPart;

  void _openPartPicker() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final maxHeight = MediaQuery.of(context).size.height * 0.75;
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
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
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hasar Bölgesi Seçin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (_selectedPart != null)
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedPart = null);
                          Navigator.pop(sheetCtx);
                        },
                        child: const Text(
                          'Temizle',
                          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(bottom: bottomPad + 16),
                  itemCount: _kCarParts.length,
                  separatorBuilder: (_, i) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (context, i) {
                    final part = _kCarParts[i];
                    final selected = _selectedPart == part;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedPart = part);
                        Navigator.pop(sheetCtx);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                part,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                  color: selected ? const Color(0xFFD97706) : const Color(0xFF374151),
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_rounded, size: 18, color: Color(0xFFD97706)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndAnalyze() async {
    if (_selectedPart == null) {
      _openPartPicker();
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(bookingRepositoryProvider);
      final reports = await repo.analyzeDamage(file, userPart: _selectedPart!);
      setState(() {
        _reports = reports;
        _loading = false;
      });
      widget.onReportsChanged(reports);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : 'Analiz yapılamadı';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_error != null) _buildError(),
          if (_reports.isNotEmpty) _buildReports(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high_outlined, size: 20, color: Color(0xFFD97706)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Hasar Analizi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Fotoğraf yükleyerek otomatik hasar tespiti yapın.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _openPartPicker,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedPart ?? 'Hasar bölgesi seçin',
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedPart != null
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFFB45309),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _loading ? null : _pickAndAnalyze,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _loading
                        ? const Color(0xFFE5E7EB)
                        : _selectedPart == null
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFD97706),
                          ),
                        )
                      : Text(
                          _reports.isEmpty ? 'Fotoğraf Seç' : 'Yeniden',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _selectedPart == null
                                ? const Color(0xFFB45309)
                                : Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        _error!,
        style: const TextStyle(fontSize: 12, color: AppColors.red700),
      ),
    );
  }

  Widget _buildReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: Color(0xFFFDE68A)),
        ..._reports.map((r) => _ReportItem(report: r)),
      ],
    );
  }
}

class _ReportItem extends StatefulWidget {
  final DamageReport report;

  const _ReportItem({required this.report});

  @override
  State<_ReportItem> createState() => _ReportItemState();
}

class _ReportItemState extends State<_ReportItem> {
  bool _showAnnotated = true;

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.part,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: report.damageCount > 0
                      ? const Color(0xFFFEE2E2)
                      : AppColors.green50,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  report.damageCount > 0
                      ? '${report.damageCount} hasar'
                      : 'Hasar yok',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: report.damageCount > 0
                        ? AppColors.red700
                        : AppColors.green700,
                  ),
                ),
              ),
            ],
          ),
          if (report.annotatedUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _ImageToggle(
                  label: 'Orijinal',
                  active: !_showAnnotated,
                  onTap: () => setState(() => _showAnnotated = false),
                ),
                const SizedBox(width: 6),
                _ImageToggle(
                  label: 'Analiz',
                  active: _showAnnotated,
                  onTap: () => setState(() => _showAnnotated = true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: _showAnnotated ? report.annotatedUrl : report.originalUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 180,
                  color: AppColors.gray100,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (report.damages.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...report.damages.map((d) => _DamageRow(damage: d)),
          ],
        ],
      ),
    );
  }
}

class _ImageToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ImageToggle({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFD97706) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? const Color(0xFFD97706) : const Color(0xFFFDE68A),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFFB45309),
          ),
        ),
      ),
    );
  }
}

class _DamageRow extends StatelessWidget {
  final Map<String, dynamic> damage;

  const _DamageRow({required this.damage});

  @override
  Widget build(BuildContext context) {
    final confidence = ((damage['confidence'] as num? ?? 0) * 100).round();
    final region = damage['region'] as String? ?? '';
    final areaPct = (damage['areaPct'] as num?)?.toStringAsFixed(1) ?? '0.0';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFD97706),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              region,
              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
          Text(
            'Alan: $areaPct%',
            style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$confidence%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.red700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
