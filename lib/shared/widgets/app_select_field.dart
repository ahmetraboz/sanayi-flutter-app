import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class AppSelectField extends StatefulWidget {
  final List<String> options;
  final String? value;
  final String hintText;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  final bool allowClear;
  final InputDecoration? decoration;
  final TextStyle? style;
  final double maxHeight;

  const AppSelectField({
    super.key,
    required this.options,
    required this.hintText,
    required this.onChanged,
    this.value,
    this.validator,
    this.allowClear = false,
    this.decoration,
    this.style,
    this.maxHeight = 220,
  });

  @override
  State<AppSelectField> createState() => _AppSelectFieldState();
}

class _AppSelectFieldState extends State<AppSelectField> {
  FocusNode? _focusNode;
  TextEditingController? _controller;

  String _normalizeTurkish(String input) {
    return input
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ç', 'ç')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ü', 'ü')
        .replaceAll('Ö', 'ö')
        .toLowerCase();
  }

  void _onFocusChange() {
    if (_focusNode == null || _controller == null) return;

    if (!_focusNode!.hasFocus) {
      final text = _controller!.text.trim();
      if (text.isEmpty) {
        widget.onChanged(null);
        return;
      }

      final normalizedQuery = _normalizeTurkish(text);
      final matched = widget.options.firstWhere(
        (o) => _normalizeTurkish(o) == normalizedQuery,
        orElse: () => '',
      );

      if (matched.isNotEmpty) {
        _controller!.text = matched;
        widget.onChanged(matched);
      } else {
        if (widget.value != null && widget.options.contains(widget.value)) {
          _controller!.text = widget.value!;
        } else {
          _controller!.clear();
          widget.onChanged(null);
        }
      }
    }
  }

  @override
  void dispose() {
    _focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  InputDecoration get _defaultDecoration => InputDecoration(
    hintText: widget.hintText,
    hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
    filled: true,
    fillColor: AppColors.gray50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary600)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.red700)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.red700)),
    suffixIcon: widget.allowClear && (widget.value?.isNotEmpty ?? false)
        ? null
        : const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.gray400),
  );

  @override
  Widget build(BuildContext context) {
    final baseDecoration = widget.decoration ?? _defaultDecoration;
    final hasValue = widget.value?.isNotEmpty ?? false;

    return Autocomplete<String>(
      key: ValueKey(widget.value),
      initialValue: TextEditingValue(text: widget.value ?? ''),
      optionsBuilder: (textValue) {
        if (textValue.text.isEmpty) return widget.options;
        return widget.options.where(
          (o) => o.toLowerCase().contains(textValue.text.toLowerCase()),
        );
      },
      fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
        _controller = ctrl;
        if (_focusNode != focusNode) {
          _focusNode?.removeListener(_onFocusChange);
          _focusNode = focusNode;
          _focusNode?.addListener(_onFocusChange);
        }
        return TextFormField(
          controller: ctrl,
          focusNode: focusNode,
          style: widget.style ?? const TextStyle(color: AppColors.gray900, fontSize: 14),
          decoration: baseDecoration.copyWith(
            suffixIcon: widget.allowClear && hasValue
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.gray400),
                    onPressed: () {
                      ctrl.clear();
                      widget.onChanged(null);
                    },
                  )
                : baseDecoration.suffixIcon ?? const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.gray400),
          ),
          validator: widget.validator != null
              ? (v) => widget.validator!(v?.isEmpty == true ? null : v)
              : null,
          onChanged: (v) {
            if (v.isEmpty) {
              widget.onChanged(null);
              return;
            }
            final normalizedQuery = _normalizeTurkish(v.trim());
            final matched = widget.options.firstWhere(
              (o) => _normalizeTurkish(o) == normalizedQuery,
              orElse: () => '',
            );
            widget.onChanged(matched.isNotEmpty ? matched : null);
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
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
    );
  }
}
