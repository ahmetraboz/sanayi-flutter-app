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
  final TextEditingController _vinController = TextEditingController();

  bool _isSubmitting = false;
  bool _showVin = false;
  bool _vinLoading = false;
  String? _vinError;
  String? _vinSuccess;
  int? _selectedMakeId;
  String? _selectedModel;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.vehicle?.brand ?? '');
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _yearController = TextEditingController(text: widget.vehicle?.year?.toString() ?? '');
    _plateController = TextEditingController(text: widget.vehicle?.licensePlate ?? '');
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _vinController.dispose();
    super.dispose();
  }

  Future<void> _lookupVin() async {
    final vin = _vinController.text.trim().toUpperCase();
    if (vin.length != 17) {
      setState(() => _vinError = 'VIN 17 karakter olmalıdır');
      return;
    }
    setState(() { _vinLoading = true; _vinError = null; _vinSuccess = null; });
    try {
      final res = await ref.read(apiClientProvider).get(
        '/api/vehicles/vin-decode',
        queryParameters: {'vin': vin},
      );
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
    } catch (e) {
      setState(() { _vinLoading = false; _vinError = 'VIN tanımlanamadı, lütfen tekrar deneyin.'; });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    final data = {
      'brand': _brandController.text.trim(),
      'model': _modelController.text.trim(),
      if (_yearController.text.trim().isNotEmpty) 'year': int.tryParse(_yearController.text.trim()),
      if (_plateController.text.trim().isNotEmpty) 'licensePlate': _plateController.text.trim().toUpperCase(),
    };

    try {
      final api = ref.read(apiClientProvider);
      debugPrint('Vehicle submit data: $data');
      if (widget.vehicle != null) {
        await api.put('/api/vehicles/${widget.vehicle!.id}', data: data);
      } else {
        await api.post('/api/vehicles', data: data);
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vehicle != null ? 'Araç güncellendi' : 'Araç eklendi'),
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
            msg = d['statusMessage'] as String? ?? d['message'] as String? ?? msg;
          }
          debugPrint('Vehicle API error: ${e.response?.statusCode} ${e.response?.data}');
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900),
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
                onToggle: (v) => setState(() { _showVin = v; _vinError = null; _vinSuccess = null; }),
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
                  _selectedMakeId = make.id;
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
                },
              )
            else
              TextFormField(
                controller: _modelController,
                style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                decoration: _inputDecoration('Model (Örn: Megane)'),
                validator: (v) => v == null || v.isEmpty ? 'Model zorunludur' : null,
                textInputAction: TextInputAction.next,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                    decoration: _inputDecoration('Yıl (Opsiyonel)'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _plateController,
                    style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                    decoration: _inputDecoration('Plaka (Opsiyonel)'),
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.vehicle != null ? 'Güncelle' : 'Kaydet', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
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
      fieldViewBuilder: (context, ctrl, focusNode, onSubmit) => TextFormField(
        controller: ctrl,
        focusNode: focusNode,
        onEditingComplete: onSubmit,
        textInputAction: TextInputAction.next,
        style: const TextStyle(color: AppColors.gray900, fontSize: 14),
        decoration: _sheetInputDecoration('Marka (Örn: Renault)'),
        validator: (v) => v == null || v.isEmpty ? 'Marka zorunludur' : null,
      ),
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
                    child: Text(make.name, style: const TextStyle(fontSize: 14, color: AppColors.gray900)),
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

  const _VehicleModelField({required this.makeId, required this.onChanged, this.value});

  @override
  ConsumerState<_VehicleModelField> createState() => _VehicleModelFieldState();
}

class _VehicleModelFieldState extends ConsumerState<_VehicleModelField> {
  FocusNode? _autocompleteFocusNode;

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(carModelsProvider(widget.makeId));

    return modelsAsync.when(
      loading: () => Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary600))),
      ),
      error: (err, stack) => TextFormField(
        decoration: _sheetInputDecoration('Model (Örn: Megane)'),
        onChanged: (v) => widget.onChanged(v),
        validator: (v) => v == null || v.isEmpty ? 'Model zorunludur' : null,
      ),
      data: (models) => Autocomplete<String>(
        initialValue: TextEditingValue(text: widget.value ?? ''),
        optionsBuilder: (textValue) {
          if (textValue.text.isEmpty) return models.map((m) => m.name);
          return models.map((m) => m.name).where(
            (name) => name.toLowerCase().contains(textValue.text.toLowerCase()),
          );
        },
        fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
          _autocompleteFocusNode = focusNode;
          return TextFormField(
            controller: ctrl,
            focusNode: focusNode,
            onEditingComplete: onSubmit,
            style: const TextStyle(color: AppColors.gray900, fontSize: 14),
            decoration: _sheetInputDecoration('Model seçin veya yazın'),
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
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray100),
                itemBuilder: (context, i) {
                  final name = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(name),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      child: Text(name, style: const TextStyle(fontSize: 14, color: AppColors.gray900)),
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
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary600)),
  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.red700)),
  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.red700)),
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
              const Text('VIN ile otomatik doldur', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray900)),
              const Text('17 haneli şasi numarasıyla sorgula', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
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
            style: const TextStyle(fontFamily: 'monospace', letterSpacing: 1.5, fontSize: 13, color: AppColors.gray900),
            decoration: InputDecoration(
              hintText: 'JTDBT923X71234567',
              hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
              filled: true,
              fillColor: AppColors.gray50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary600)),
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
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
              style: TextStyle(fontSize: 12, color: isError ? AppColors.red700 : AppColors.primary700),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    return next.copyWith(text: next.text.toUpperCase());
  }
}
