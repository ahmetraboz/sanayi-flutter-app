import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/theme.dart';
import '../../../core/constants/turkey_cities.dart';
import '../../../shared/widgets/app_select_field.dart';
import '../../../shared/models/provider_model.dart';
import '../../booking/booking_repository.dart';
import '../../booking/widgets/damage_analysis_widget.dart';
import '../../booking/models/booking_form_data.dart';
import '../vehicles/widgets/vehicle_form_sheet.dart';
import '../../../shared/widgets/date_picker_sheet.dart';
import 'create_request_providers.dart';

const _categories = [
  _Category('motor', 'Motor', Icons.local_fire_department_outlined, Color(0xFFFEF2F2), Color(0xFFEF4444)),
  _Category('elektrik', 'Elektrik', Icons.bolt_outlined, Color(0xFFFEFCE8), Color(0xFFEAB308)),
  _Category('fren', 'Fren', Icons.radio_button_checked_outlined, Color(0xFFFFF7ED), Color(0xFFF97316)),
  _Category('suspan', 'Süspansiyon', Icons.tune_outlined, Color(0xFFEFF6FF), Color(0xFF3B82F6)),
  _Category('kaporta', 'Kaporta', Icons.brush_outlined, Color(0xFFFAF5FF), Color(0xFFA855F7)),
  _Category('klima', 'Klima', Icons.wb_sunny_outlined, Color(0xFFECFEFF), Color(0xFF06B6D4)),
  _Category('lastik', 'Lastik', Icons.circle_outlined, Color(0xFFF8FAFC), Color(0xFF64748B)),
  _Category('vites', 'Vites', Icons.settings_outlined, Color(0xFFEEF2FF), Color(0xFF6366F1)),
  _Category('egzoz', 'Egzoz', Icons.cloud_outlined, Color(0xFFECFDF5), Color(0xFF10B981)),
  _Category('diger', 'Diğer', Icons.help_outline, Color(0xFFF9FAFB), Color(0xFF9CA3AF)),
];

const _urgencyOptions = [
  _Urgency('low', 'Acele Değil', 'Uygun zamanda bakılabilir', Icons.access_time_outlined, Color(0xFF059669), Color(0xFFECFDF5), Color(0xFF6EE7B7)),
  _Urgency('normal', 'Normal', 'Bu hafta içinde', Icons.calendar_today_outlined, Color(0xFFD97706), Color(0xFFFFFBEB), Color(0xFFFCD34D)),
  _Urgency('urgent', 'Acil', 'En kısa sürede', Icons.warning_amber_outlined, Color(0xFFDC2626), Color(0xFFFEF2F2), Color(0xFFFCA5A5)),
];

class _Category {
  final String value;
  final String label;
  final IconData icon;
  final Color bg;
  final Color color;
  const _Category(this.value, this.label, this.icon, this.bg, this.color);
}

class _Urgency {
  final String value;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  const _Urgency(this.value, this.label, this.description, this.icon, this.color, this.bg, this.border);
}

class CreateRequestScreen extends ConsumerStatefulWidget {
  final int? preselectedServiceId;
  final String? preselectedServiceName;

  const CreateRequestScreen({
    super.key,
    this.preselectedServiceId,
    this.preselectedServiceName,
  });

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  int _step = 1;
  static const int _totalSteps = 4;

  // Step 1
  String? _category;

  // Step 2
  String _urgency = 'normal';
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _imageUrl;
  bool _uploadingImage = false;
  bool _hasDamage = false;
  List<DamageReport> _damageReports = [];
  String? _preferredDateFrom;
  String? _preferredDateTo;

  // Step 3
  int? _vehicleId;

  // Step 4
  String? _selectedCity;
  List<int> _selectedServiceIds = [];

  bool _submitting = false;

  final Map<String, String?> _errors = {};

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() => _errors.clear());
    if (_step == 1) {
      if (_category == null) {
        setState(() => _errors['category'] = 'Lütfen bir kategori seçin');
        return false;
      }
    } else if (_step == 2) {
      bool ok = true;
      if (_titleCtrl.text.trim().length < 3) {
        _errors['title'] = 'Başlık en az 3 karakter olmalıdır';
        ok = false;
      }
      if (_descCtrl.text.trim().length < 10) {
        _errors['desc'] = 'Açıklama en az 10 karakter olmalıdır';
        ok = false;
      }
      if (!ok) { setState(() {}); return false; }
    } else if (_step == 3) {
      if (_vehicleId == null) {
        setState(() => _errors['vehicle'] = 'Lütfen bir araç seçin');
        return false;
      }
    } else if (_step == 4) {
      if (_selectedCity == null || _selectedServiceIds.isEmpty) {
        setState(() => _errors['services'] = 'İl ve en az bir servis seçmelisiniz');
        return false;
      }
    }
    return true;
  }

  void _next() {
    if (!_validate()) return;
    if (_step < _totalSteps) setState(() => _step++);
  }

  void _back() {
    if (_step > 1) setState(() => _step--);
  }

  Future<void> _showAddVehicleSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const VehicleFormSheet(),
    );
    ref.invalidate(userVehiclesProvider);
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    setState(() => _uploadingImage = true);
    try {
      final url = await ref.read(bookingRepositoryProvider).uploadImage(file);
      setState(() { _imageUrl = url; _uploadingImage = false; });
    } catch (_) {
      setState(() => _uploadingImage = false);
    }
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _submitting = true);
    try {
      final data = {
        'vehicleId': _vehicleId,
        'problemCategory': _category,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'urgencyLevel': _urgency,
        'targetCity': _selectedCity,
        'targetServiceIds': _selectedServiceIds,
        if (_imageUrl != null) 'imageUrl': _imageUrl,
        if (_preferredDateFrom != null) 'preferredDateFrom': _preferredDateFrom,
        if (_preferredDateTo != null) 'preferredDateTo': _preferredDateTo,
        if (widget.preselectedServiceId != null) 'targetProviderId': widget.preselectedServiceId,
        if (_damageReports.isNotEmpty)
          'damageReports': _damageReports.map((r) => r.toJson()).toList(),
      };
      await ref.read(submitRequestProvider(data).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Talebiniz başarıyla oluşturuldu!'),
          backgroundColor: AppColors.green700,
        ));
        context.go('/dashboard/requests');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Hata: $e'),
        backgroundColor: AppColors.red700,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Yeni Talep Oluştur',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                children: [
                  if (widget.preselectedServiceName != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.blue600.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline, color: AppColors.blue600, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          '${widget.preselectedServiceName} servisine doğrudan iletilecektir.',
                          style: const TextStyle(color: AppColors.blue800, fontSize: 13),
                        )),
                      ]),
                    ),
                  _buildCurrentStep(),
                  const SizedBox(height: 24),
                  _buildNavigation(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const labels = ['Sorun', 'Detaylar', 'Araç', 'Servis'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            final stepNum = (i ~/ 2) + 1;
            return Expanded(
              child: Container(
                height: 2,
                color: _step > stepNum ? AppColors.primary600.withValues(alpha: 0.5) : AppColors.gray100,
              ),
            );
          }
          final stepNum = (i ~/ 2) + 1;
          final done = _step > stepNum;
          final active = _step == stepNum;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 36 : 32,
                height: active ? 36 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? AppColors.primary600.withValues(alpha: 0.15)
                      : active
                          ? AppColors.primary600
                          : AppColors.gray100,
                  boxShadow: active
                      ? [BoxShadow(color: AppColors.primary600.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 14, color: AppColors.primary600)
                      : Text('$stepNum',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: active ? Colors.white : AppColors.gray400,
                          )),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[stepNum - 1],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _step >= stepNum ? AppColors.primary600 : AppColors.gray400,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    return switch (_step) {
      1 => _buildStep1(),
      2 => _buildStep2(),
      3 => _buildStep3(),
      4 => _buildStep4(),
      _ => const SizedBox(),
    };
  }

  // ── STEP 1: Category ─────────────────────────────────────────────────────
  Widget _buildStep1() {
    return _card(
      title: 'Sorun ne ile ilgili?',
      subtitle: 'Aracınızdaki probleme en uygun kategoriyi seçin',
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: _categories.map((cat) {
              final selected = _category == cat.value;
              return GestureDetector(
                onTap: () => setState(() { _category = cat.value; _errors.remove('category'); }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: selected ? cat.bg : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? cat.color : AppColors.gray200,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: cat.bg, borderRadius: BorderRadius.circular(8)),
                        child: Icon(cat.icon, size: 18, color: cat.color),
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: Text(cat.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? cat.color : AppColors.gray700,
                          ))),
                      if (selected) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 7, height: 7,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_errors['category'] != null) ...[
            const SizedBox(height: 10),
            _errorText(_errors['category']!),
          ],
        ],
      ),
    );
  }

  // ── STEP 2: Details ───────────────────────────────────────────────────────
  Widget _buildStep2() {
    final selCat = _categories.where((c) => c.value == _category).firstOrNull;
    return _card(
      title: 'Sorunu Anlatın',
      subtitle: 'Servis ustaları için detaylı açıklama yapın',
      titleIcon: selCat != null
          ? Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: selCat.bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(selCat.icon, size: 18, color: selCat.color),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Urgency
          const Text('Ne kadar acil?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900)),
          const SizedBox(height: 10),
          Row(
            children: _urgencyOptions.map((opt) {
              final selected = _urgency == opt.value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _urgency = opt.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(right: opt == _urgencyOptions.last ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? opt.bg : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? opt.border : AppColors.gray200,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(opt.icon, size: 20, color: selected ? opt.color : AppColors.gray400),
                        const SizedBox(height: 4),
                        Text(opt.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: selected ? opt.color : AppColors.gray700,
                            )),
                        const SizedBox(height: 2),
                        Text(opt.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9, color: AppColors.gray500),
                            maxLines: 2),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.gray100),
          const SizedBox(height: 16),

          // Title
          _fieldLabel('Başlık', required: true),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: AppColors.gray900, fontSize: 14),
            onChanged: (_) { if (_errors['title'] != null) setState(() => _errors.remove('title')); },
            decoration: _inputDeco('Örn: Motor yağından ses geliyor, fren tutmuyor...', Icons.edit_outlined,
                error: _errors['title']),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${_titleCtrl.text.length} / 200',
                  style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
            ),
          ),
          const SizedBox(height: 14),

          // Description
          _fieldLabel('Açıklama', required: true),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            minLines: 4,
            maxLines: 6,
            style: const TextStyle(color: AppColors.gray900, fontSize: 14),
            onChanged: (_) { if (_errors['desc'] != null) setState(() => _errors.remove('desc')); },
            decoration: _inputDeco(
              'Sorun ne zaman başladı? Nasıl fark ettiniz? Detaylı anlatın.',
              null,
              error: _errors['desc'],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${_descCtrl.text.length} / min 10',
                  style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
            ),
          ),
          const SizedBox(height: 16),

          // Photo
          _fieldLabel('Fotoğraf (Opsiyonel)'),
          const SizedBox(height: 8),
          _buildPhotoUpload(),
          const SizedBox(height: 16),
          const Divider(color: AppColors.gray100),
          const SizedBox(height: 16),

          // Preferred Date Range
          _fieldLabel('Tercih Ettiğiniz Tarih Aralığı (Opsiyonel)'),
          const SizedBox(height: 4),
          const Text(
            'Hangi tarihler arasında servis almak istediğinizi belirtin.',
            style: TextStyle(fontSize: 12, color: AppColors.gray500),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildDateField(
                label: 'Başlangıç',
                value: _preferredDateFrom,
                onTap: () => _pickDate(
                  title: 'Başlangıç Tarihi',
                  initial: _preferredDateFrom,
                  onSelected: (d) => setState(() {
                    _preferredDateFrom = d;
                    if (_preferredDateTo != null && _preferredDateTo!.compareTo(d) < 0) {
                      _preferredDateTo = null;
                    }
                  }),
                ),
                onClear: _preferredDateFrom != null
                    ? () => setState(() => _preferredDateFrom = null)
                    : null,
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildDateField(
                label: 'Bitiş',
                value: _preferredDateTo,
                onTap: () => _pickDate(
                  title: 'Bitiş Tarihi',
                  initial: _preferredDateTo,
                  highlightFrom: _preferredDateFrom,
                  onSelected: (d) => setState(() => _preferredDateTo = d),
                ),
                onClear: _preferredDateTo != null
                    ? () => setState(() => _preferredDateTo = null)
                    : null,
              )),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.gray100),
          const SizedBox(height: 12),

          // Damage toggle
          GestureDetector(
            onTap: () => setState(() {
              _hasDamage = !_hasDamage;
              if (!_hasDamage) _damageReports = [];
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _hasDamage ? const Color(0xFFFFF7ED) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasDamage ? const Color(0xFFFBBF24) : AppColors.gray200,
                  width: _hasDamage ? 2 : 1,
                ),
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _hasDamage ? const Color(0xFFFEF3C7) : AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.warning_amber_outlined, size: 18,
                      color: _hasDamage ? const Color(0xFFD97706) : AppColors.gray400),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Hasarlı Aracım Var',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: _hasDamage ? const Color(0xFFB45309) : AppColors.gray700,
                        )),
                    const Text('AI ile hasar analizi yapın, servislere otomatik rapor gönderin',
                        style: TextStyle(fontSize: 11, color: AppColors.gray500)),
                  ]),
                ),
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasDamage ? const Color(0xFFF97316) : Colors.transparent,
                    border: Border.all(
                      color: _hasDamage ? const Color(0xFFF97316) : AppColors.gray300,
                    ),
                  ),
                  child: _hasDamage
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ]),
            ),
          ),
          if (_hasDamage) ...[
            const SizedBox(height: 12),
            DamageAnalysisWidget(
              onReportsChanged: (reports) => setState(() => _damageReports = reports),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoUpload() {
    if (_imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(children: [
          Image.network(_imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _imageUrl = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ]),
      );
    }
    return GestureDetector(
      onTap: _uploadingImage ? null : _pickAndUploadImage,
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200, style: BorderStyle.solid),
        ),
        child: _uploadingImage
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary600))
            : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.camera_alt_outlined, size: 28, color: AppColors.gray400),
                SizedBox(height: 6),
                Text('Arıza fotoğrafı ekleyin', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
                Text('JPG, PNG veya WebP', style: TextStyle(fontSize: 11, color: AppColors.gray400)),
              ]),
      ),
    );
  }

  // ── STEP 3: Vehicle ───────────────────────────────────────────────────────
  Widget _buildStep3() {
    return _card(
      title: 'Aracınızı Seçin',
      subtitle: 'Hangi aracınız için servis talep ediyorsunuz?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Araç', required: true),
          const SizedBox(height: 8),
          ref.watch(userVehiclesProvider).when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary600),
            )),
            error: (e, _) => Text('Araçlar yüklenemedi: $e',
                style: const TextStyle(color: AppColors.red700, fontSize: 13)),
            data: (vehicles) {
              if (vehicles.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.directions_car_outlined, color: AppColors.gray400, size: 20),
                    const SizedBox(width: 10),
                    const Text('Henüz araç eklenmemiş. ', style: TextStyle(color: AppColors.gray500, fontSize: 13)),
                    GestureDetector(
                      onTap: () => _showAddVehicleSheet(),
                      child: const Text('Araç Ekle', style: TextStyle(color: AppColors.primary600, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                );
              }
              return DropdownButtonFormField<int>(
                value: _vehicleId,
                dropdownColor: Colors.white,
                style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                hint: const Text('Araç Seçin', style: TextStyle(color: AppColors.gray400, fontSize: 14)),
                decoration: _inputDeco(null, Icons.directions_car_outlined),
                items: vehicles.map((v) {
                  final plate = v.licensePlate != null ? ' - ${v.licensePlate}' : '';
                  return DropdownMenuItem(value: v.id, child: Text('${v.brand} ${v.model}$plate'));
                }).toList(),
                onChanged: (val) => setState(() { _vehicleId = val; _errors.remove('vehicle'); }),
              );
            },
          ),
          if (_errors['vehicle'] != null) ...[
            const SizedBox(height: 6),
            _errorText(_errors['vehicle']!),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showAddVehicleSheet(),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline, size: 14, color: AppColors.gray400),
              const SizedBox(width: 6),
              Flexible(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 12, color: AppColors.gray400),
                    children: [
                      TextSpan(text: 'Araç listesinde görünmüyorsa '),
                      TextSpan(text: 'buradan ekleyebilirsiniz',
                          style: TextStyle(color: AppColors.primary600, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── STEP 4: Service Provider ───────────────────────────────────────────────
  Widget _buildStep4() {
    return _card(
      title: 'Servis Seçimi',
      subtitle: 'Talebinizi göndermek istediğiniz servisleri seçin',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('İlinizi Seçin', required: true),
          const SizedBox(height: 8),
          AppSelectField(
            options: kTurkeyCities,
            value: _selectedCity,
            hintText: 'İl arayın veya seçin...',
            decoration: _inputDeco(null, Icons.location_on_outlined),
            onChanged: (val) => setState(() {
              _selectedCity = val;
              _selectedServiceIds = [];
              _errors.remove('services');
            }),
            validator: (v) => (v == null || v.isEmpty) ? 'İl seçin' : null,
          ),
          const SizedBox(height: 16),
          if (_selectedCity != null) ...[
            _fieldLabel('Servis Sağlayıcı Seçin', required: true),
            const SizedBox(height: 8),
            _buildProviderList(),
          ],
          if (_errors['services'] != null) ...[
            const SizedBox(height: 8),
            _errorText(_errors['services']!),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderList() {
    return ref.watch(providersByCityProvider(_selectedCity!)).when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary600),
      )),
      error: (e, _) => Text('Servisler yüklenemedi: $e',
          style: const TextStyle(color: AppColors.red700, fontSize: 13)),
      data: (providers) {
        if (providers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(children: [
              const Icon(Icons.store_outlined, size: 32, color: AppColors.gray300),
              const SizedBox(height: 8),
              Text('$_selectedCity ilinde henüz kayıtlı doğrulanmış servis sağlayıcı bulunmuyor.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
              const SizedBox(height: 4),
              const Text('Başka bir il seçmeyi deneyin.',
                  style: TextStyle(fontSize: 12, color: AppColors.gray400)),
            ]),
          );
        }
        return Column(
          children: providers.map((p) => _buildProviderTile(p)).toList(),
        );
      },
    );
  }

  Widget _buildProviderTile(ProviderModel p) {
    final selected = _selectedServiceIds.contains(p.id);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _selectedServiceIds.remove(p.id);
        } else {
          _selectedServiceIds.add(p.id);
        }
        _errors.remove('services');
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary600.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary600 : AppColors.gray200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: p.logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(p.logoUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.store_outlined, size: 20, color: AppColors.gray400)),
                  )
                : const Icon(Icons.store_outlined, size: 20, color: AppColors.gray400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(p.companyName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900))),
                if (p.isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, size: 14, color: AppColors.primary600),
                ],
              ]),
              if (p.district != null || p.averageRating != null)
                Text(
                  [if (p.district != null) p.district!, if (p.averageRating != null) '★ ${p.averageRating}'].join(' · '),
                  style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                ),
            ]),
          ),
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.primary600 : Colors.transparent,
              border: Border.all(color: selected ? AppColors.primary600 : AppColors.gray300),
            ),
            child: selected ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
          ),
        ]),
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  Widget _buildNavigation() {
    return Row(
      children: [
        if (_step > 1)
          OutlinedButton.icon(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Geri'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gray700,
              side: const BorderSide(color: AppColors.gray300),
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )
        else
          TextButton.icon(
            onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Vazgeç'),
            style: TextButton.styleFrom(foregroundColor: AppColors.gray500),
          ),
        const Spacer(),
        Text('$_step / $_totalSteps', style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
        const SizedBox(width: 12),
        if (_step < _totalSteps)
          ElevatedButton.icon(
            onPressed: _next,
            icon: const SizedBox.shrink(),
            label: const Row(children: [
              Text('İleri'),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 16),
            ]),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_outlined, size: 16),
            label: const Text('Talep Oluştur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _card({required String title, required String subtitle, required Widget child, Widget? titleIcon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (titleIcon != null) ...[titleIcon, const SizedBox(width: 10)],
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
            ])),
          ]),
          const SizedBox(height: 16),
          const Divider(color: AppColors.gray100),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _pickDate({
    required String title,
    required void Function(String) onSelected,
    String? initial,
    String? highlightFrom,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DatePickerSheet(
        title: title,
        initialDate: initial,
        highlightFrom: highlightFrom,
        onSelected: onSelected,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String? value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value != null ? AppColors.primary600 : AppColors.gray200,
            width: value != null ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 16,
              color: value != null ? AppColors.primary600 : AppColors.gray400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value != null ? formatDateTr(value) : label,
              style: TextStyle(
                fontSize: 13,
                color: value != null ? AppColors.gray900 : AppColors.gray400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onClear != null)
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.close, size: 14, color: AppColors.gray400),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _fieldLabel(String text, {bool required = false}) => Row(children: [
    Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
    if (required) const Text(' *', style: TextStyle(color: AppColors.red700, fontSize: 13)),
  ]);

  Widget _errorText(String msg) => Row(children: [
    const Icon(Icons.error_outline, size: 14, color: AppColors.red700),
    const SizedBox(width: 4),
    Text(msg, style: const TextStyle(fontSize: 12, color: AppColors.red700)),
  ]);

  InputDecoration _inputDeco(String? hint, IconData? icon, {String? error}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
    prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.gray400) : null,
    errorText: error,
    filled: true,
    fillColor: AppColors.gray50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary600, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.red700)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.red700)),
  );
}
