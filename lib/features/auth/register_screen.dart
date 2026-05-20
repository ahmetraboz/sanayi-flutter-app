import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/theme/theme.dart';
import 'widgets/step_indicator.dart';
import 'widgets/vehicle_form_step.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _currentStep = 1;

  final _step1Key = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _showPassword = false;

  final _vehicleData = VehicleFormData();

  bool _loading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (!(_step1Key.currentState?.validate() ?? false)) return;
    }
    if (_currentStep == 2) {
      if (!_vehicleData.isValid) {
        setState(() => _errorMessage = 'Lütfen marka ve model alanlarını doldurun');
        return;
      }
    }
    setState(() {
      _errorMessage = '';
      _currentStep++;
    });
  }

  void _prevStep() {
    if (_currentStep > 1) setState(() => _currentStep--);
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    try {
      await ref.read(authNotifierProvider.notifier).register(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            phone: _phoneCtrl.text.trim(),
            role: 'customer',
            vehicle: _vehicleData.toJson(),
            serviceProfile: null,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
          onPressed: () {
            if (_currentStep > 1) {
              _prevStep();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          _stepTitle(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray900),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepIndicator(totalSteps: 3, currentStep: _currentStep),
                const SizedBox(height: 28),
                if (_errorMessage.isNotEmpty) ...[
                  _buildErrorAlert(),
                  const SizedBox(height: 16),
                ],
                _buildCurrentStep(),
                const SizedBox(height: 24),
                _buildStepActions(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Zaten hesabınız var mı? ', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text(
                        'Giriş yapın',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stepTitle() => switch (_currentStep) {
        1 => 'Kişisel Bilgiler',
        2 => 'Araç Bilgisi',
        _ => 'Onay',
      };

  Widget _buildCurrentStep() => switch (_currentStep) {
        1 => _buildStep1(),
        2 => _buildStep2(),
        _ => _buildStep3(),
      };

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labeledField(
            label: 'Ad Soyad',
            child: TextFormField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              decoration: _inputDecoration(hint: 'Ahmet Yılmaz', prefixIcon: Icons.person_outline),
              validator: (v) => (v?.trim().length ?? 0) < 2 ? 'En az 2 karakter giriniz' : null,
            ),
          ),
          const SizedBox(height: 20),
          _labeledField(
            label: 'E-posta',
            child: TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              decoration: _inputDecoration(hint: 'ornek@email.com', prefixIcon: Icons.email_outlined),
              validator: (v) => (v?.contains('@') ?? false) ? null : 'Geçerli e-posta giriniz',
            ),
          ),
          const SizedBox(height: 20),
          _labeledField(
            label: 'Şifre',
            child: TextFormField(
              controller: _passwordCtrl,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              decoration: _inputDecoration(
                hint: '••••••••',
                prefixIcon: Icons.lock_outline,
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _showPassword = !_showPassword),
                  child: Icon(
                    _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.gray400,
                    size: 20,
                  ),
                ),
              ),
              validator: (v) => (v?.length ?? 0) < 6 ? 'En az 6 karakter giriniz' : null,
            ),
          ),
          const SizedBox(height: 20),
          _labeledField(
            label: 'Telefon (isteğe bağlı)',
            child: TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              decoration: _inputDecoration(hint: '5XX XXX XXXX', prefixIcon: Icons.phone_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return VehicleFormStep(
      data: _vehicleData,
      onChanged: () => setState(() {}),
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bilgilerinizi Onaylayın',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray900),
        ),
        const SizedBox(height: 20),
        _SummaryCard(
          title: 'Kişisel Bilgiler',
          icon: Icons.person_outline,
          rows: [
            _SummaryRow('Ad Soyad', _nameCtrl.text),
            _SummaryRow('E-posta', _emailCtrl.text),
            if (_phoneCtrl.text.isNotEmpty) _SummaryRow('Telefon', _phoneCtrl.text),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          title: 'Araç Bilgileri',
          icon: Icons.directions_car_outlined,
          rows: [
            _SummaryRow('Marka / Model', '${_vehicleData.brand} ${_vehicleData.model}'),
            if (_vehicleData.year.isNotEmpty) _SummaryRow('Yıl', _vehicleData.year),
            if (_vehicleData.licensePlate.isNotEmpty)
              _SummaryRow('Plaka', _vehicleData.licensePlate),
            if (_vehicleData.fuelType != null) _SummaryRow('Yakıt', _vehicleData.fuelType!),
            if (_vehicleData.transmissionType != null)
              _SummaryRow('Şanzıman', _vehicleData.transmissionType!),
            if (_vehicleData.color.isNotEmpty) _SummaryRow('Renk', _vehicleData.color),
            if (_vehicleData.mileage.isNotEmpty) _SummaryRow('Km', '${_vehicleData.mileage} km'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.blue600, size: 18),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Hesabınız oluşturulduktan sonra servis taleplerini iletebilirsiniz.',
                  style: TextStyle(fontSize: 13, color: AppColors.blue600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepActions() {
    final isLastStep = _currentStep == 3;
    return GestureDetector(
      onTap: _loading ? null : (isLastStep ? _submit : _nextStep),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary600, AppColors.primaryTeal],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary600.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  isLastStep ? 'Hesap Oluştur' : 'İleri',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _buildErrorAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: Color(0xFFB91C1C), size: 20),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _errorMessage,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFB91C1C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint, IconData? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.gray400, size: 20) : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary600)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))),
      hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
    );
  }
}

class _SummaryRow {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_SummaryRow> rows;

  const _SummaryCard({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary600),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray700)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.gray100),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.label, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                    Text(r.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray900)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
