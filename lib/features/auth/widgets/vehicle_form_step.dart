import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/car_api_service.dart';
import '../../../core/theme/theme.dart';

class VehicleFormData {
  String brand;
  String model;
  String year;
  String licensePlate;
  String? fuelType;
  String? transmissionType;
  String? driveType;
  String? bodyType;
  String engineDisplacement;
  String color;
  String mileage;

  VehicleFormData({
    this.brand = '',
    this.model = '',
    this.year = '',
    this.licensePlate = '',
    this.fuelType,
    this.transmissionType,
    this.driveType,
    this.bodyType,
    this.engineDisplacement = '',
    this.color = '',
    this.mileage = '',
  });

  bool get isValid => brand.isNotEmpty && model.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'brand': brand,
        'model': model,
        if (year.isNotEmpty) 'year': int.tryParse(year) ?? 0,
        if (licensePlate.isNotEmpty) 'licensePlate': licensePlate,
        if (fuelType != null) 'fuelType': fuelType,
        if (transmissionType != null) 'transmissionType': transmissionType,
        if (driveType != null) 'driveType': driveType,
        if (bodyType != null) 'bodyType': bodyType,
        if (engineDisplacement.isNotEmpty) 'engineDisplacement': engineDisplacement,
        if (color.isNotEmpty) 'color': color,
        if (mileage.isNotEmpty) 'mileage': int.tryParse(mileage),
      };
}

class VehicleFormStep extends ConsumerStatefulWidget {
  final VehicleFormData data;
  final VoidCallback? onChanged;

  const VehicleFormStep({super.key, required this.data, this.onChanged});

  @override
  ConsumerState<VehicleFormStep> createState() => _VehicleFormStepState();
}

class _VehicleFormStepState extends ConsumerState<VehicleFormStep> {
  late TextEditingController _brandCtrl;
  late TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _engineCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _mileageCtrl;
  final TextEditingController _vinCtrl = TextEditingController();

  int? _selectedMakeId;
  String? _selectedModel;

  bool _showVin = false;
  bool _vinLoading = false;
  String? _vinError;
  String? _vinSuccess;

  List<String> _carImages = [];
  bool _imageLoading = false;
  int _imageIndex = 0;
  String _lastFetchedYear = '';

  FocusNode? _brandFocusNode;
  FocusNode? _modelFocusNode;

  @override
  void initState() {
    super.initState();
    _brandCtrl = TextEditingController(text: widget.data.brand);
    _modelCtrl = TextEditingController(text: widget.data.model);
    _yearCtrl = TextEditingController(text: widget.data.year);
    _plateCtrl = TextEditingController(text: widget.data.licensePlate);
    _engineCtrl = TextEditingController(text: widget.data.engineDisplacement);
    _colorCtrl = TextEditingController(text: widget.data.color);
    _mileageCtrl = TextEditingController(text: widget.data.mileage);
    _yearCtrl.addListener(_onYearChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initMakeId());
  }

  void _onYearChanged() {
    final year = _yearCtrl.text.trim();
    if (year == _lastFetchedYear) return;
    if (year.length == 4 || year.isEmpty) {
      _lastFetchedYear = year;
      _fetchCarImage();
    }
  }

  Future<void> _initMakeId() async {
    if (widget.data.brand.isEmpty) return;
    try {
      final makes = await ref.read(carMakesProvider.future);
      final match = makes.firstWhere(
        (m) => m.name.toLowerCase() == widget.data.brand.toLowerCase(),
        orElse: () => const CarMake(id: -1, name: ''),
      );
      if (match.id != -1 && mounted) {
        setState(() {
          _selectedMakeId = match.id;
          _selectedModel = widget.data.model;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _yearCtrl.removeListener(_onYearChanged);
    _brandFocusNode?.removeListener(_onBrandFocusChange);
    _modelFocusNode?.removeListener(_onModelFocusChange);
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _plateCtrl.dispose();
    _engineCtrl.dispose();
    _colorCtrl.dispose();
    _mileageCtrl.dispose();
    _vinCtrl.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged?.call();

  Future<void> _fetchCarImage() async {
    final brand = _brandCtrl.text.trim();
    final model = _selectedModel ?? _modelCtrl.text.trim();
    if (brand.isEmpty || model.isEmpty) {
      setState(() {
        _carImages = [];
        _imageIndex = 0;
      });
      return;
    }
    final year = _yearCtrl.text.trim();
    _lastFetchedYear = year;
    setState(() {
      _imageLoading = true;
      _imageIndex = 0;
    });
    try {
      final params = <String, String>{'make': brand, 'model': model};
      if (year.isNotEmpty) params['year'] = year;
      final res = await ref
          .read(apiClientProvider)
          .get('/api/cars/image', queryParameters: params);
      final data = res.data as Map<String, dynamic>;
      final images = (data['images'] as List?)?.cast<String>() ?? [];
      if (mounted) {
        setState(() {
          _carImages = images;
          _imageLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _carImages = [];
          _imageLoading = false;
        });
      }
    }
  }

  Future<void> _lookupVin() async {
    final vin = _vinCtrl.text.trim().toUpperCase();
    if (vin.length != 17) {
      setState(() => _vinError = 'VIN 17 karakter olmalıdır');
      return;
    }
    setState(() {
      _vinLoading = true;
      _vinError = null;
      _vinSuccess = null;
    });
    try {
      final res = await ref.read(apiClientProvider).get(
        '/api/vehicles/vin-decode',
        queryParameters: {'vin': vin},
      );
      final data = res.data as Map<String, dynamic>;
      final make = (data['make'] as String?) ?? '';
      final model = (data['model'] as String?) ?? '';
      final year = '${data['year'] ?? ''}';
      _brandCtrl.text = make;
      _modelCtrl.text = model;
      _yearCtrl.text = year;
      widget.data.brand = make;
      widget.data.model = model;
      widget.data.year = year;
      setState(() {
        _vinLoading = false;
        _vinSuccess = 'Araç bilgileri dolduruldu.';
        _selectedMakeId = null;
        _selectedModel = model;
      });
      _notify();
      _fetchCarImage();
    } catch (_) {
      setState(() {
        _vinLoading = false;
        _vinError = 'VIN tanımlanamadı, lütfen tekrar deneyin.';
      });
    }
  }

  void _onBrandFocusChange() {
    if (_brandFocusNode == null) return;
    if (!_brandFocusNode!.hasFocus) {
      final text = _brandCtrl.text.trim();
      final makes = ref.read(carMakesProvider).value ?? [];
      final matched = makes.firstWhere(
        (m) => m.name.toLowerCase() == text.toLowerCase(),
        orElse: () => const CarMake(id: -1, name: ''),
      );
      if (matched.id != -1) {
        _brandCtrl.text = matched.name;
        setState(() {
          widget.data.brand = matched.name;
          _selectedMakeId = matched.id;
        });
      } else {
        setState(() {
          widget.data.brand = text;
          _selectedMakeId = null;
        });
      }
      _notify();
    }
  }

  void _onModelFocusChange() {
    if (_selectedMakeId == null || _modelFocusNode == null) return;
    if (!_modelFocusNode!.hasFocus) {
      final text = _modelCtrl.text.trim();
      final models = ref.read(carModelsProvider(_selectedMakeId!)).value ?? [];
      final matched = models
          .map((m) => m.name)
          .firstWhere((name) => name.toLowerCase() == text.toLowerCase(), orElse: () => '');
      if (matched.isNotEmpty) {
        _modelCtrl.text = matched;
        widget.data.model = matched;
      } else {
        widget.data.model = text;
      }
      _notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(carMakesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VinToggleRow(
          showVin: _showVin,
          onToggle: (v) => setState(() {
            _showVin = v;
            _vinError = null;
            _vinSuccess = null;
          }),
        ),
        if (_showVin) ...[
          const SizedBox(height: 12),
          _VinInputRow(controller: _vinCtrl, loading: _vinLoading, onLookup: _lookupVin),
          if (_vinSuccess != null) _AlertBanner(message: _vinSuccess!, isError: false),
          if (_vinError != null) _AlertBanner(message: _vinError!, isError: true),
        ],
        const SizedBox(height: 16),
        Autocomplete<CarMake>(
          initialValue: TextEditingValue(text: widget.data.brand),
          optionsBuilder: (value) async {
            if (value.text.length < 2) return const Iterable<CarMake>.empty();
            final makes = await ref.read(carMakesProvider.future);
            final q = value.text.toLowerCase();
            return makes.where((m) => m.name.toLowerCase().contains(q)).take(50);
          },
          displayStringForOption: (make) => make.name,
          fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
            _brandCtrl = ctrl;
            if (_brandFocusNode != focusNode) {
              _brandFocusNode?.removeListener(_onBrandFocusChange);
              _brandFocusNode = focusNode;
              _brandFocusNode?.addListener(_onBrandFocusChange);
            }
            return TextFormField(
              controller: ctrl,
              focusNode: focusNode,
              onEditingComplete: onSubmit,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              onChanged: (val) {
                widget.data.brand = val.trim();
                _notify();
              },
              decoration: _inputDecoration(hint: 'Marka (Örn: Renault)'),
              validator: (v) => (v == null || v.isEmpty) ? 'Marka zorunludur' : null,
            );
          },
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final make = options.elementAt(i);
                    return InkWell(
                      onTap: () => onSelected(make),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(make.name,
                            style: const TextStyle(fontSize: 14, color: AppColors.gray900)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          onSelected: (make) {
            _brandCtrl.text = make.name;
            setState(() {
              widget.data.brand = make.name;
              _selectedMakeId = make.id == -1 ? null : make.id;
              _selectedModel = null;
              widget.data.model = '';
              _modelCtrl.clear();
            });
            _notify();
          },
        ),
        const SizedBox(height: 16),
        if (_selectedMakeId != null)
          Consumer(
            builder: (context, ref, _) {
              final modelsAsync = ref.watch(carModelsProvider(_selectedMakeId!));
              return modelsAsync.when(
                loading: () => Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary600),
                    ),
                  ),
                ),
                error: (_, e) => TextFormField(
                  controller: _modelCtrl,
                  decoration: _inputDecoration(hint: 'Model (Örn: Megane)'),
                  onChanged: (v) {
                    widget.data.model = v;
                    _notify();
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Model zorunludur' : null,
                ),
                data: (models) => Autocomplete<String>(
                  initialValue: TextEditingValue(text: widget.data.model),
                  optionsBuilder: (textValue) {
                    if (textValue.text.isEmpty) return models.map((m) => m.name);
                    return models
                        .map((m) => m.name)
                        .where((name) => name.toLowerCase().contains(textValue.text.toLowerCase()));
                  },
                  fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
                    _modelCtrl = ctrl;
                    if (_modelFocusNode != focusNode) {
                      _modelFocusNode?.removeListener(_onModelFocusChange);
                      _modelFocusNode = focusNode;
                      _modelFocusNode?.addListener(_onModelFocusChange);
                    }
                    return TextFormField(
                      controller: ctrl,
                      focusNode: focusNode,
                      onEditingComplete: onSubmit,
                      style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                      decoration: _inputDecoration(hint: 'Model seçin veya yazın'),
                      onChanged: (v) {
                        final normalized = v.trim().toLowerCase();
                        final matched = models
                            .map((m) => m.name)
                            .firstWhere((name) => name.toLowerCase() == normalized, orElse: () => '');
                        widget.data.model = matched.isNotEmpty ? matched : v.trim();
                        _notify();
                      },
                      validator: (v) => v == null || v.isEmpty ? 'Model zorunludur' : null,
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          separatorBuilder: (_, i) => const Divider(height: 1, color: AppColors.gray100),
                          itemBuilder: (context, i) {
                            final name = options.elementAt(i);
                            return InkWell(
                              onTap: () => onSelected(name),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                child: Text(name,
                                    style: const TextStyle(fontSize: 14, color: AppColors.gray900)),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  onSelected: (name) {
                    setState(() {
                      _selectedModel = name;
                      widget.data.model = name;
                    });
                    _modelCtrl.text = name;
                    _notify();
                    _modelFocusNode?.unfocus();
                    _fetchCarImage();
                  },
                ),
              );
            },
          )
        else
          TextFormField(
            controller: _modelCtrl,
            style: const TextStyle(color: AppColors.gray900, fontSize: 14),
            decoration: _inputDecoration(hint: 'Model (Örn: Megane)'),
            onChanged: (v) {
              widget.data.model = v;
              _notify();
            },
            validator: (v) => (v == null || v.isEmpty) ? 'Model zorunludur' : null,
            textInputAction: TextInputAction.next,
          ),
        if (_imageLoading || _carImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          _CarImagePreview(
            images: _carImages,
            loading: _imageLoading,
            currentIndex: _imageIndex,
            onPageChanged: (i) => setState(() => _imageIndex = i),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _yearCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                onChanged: (v) {
                  widget.data.year = v;
                  _notify();
                },
                decoration: _inputDecoration(hint: 'Yıl (Opsiyonel)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _plateCtrl,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                onChanged: (v) {
                  widget.data.licensePlate = v.toUpperCase();
                  _plateCtrl.value = _plateCtrl.value.copyWith(
                    text: v.toUpperCase(),
                    selection: TextSelection.collapsed(offset: v.length),
                  );
                  _notify();
                },
                decoration: _inputDecoration(hint: 'Plaka (Opsiyonel)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Teknik Detaylar (Opsiyonel)'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DropdownField(
                hint: 'Yakıt Tipi',
                value: widget.data.fuelType,
                items: const ['benzin', 'dizel', 'lpg', 'hibrit', 'elektrik'],
                labels: const ['Benzin', 'Dizel', 'LPG', 'Hibrit', 'Elektrik'],
                onChanged: (v) {
                  setState(() => widget.data.fuelType = v);
                  _notify();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DropdownField(
                hint: 'Şanzıman',
                value: widget.data.transmissionType,
                items: const ['manuel', 'otomatik', 'yariOtomatik'],
                labels: const ['Manuel', 'Otomatik', 'Yarı Otomatik'],
                onChanged: (v) {
                  setState(() => widget.data.transmissionType = v);
                  _notify();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _engineCtrl,
                style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                decoration: _inputDecoration(hint: 'Motor Hacmi (Örn: 1.6)'),
                textInputAction: TextInputAction.next,
                onChanged: (v) {
                  widget.data.engineDisplacement = v;
                  _notify();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DropdownField(
                hint: 'Çekiş',
                value: widget.data.driveType,
                items: const ['fwd', 'rwd', 'awd', '4wd'],
                labels: const ['Önden Çekiş', 'Arkadan İtiş', 'AWD', '4x4'],
                onChanged: (v) {
                  setState(() => widget.data.driveType = v);
                  _notify();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DropdownField(
                hint: 'Kasa Tipi',
                value: widget.data.bodyType,
                items: const [
                  'sedan', 'hatchback', 'suv', 'coupe', 'station', 'pickup', 'minivan',
                ],
                labels: const [
                  'Sedan', 'Hatchback', 'SUV', 'Coupe', 'Station Wagon', 'Pickup', 'Minivan',
                ],
                onChanged: (v) {
                  setState(() => widget.data.bodyType = v);
                  _notify();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _colorCtrl,
                style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                decoration: _inputDecoration(hint: 'Renk'),
                textInputAction: TextInputAction.next,
                onChanged: (v) {
                  widget.data.color = v;
                  _notify();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _mileageCtrl,
          style: const TextStyle(color: AppColors.gray900, fontSize: 14),
          decoration: _inputDecoration(hint: 'Kilometre').copyWith(suffixText: 'km'),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onChanged: (v) {
            widget.data.mileage = v;
            _notify();
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint}) => InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: AppColors.gray50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary600),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red700),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red700),
        ),
        hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
      );
}

// ─── VIN Section ─────────────────────────────────────────────────────────────

class _VinToggleRow extends StatelessWidget {
  final bool showVin;
  final ValueChanged<bool> onToggle;

  const _VinToggleRow({required this.showVin, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VIN ile otomatik doldur',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray900),
              ),
              Text(
                '17 haneli şasi numarasıyla sorgula',
                style: TextStyle(fontSize: 12, color: AppColors.gray500),
              ),
            ],
          ),
          Switch(
            value: showVin,
            onChanged: onToggle,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary600,
          ),
        ],
      ),
    );
  }
}

class _VinInputRow extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onLookup;

  const _VinInputRow({required this.controller, required this.loading, required this.onLookup});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(17),
              _UpperCaseFormatter(),
            ],
            style: const TextStyle(
              fontFamily: 'monospace',
              letterSpacing: 1.5,
              fontSize: 13,
              color: AppColors.gray900,
            ),
            decoration: InputDecoration(
              hintText: 'JTDBT923X71234567',
              hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
              filled: true,
              fillColor: AppColors.gray50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 48,
          width: 90,
          child: ElevatedButton(
            onPressed: loading ? null : onLookup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Sorgula', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _AlertBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isError ? AppColors.red50 : AppColors.success50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isError ? AppColors.red100 : AppColors.emerald200),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: isError ? AppColors.red700 : AppColors.primary600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: isError ? AppColors.red700 : AppColors.primary700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) =>
      next.copyWith(text: next.text.toUpperCase());
}

// ─── Car Image Preview ────────────────────────────────────────────────────────

class _CarImagePreview extends StatelessWidget {
  final List<String> images;
  final bool loading;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _CarImagePreview({
    required this.images,
    required this.loading,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 200,
        color: AppColors.gray100,
        child: loading
            ? const _ShimmerBox()
            : images.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car_outlined, size: 48, color: AppColors.gray300),
                        SizedBox(height: 8),
                        Text('Görsel bulunamadı',
                            style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                      ],
                    ),
                  )
                : _buildCarousel(),
      ),
    );
  }

  Widget _buildCarousel() {
    final controller = PageController();
    return Stack(
      children: [
        PageView.builder(
          controller: controller,
          itemCount: images.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, i) => Image.network(
            images[i],
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : const _ShimmerBox(),
            errorBuilder: (_, e, s) => const Center(
              child: Icon(Icons.broken_image_outlined, size: 40, color: AppColors.gray300),
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == currentIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == currentIndex ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        if (images.length > 1)
          Positioned(
            top: 8,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${currentIndex + 1}/${images.length}',
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, v) => Container(color: Color.fromRGBO(209, 213, 219, _anim.value)),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.gray400,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Dropdown Field ───────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final List<String> labels;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.labels,
    required this.onChanged,
  });

  String? get _selectedLabel {
    if (value == null) return null;
    final i = items.indexOf(value!);
    return i >= 0 ? labels[i] : null;
  }

  void _open(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(hint,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                  if (value != null)
                    GestureDetector(
                      onTap: () {
                        onChanged(null);
                        Navigator.pop(sheetCtx);
                      },
                      child: const Text('Temizle',
                          style: TextStyle(fontSize: 13, color: AppColors.gray500)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.gray100),
            ...List.generate(
              items.length,
              (i) => InkWell(
                onTap: () {
                  onChanged(items[i]);
                  Navigator.pop(sheetCtx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                value == items[i] ? FontWeight.w600 : FontWeight.w400,
                            color: value == items[i]
                                ? AppColors.primary600
                                : AppColors.gray700,
                          ),
                        ),
                      ),
                      if (value == items[i])
                        const Icon(Icons.check_rounded, size: 18, color: AppColors.primary600),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: bottomPad + 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedLabel;
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected != null ? AppColors.primary600 : AppColors.gray200,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected ?? hint,
                style: TextStyle(
                  fontSize: 13,
                  color: selected != null ? AppColors.gray900 : AppColors.gray400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: selected != null ? AppColors.primary600 : AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}
