import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/car_api_service.dart';
import '../../../../core/theme/theme.dart';
import '../models/vehicle_detail.dart';
import '../vehicles_list_notifier.dart';

class VehicleFormSheet extends ConsumerStatefulWidget {
  final VehicleDetail? vehicle;

  const VehicleFormSheet({super.key, this.vehicle});

  @override
  ConsumerState<VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends ConsumerState<VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _plateController;
  late final TextEditingController _engineController;
  late final TextEditingController _colorController;
  late final TextEditingController _mileageController;
  final TextEditingController _vinController = TextEditingController();

  String? _fuelType;
  String? _transmissionType;
  String? _driveType;
  String? _bodyType;

  bool _isSubmitting = false;
  bool _showVin = false;
  bool _vinLoading = false;
  String? _vinError;
  String? _vinSuccess;
  int? _selectedMakeId;
  String? _selectedModel;

  List<String> _carImages = [];
  bool _imageLoading = false;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.vehicle?.brand ?? '');
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _yearController = TextEditingController(
      text: widget.vehicle?.year?.toString() ?? '',
    );
    _plateController = TextEditingController(
      text: widget.vehicle?.licensePlate ?? '',
    );
    _engineController = TextEditingController(
      text: widget.vehicle?.engineDisplacement ?? '',
    );
    _colorController = TextEditingController(text: widget.vehicle?.color ?? '');
    _mileageController = TextEditingController(
      text: widget.vehicle?.mileage?.toString() ?? '',
    );
    _fuelType = widget.vehicle?.fuelType;
    _transmissionType = widget.vehicle?.transmissionType;
    _driveType = widget.vehicle?.driveType;
    _bodyType = widget.vehicle?.bodyType;
    _yearController.addListener(_onYearChanged);
  }

  String _lastFetchedYear = '';

  void _onYearChanged() {
    final year = _yearController.text.trim();
    if (year == _lastFetchedYear) return;
    if (year.length == 4 || year.isEmpty) {
      _lastFetchedYear = year;
      _fetchCarImage();
    }
  }

  @override
  void dispose() {
    _yearController.removeListener(_onYearChanged);
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _engineController.dispose();
    _colorController.dispose();
    _mileageController.dispose();
    _vinController.dispose();
    super.dispose();
  }

  Future<void> _fetchCarImage() async {
    final brand = _brandController.text.trim();
    final model = _selectedModel ?? _modelController.text.trim();
    if (brand.isEmpty || model.isEmpty) {
      setState(() {
        _carImages = [];
        _imageIndex = 0;
      });
      return;
    }
    final year = _yearController.text.trim();
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
      if (mounted)
        setState(() {
          _carImages = images;
          _imageLoading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _carImages = [];
          _imageLoading = false;
        });
    }
  }

  Future<void> _lookupVin() async {
    final vin = _vinController.text.trim().toUpperCase();
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
      final res = await ref
          .read(apiClientProvider)
          .get('/api/vehicles/vin-decode', queryParameters: {'vin': vin});
      final data = res.data as Map<String, dynamic>;
      final make = (data['make'] as String?) ?? '';
      final model = (data['model'] as String?) ?? '';
      _brandController.text = make;
      _modelController.text = model;
      _yearController.text = '${data['year'] ?? ''}';
      setState(() {
        _vinLoading = false;
        _vinSuccess = 'Araç bilgileri dolduruldu.';
        _selectedMakeId = null;
        _selectedModel = model;
      });
      _fetchCarImage();
    } catch (e) {
      setState(() {
        _vinLoading = false;
        _vinError = 'VIN tanımlanamadı, lütfen tekrar deneyin.';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      'brand': _brandController.text.trim(),
      'model': _modelController.text.trim(),
      if (_yearController.text.trim().isNotEmpty)
        'year': int.tryParse(_yearController.text.trim()),
      if (_plateController.text.trim().isNotEmpty)
        'licensePlate': _plateController.text.trim().toUpperCase(),
      if (_fuelType != null) 'fuelType': _fuelType,
      if (_transmissionType != null) 'transmissionType': _transmissionType,
      if (_driveType != null) 'driveType': _driveType,
      if (_bodyType != null) 'bodyType': _bodyType,
      if (_engineController.text.trim().isNotEmpty)
        'engineDisplacement': _engineController.text.trim(),
      if (_colorController.text.trim().isNotEmpty)
        'color': _colorController.text.trim(),
      if (_mileageController.text.trim().isNotEmpty)
        'mileage': int.tryParse(_mileageController.text.trim()),
    };

    try {
      final api = ref.read(apiClientProvider);
      debugPrint('Vehicle submit data: $data');
      Map<String, dynamic>? addedVehicle;
      if (widget.vehicle != null) {
        await api.put('/api/vehicles/${widget.vehicle!.id}', data: data);
      } else {
        final res = await api.post('/api/vehicles', data: data);
        final resData = res.data;
        if (resData is Map<String, dynamic> && resData.containsKey('vehicle')) {
          addedVehicle = resData['vehicle'] as Map<String, dynamic>?;
        }
      }

      if (mounted) {
        Navigator.pop(context, addedVehicle);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.vehicle != null ? 'Araç güncellendi' : 'Araç eklendi',
            ),
            backgroundColor: AppColors.green700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Araç eklenemedi';
        if (e is DioException) {
          final d = e.response?.data;
          if (d is Map) {
            msg =
                d['statusMessage'] as String? ?? d['message'] as String? ?? msg;
          }
          debugPrint(
            'Vehicle API error: ${e.response?.statusCode} ${e.response?.data}',
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.red700),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: bottomInset > 0 ? bottomInset : bottomPad + 100,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.vehicle != null ? 'Aracı Düzenle' : 'Yeni Araç Ekle',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.gray500),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  if (widget.vehicle == null) ...[
                    const SizedBox(height: 8),
                    _VinToggleRow(
                      showVin: _showVin,
                      onToggle:
                          (v) => setState(() {
                            _showVin = v;
                            _vinError = null;
                            _vinSuccess = null;
                          }),
                    ),
                    if (_showVin) ...[
                      const SizedBox(height: 12),
                      _VinInputRow(
                        controller: _vinController,
                        loading: _vinLoading,
                        onLookup: _lookupVin,
                      ),
                      if (_vinSuccess != null)
                        _AlertBanner(message: _vinSuccess!, isError: false),
                      if (_vinError != null)
                        _AlertBanner(message: _vinError!, isError: true),
                    ],
                  ],
                  const SizedBox(height: 16),
                  _VehicleBrandField(
                    controller: _brandController,
                    initialValue: widget.vehicle?.brand ?? '',
                    onSelected: (make) {
                      _brandController.text = make.name;
                      setState(() {
                        _selectedMakeId = make.id == -1 ? null : make.id;
                        _selectedModel = null;
                        _modelController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedMakeId != null)
                    _VehicleModelField(
                      makeId: _selectedMakeId!,
                      value: _selectedModel,
                      onChanged: (v) {
                        setState(() => _selectedModel = v);
                        _modelController.text = v ?? '';
                        if (v != null) _fetchCarImage();
                      },
                    )
                  else
                    TextFormField(
                      controller: _modelController,
                      style: const TextStyle(
                        color: AppColors.gray900,
                        fontSize: 14,
                      ),
                      decoration: _inputDecoration('Model (Örn: Megane)'),
                      validator:
                          (v) => v == null || v.isEmpty ? 'Model zorunludur' : null,
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
                          controller: _yearController,
                          style: const TextStyle(
                            color: AppColors.gray900,
                            fontSize: 14,
                          ),
                          decoration: _inputDecoration('Yıl (Opsiyonel)'),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _plateController,
                          style: const TextStyle(
                            color: AppColors.gray900,
                            fontSize: 14,
                          ),
                          decoration: _inputDecoration('Plaka (Opsiyonel)'),
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
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
                          value: _fuelType,
                          items: const [
                            'benzin',
                            'dizel',
                            'lpg',
                            'hibrit',
                            'elektrik',
                          ],
                          labels: const [
                            'Benzin',
                            'Dizel',
                            'LPG',
                            'Hibrit',
                            'Elektrik',
                          ],
                          onChanged: (v) => setState(() => _fuelType = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownField(
                          hint: 'Şanzıman',
                          value: _transmissionType,
                          items: const ['manuel', 'otomatik', 'yariOtomatik'],
                          labels: const ['Manuel', 'Otomatik', 'Yarı Otomatik'],
                          onChanged: (v) => setState(() => _transmissionType = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _engineController,
                          style: const TextStyle(
                            color: AppColors.gray900,
                            fontSize: 14,
                          ),
                          decoration: _inputDecoration('Motor Hacmi (Örn: 1.6)'),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownField(
                          hint: 'Çekiş',
                          value: _driveType,
                          items: const ['fwd', 'rwd', 'awd', '4wd'],
                          labels: const [
                            'Önden Çekiş',
                            'Arkadan İtiş',
                            'AWD',
                            '4x4',
                          ],
                          onChanged: (v) => setState(() => _driveType = v),
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
                          value: _bodyType,
                          items: const [
                            'sedan',
                            'hatchback',
                            'suv',
                            'coupe',
                            'station',
                            'pickup',
                            'minivan',
                          ],
                          labels: const [
                            'Sedan',
                            'Hatchback',
                            'SUV',
                            'Coupe',
                            'Station Wagon',
                            'Pickup',
                            'Minivan',
                          ],
                          onChanged: (v) => setState(() => _bodyType = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _colorController,
                          style: const TextStyle(
                            color: AppColors.gray900,
                            fontSize: 14,
                          ),
                          decoration: _inputDecoration('Renk'),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mileageController,
                    style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                    decoration: _inputDecoration(
                      'Kilometre',
                    ).copyWith(suffixText: 'km'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    key: const Key('vehicle_save_button'),
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              widget.vehicle != null ? 'Güncelle' : 'Kaydet',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => _sheetInputDecoration(hint);
}

// ─── Brand Autocomplete ───────────────────────────────────────────────────────

class _VehicleBrandField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String initialValue;
  final ValueChanged<CarMake> onSelected;

  const _VehicleBrandField({
    required this.controller,
    required this.initialValue,
    required this.onSelected,
  });

  @override
  ConsumerState<_VehicleBrandField> createState() => _VehicleBrandFieldState();
}

class _VehicleBrandFieldState extends ConsumerState<_VehicleBrandField> {
  FocusNode? _focusNode;
  TextEditingController? _controller;

  void _onTextChange(String val) {
    final makes = ref.read(carMakesProvider).value ?? [];
    final normalized = val.trim().toLowerCase();

    final matched = makes.firstWhere(
      (m) => m.name.toLowerCase() == normalized,
      orElse: () => const CarMake(id: -1, name: ''),
    );

    if (matched.id != -1) {
      widget.onSelected(matched);
    } else {
      widget.onSelected(CarMake(id: -1, name: val.trim()));
    }
  }

  void _onFocusChange() {
    if (_focusNode == null || _controller == null) return;

    if (!_focusNode!.hasFocus) {
      final text = _controller!.text.trim();
      final makes = ref.read(carMakesProvider).value ?? [];

      final normalized = text.toLowerCase();
      final matched = makes.firstWhere(
        (m) => m.name.toLowerCase() == normalized,
        orElse: () => const CarMake(id: -1, name: ''),
      );

      if (matched.id != -1) {
        _controller!.text = matched.name;
        widget.onSelected(matched);
      } else {
        widget.onSelected(CarMake(id: -1, name: text));
      }
    }
  }

  @override
  void dispose() {
    _focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(carMakesProvider);
    final service = ref.read(carApiServiceProvider);

    return Autocomplete<CarMake>(
      initialValue: TextEditingValue(text: widget.initialValue),
      optionsBuilder: (value) {
        if (value.text.length < 2) return const Iterable<CarMake>.empty();
        return service.filterMakes(value.text);
      },
      displayStringForOption: (make) => make.name,
      fieldViewBuilder:
          (context, ctrl, focusNode, onSubmit) {
            _controller = ctrl;
            if (_focusNode != focusNode) {
              _focusNode?.removeListener(_onFocusChange);
              _focusNode = focusNode;
              _focusNode?.addListener(_onFocusChange);
            }
            return TextFormField(
              key: const Key('vehicle_brand_field'),
              controller: ctrl,
              focusNode: focusNode,
              onEditingComplete: onSubmit,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              onChanged: _onTextChange,
              decoration: _sheetInputDecoration('Marka (Örn: Renault)'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Marka zorunludur' : null,
            );
          },
      optionsViewBuilder:
          (context, onSelected, options) => Align(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          make.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      onSelected: widget.onSelected,
    );
  }
}

// ─── Model Dropdown ───────────────────────────────────────────────────────────

class _VehicleModelField extends ConsumerStatefulWidget {
  final int makeId;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _VehicleModelField({
    required this.makeId,
    required this.onChanged,
    this.value,
  });

  @override
  ConsumerState<_VehicleModelField> createState() => _VehicleModelFieldState();
}

class _VehicleModelFieldState extends ConsumerState<_VehicleModelField> {
  FocusNode? _autocompleteFocusNode;
  TextEditingController? _controller;

  void _onFocusChange() {
    if (_autocompleteFocusNode == null || _controller == null) return;

    if (!_autocompleteFocusNode!.hasFocus) {
      final text = _controller!.text.trim();
      final models = ref.read(carModelsProvider(widget.makeId)).value ?? [];

      final normalized = text.toLowerCase();
      final matched = models.map((m) => m.name).firstWhere(
        (name) => name.toLowerCase() == normalized,
        orElse: () => '',
      );

      if (matched.isNotEmpty) {
        _controller!.text = matched;
        widget.onChanged(matched);
      } else {
        widget.onChanged(text);
      }
    }
  }

  @override
  void dispose() {
    _autocompleteFocusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(carModelsProvider(widget.makeId));

    return modelsAsync.when(
      loading:
          () => Container(
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary600,
                ),
              ),
            ),
          ),
      error:
          (err, stack) => TextFormField(
            decoration: _sheetInputDecoration('Model (Örn: Megane)'),
            onChanged: (v) => widget.onChanged(v),
            validator:
                (v) => v == null || v.isEmpty ? 'Model zorunludur' : null,
          ),
      data:
          (models) => Autocomplete<String>(
            initialValue: TextEditingValue(text: widget.value ?? ''),
            optionsBuilder: (textValue) {
              if (textValue.text.isEmpty) return models.map((m) => m.name);
              return models
                  .map((m) => m.name)
                  .where(
                    (name) => name.toLowerCase().contains(
                      textValue.text.toLowerCase(),
                    ),
                  );
            },
            fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
              _controller = ctrl;
              if (_autocompleteFocusNode != focusNode) {
                _autocompleteFocusNode?.removeListener(_onFocusChange);
                _autocompleteFocusNode = focusNode;
                _autocompleteFocusNode?.addListener(_onFocusChange);
              }
              return TextFormField(
                controller: ctrl,
                focusNode: focusNode,
                onEditingComplete: onSubmit,
                onChanged: (v) {
                  final normalized = v.trim().toLowerCase();
                  final matched = models.map((m) => m.name).firstWhere(
                    (name) => name.toLowerCase() == normalized,
                    orElse: () => '',
                  );
                  widget.onChanged(matched.isNotEmpty ? matched : v.trim());
                },
                style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                decoration: _sheetInputDecoration('Model seçin veya yazın'),
                validator:
                    (v) => v == null || v.isEmpty ? 'Model zorunludur' : null,
              );
            },
            optionsViewBuilder:
                (context, onSelected, options) => Align(
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
                        separatorBuilder:
                            (_, __) => const Divider(
                              height: 1,
                              color: AppColors.gray100,
                            ),
                        itemBuilder: (context, i) {
                          final name = options.elementAt(i);
                          return InkWell(
                            onTap: () => onSelected(name),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.gray900,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            onSelected: (name) {
              widget.onChanged(name);
              _autocompleteFocusNode?.unfocus();
            },
          ),
    );
  }
}

InputDecoration _sheetInputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
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
);

// ─── Vin Section ──────────────────────────────────────────────────────────────

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VIN ile otomatik doldur',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray900,
                ),
              ),
              const Text(
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

  const _VinInputRow({
    required this.controller,
    required this.loading,
    required this.onLookup,
  });

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
              hintStyle: const TextStyle(
                color: AppColors.gray400,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.gray50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                loading
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text(
                      'Sorgula',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
        border: Border.all(
          color: isError ? AppColors.red100 : AppColors.emerald200,
        ),
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
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    return next.copyWith(text: next.text.toUpperCase());
  }
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
        child:
            loading
                ? _buildSkeleton()
                : images.isEmpty
                ? _buildPlaceholder()
                : _buildCarousel(),
      ),
    );
  }

  Widget _buildSkeleton() {
    return const _ShimmerBox();
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 48,
            color: AppColors.gray300,
          ),
          SizedBox(height: 8),
          Text(
            'Görsel bulunamadı',
            style: TextStyle(fontSize: 12, color: AppColors.gray400),
          ),
        ],
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
          itemBuilder:
              (context, i) => Image.network(
                images[i],
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder:
                    (_, child, progress) =>
                        progress == null ? child : const _ShimmerBox(),
                errorBuilder:
                    (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 40,
                        color: AppColors.gray300,
                      ),
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
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
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

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
      builder:
          (_, __) =>
              Container(color: Color.fromRGBO(209, 213, 219, _anim.value)),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

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

// ── Dropdown Field (bottom sheet picker) ─────────────────────────────────────

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
      builder:
          (sheetCtx) => Container(
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
                      Text(
                        hint,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      if (value != null)
                        GestureDetector(
                          onTap: () {
                            onChanged(null);
                            Navigator.pop(sheetCtx);
                          },
                          child: const Text(
                            'Temizle',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.gray500,
                            ),
                          ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              labels[i],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    value == items[i]
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                color:
                                    value == items[i]
                                        ? AppColors.primary600
                                        : AppColors.gray700,
                              ),
                            ),
                          ),
                          if (value == items[i])
                            const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: AppColors.primary600,
                            ),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
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
                  color:
                      selected != null ? AppColors.gray900 : AppColors.gray400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color:
                  selected != null ? AppColors.primary600 : AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}
