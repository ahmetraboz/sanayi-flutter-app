import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/car_api_service.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/app_select_field.dart';
import '../guest_booking_notifier.dart';

const _kFuelTypes = ['Benzin', 'Dizel', 'LPG', 'Hibrit', 'Elektrik'];
const _kTransmissions = ['Manuel', 'Otomatik', 'Yarı Otomatik'];

class BookingStep2 extends ConsumerStatefulWidget {
  const BookingStep2({super.key});

  @override
  ConsumerState<BookingStep2> createState() => _BookingStep2State();
}

class _BookingStep2State extends ConsumerState<BookingStep2> {
  late final TextEditingController _vinCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _engineCtrl;
  late final TextEditingController _mileageCtrl;
  int? _selectedMakeId;

  @override
  void initState() {
    super.initState();
    final form = ref.read(guestBookingProvider).form;
    _vinCtrl = TextEditingController(text: form.chassisCode);
    _modelCtrl = TextEditingController(text: form.model);
    _yearCtrl = TextEditingController(text: form.year);
    _colorCtrl = TextEditingController(text: form.color);
    _plateCtrl = TextEditingController(text: form.licensePlate);
    _engineCtrl = TextEditingController(text: form.engineDisplacement);
    _mileageCtrl = TextEditingController(text: form.mileage);
    if (form.brand.isNotEmpty) {
      final service = ref.read(carApiServiceProvider);
      final match = service.filterMakes(form.brand);
      if (match.isNotEmpty && match.first.name == form.brand) {
        _selectedMakeId = match.first.id;
      }
    }
  }

  @override
  void dispose() {
    _vinCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _plateCtrl.dispose();
    _engineCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guestBookingProvider);
    final notifier = ref.read(guestBookingProvider.notifier);
    final errors = state.errors;
    final form = state.form;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggle(form.useChassisMode, notifier),
        const SizedBox(height: 20),
        if (form.useChassisMode) ...[
          _buildVinSection(state, notifier, errors),
        ] else ...[
          _buildManualForm(form, notifier, errors),
        ],
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _outlinedButton(label: 'Geri', onTap: notifier.previousStep)),
            const SizedBox(width: 12),
            Expanded(child: _primaryButton(label: 'İleri', onTap: notifier.validateAndNext)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildToggle(bool useChassisMode, GuestBookingNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Şasi ile sorgula', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray900)),
              const Text('VIN / şasi numarasıyla otomatik doldurun', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
            ],
          ),
          Switch(
            value: useChassisMode,
            onChanged: notifier.toggleChassisMode,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary600,
          ),
        ],
      ),
    );
  }

  Widget _buildVinSection(GuestBookingState state, GuestBookingNotifier notifier, Map<String, String?> errors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Şasi / VIN Numarası'),
        const SizedBox(height: 6),
        TextField(
          controller: _vinCtrl,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(20),
          ],
          style: const TextStyle(fontFamily: 'monospace', letterSpacing: 1.5),
          onChanged: notifier.updateChassisCode,
          decoration: _inputDecoration(hint: 'JTDBT923X71234567', error: errors['chassis']),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: state.vinLookupLoading
                ? null
                : () => notifier.lookupVin(_vinCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: state.vinLookupLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Sorgula', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        if (state.vinLookupSuccess) ...[
          const SizedBox(height: 12),
          _successAlert('Araç bilgileri otomatik dolduruldu.'),
        ],
        if (state.vinError != null) ...[
          const SizedBox(height: 12),
          _errorAlert(state.vinError!),
        ],
      ],
    );
  }

  Widget _buildManualForm(dynamic form, GuestBookingNotifier notifier, Map<String, String?> errors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Marka'),
                  const SizedBox(height: 6),
                  _BrandAutocomplete(
                    initialValue: form.brand,
                    error: errors['brand'],
                    onSelected: (make) {
                      setState(() {
                        _selectedMakeId = make.id == -1 ? null : make.id;
                        _modelCtrl.clear();
                      });
                      notifier.updateBrand(make.name);
                      notifier.updateModel('');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Model'),
                  const SizedBox(height: 6),
                  if (_selectedMakeId != null)
                    _ModelDropdown(
                      makeId: _selectedMakeId!,
                      value: form.model.isEmpty ? null : form.model,
                      error: errors['model'],
                      onChanged: (v) {
                        notifier.updateModel(v ?? '');
                        _modelCtrl.text = v ?? '';
                      },
                    )
                  else
                    TextField(
                      controller: _modelCtrl,
                      textInputAction: TextInputAction.next,
                      onChanged: notifier.updateModel,
                      decoration: _inputDecoration(hint: 'Örn: Corolla', error: errors['model']),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Yıl'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onChanged: notifier.updateYear,
                    decoration: _inputDecoration(hint: '2020'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Renk'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _colorCtrl,
                    textInputAction: TextInputAction.next,
                    onChanged: notifier.updateColor,
                    decoration: _inputDecoration(hint: 'Beyaz'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _label('Plaka'),
        const SizedBox(height: 6),
        TextField(
          controller: _plateCtrl,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          onChanged: (v) {
            final upper = v.toUpperCase();
            notifier.updateLicensePlate(upper);
            _plateCtrl.value = _plateCtrl.value.copyWith(
              text: upper,
              selection: TextSelection.collapsed(offset: upper.length),
            );
          },
          decoration: _inputDecoration(hint: '34 ABC 123'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Yakıt Tipi'),
                  const SizedBox(height: 6),
                  _dropdownField(
                    value: form.fuelType.isEmpty ? null : form.fuelType,
                    hint: 'Seçin',
                    items: _kFuelTypes,
                    onChanged: notifier.updateFuelType,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Şanzıman'),
                  const SizedBox(height: 6),
                  _dropdownField(
                    value: form.transmissionType.isEmpty ? null : form.transmissionType,
                    hint: 'Seçin',
                    items: _kTransmissions,
                    onChanged: notifier.updateTransmission,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Motor Hacmi'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _engineCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    onChanged: notifier.updateEngineDisplacement,
                    decoration: _inputDecoration(hint: '1.6'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Kilometre'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _mileageCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onChanged: notifier.updateMileage,
                    decoration: _inputDecoration(hint: '85000'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

}

Widget _dropdownField({
  required String? value,
  required String hint,
  required List<String> items,
  required ValueChanged<String?> onChanged,
  String? error,
}) {
  return AppSelectField(
    options: items,
    value: value,
    hintText: hint,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: error != null ? AppColors.red700 : AppColors.gray200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary600)),
    ),
    onChanged: onChanged,
  );
}

class _BrandAutocomplete extends ConsumerStatefulWidget {
  final String initialValue;
  final String? error;
  final ValueChanged<CarMake> onSelected;

  const _BrandAutocomplete({
    required this.initialValue,
    required this.onSelected,
    this.error,
  });

  @override
  ConsumerState<_BrandAutocomplete> createState() => _BrandAutocompleteState();
}

class _BrandAutocompleteState extends ConsumerState<_BrandAutocomplete> {
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
      fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
        _controller = ctrl;
        if (_focusNode != focusNode) {
          _focusNode?.removeListener(_onFocusChange);
          _focusNode = focusNode;
          _focusNode?.addListener(_onFocusChange);
        }
        return TextField(
          controller: ctrl,
          focusNode: focusNode,
          onEditingComplete: onSubmit,
          textInputAction: TextInputAction.next,
          onChanged: _onTextChange,
          decoration: _inputDecoration(hint: 'Marka ara...', error: widget.error),
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
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

class _ModelDropdown extends ConsumerStatefulWidget {
  final int makeId;
  final String? value;
  final String? error;
  final ValueChanged<String?> onChanged;

  const _ModelDropdown({
    required this.makeId,
    required this.onChanged,
    this.value,
    this.error,
  });

  @override
  ConsumerState<_ModelDropdown> createState() => _ModelDropdownState();
}

class _ModelDropdownState extends ConsumerState<_ModelDropdown> {
  FocusNode? _focusNode;
  TextEditingController? _controller;

  void _onFocusChange() {
    if (_focusNode == null || _controller == null) return;

    if (!_focusNode!.hasFocus) {
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
    _focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(carModelsProvider(widget.makeId));

    return modelsAsync.when(
      loading: () => Container(
        height: 48,
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
      error: (err, stackTrace) => TextField(
        decoration: _inputDecoration(hint: 'Model girin', error: widget.error),
        onChanged: (v) => widget.onChanged(v),
      ),
      data: (models) => Autocomplete<String>(
        key: ValueKey(widget.value),
        initialValue: TextEditingValue(text: widget.value ?? ''),
        optionsBuilder: (textValue) {
          if (textValue.text.isEmpty) return models.map((m) => m.name);
          return models.map((m) => m.name).where(
            (name) => name.toLowerCase().contains(textValue.text.toLowerCase()),
          );
        },
        fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
          _controller = ctrl;
          if (_focusNode != focusNode) {
            _focusNode?.removeListener(_onFocusChange);
            _focusNode = focusNode;
            _focusNode?.addListener(_onFocusChange);
          }
          return TextField(
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
            decoration: _inputDecoration(hint: 'Model seçin veya yazın', error: widget.error),
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
          _focusNode?.unfocus();
        },
      ),
    );
  }
}

Widget _successAlert(String message) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF6EE7B7)),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF059669)),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFF065F46)))),
      ],
    ),
  );
}

Widget _errorAlert(String message) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.red50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.red100),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, size: 18, color: AppColors.red700),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.red700))),
      ],
    ),
  );
}

Widget _label(String text) => Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700),
    );

InputDecoration _inputDecoration({String? hint, String? error}) => InputDecoration(
      hintText: hint,
      errorText: error,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary600)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.red700)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.red700)),
      hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
    );

Widget _primaryButton({required String label, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary600, AppColors.primaryTeal]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.primary600.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))),
    ),
  );
}

Widget _outlinedButton({required String label, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.gray700))),
    ),
  );
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    return next.copyWith(text: next.text.toUpperCase());
  }
}
