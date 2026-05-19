import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/page_header.dart';
import 'customer_profile_notifier.dart';

class TurkishPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;

    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 4 || i == 7 || i == 9) buffer.write(' ');
      buffer.write(limited[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).valueOrNull;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(customerProfileProvider.notifier).updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) _showSnack('Profiliniz güncellendi', success: true);
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (file == null) return;
    try {
      await ref.read(customerProfileProvider.notifier).uploadAvatar(file);
      if (mounted) _showSnack('Profil fotoğrafı güncellendi', success: true);
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    try {
      await ref.read(customerProfileProvider.notifier).changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showSnack('Şifreniz başarıyla değiştirildi', success: true);
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    }
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.green700 : AppColors.red700,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return 'K';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull;
    final profileState = ref.watch(customerProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: 'Profilim',
              showBack: true,
              action: GestureDetector(
                onTap: () => _showLogoutConfirm(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.red50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.red100),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, size: 15, color: AppColors.red700),
                      SizedBox(width: 5),
                      Text(
                        'Çıkış',
                        style: TextStyle(
                          color: AppColors.red700,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: authState.isLoading || user == null
                  ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary600,
                    ),
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAvatarCard(user, profileState),
                        const SizedBox(height: 24),
                        _buildProfileForm(profileState),
                        const SizedBox(height: 24),
                        _buildPasswordCard(profileState),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCard(dynamic user, ProfileState profileState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          GestureDetector(
            onTap: profileState.isUploadingAvatar ? null : _pickAndUploadAvatar,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34D399), AppColors.primary600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary600.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: profileState.isUploadingAvatar
                        ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? Image.network(
                          user.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context2, err, stack) =>
                              _buildInitials(user.name),
                        )
                        : _buildInitials(user.name),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 14,
                color: AppColors.gray500,
              ),
              const SizedBox(width: 4),
              Text(
                user.email,
                style: const TextStyle(fontSize: 14, color: AppColors.gray500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Müşteri',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(ProfileState profileState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.edit_square, 'Bilgileri Düzenle'),
            const SizedBox(height: 24),

            _fieldLabel('E-posta'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: ref.read(authNotifierProvider).valueOrNull?.email,
              enabled: false,
              decoration: _inputDecoration(
                icon: Icons.lock_outline,
              ).copyWith(fillColor: AppColors.gray100),
              style: const TextStyle(color: AppColors.gray500),
            ),
            const SizedBox(height: 20),

            _fieldLabel('Ad Soyad'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              decoration: _inputDecoration(
                icon: Icons.person_outline,
                hint: 'Adınız Soyadınız',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Ad Soyad zorunludur' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            _fieldLabel('Telefon'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              keyboardType: TextInputType.phone,
              inputFormatters: [TurkishPhoneFormatter()],
              decoration: _inputDecoration(
                icon: Icons.phone_outlined,
                hint: '0XXX XXX XX XX',
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _saveProfile(),
            ),
            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed:
                    profileState.isSavingProfile ? null : _saveProfile,
                icon: profileState.isSavingProfile
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.check, size: 18),
                label: Text(
                  profileState.isSavingProfile ? 'Kaydediliyor...' : 'Kaydet',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: _primaryButtonStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(ProfileState profileState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.lock_outline, 'Şifre Değiştir'),
            const SizedBox(height: 24),

            _fieldLabel('Mevcut Şifre'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _currentPasswordController,
              obscureText: !_showCurrentPassword,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              decoration: _inputDecoration(
                icon: Icons.lock_outline,
                hint: '••••••••',
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrentPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.gray400,
                  ),
                  onPressed: () => setState(
                    () => _showCurrentPassword = !_showCurrentPassword,
                  ),
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Mevcut şifre zorunludur' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            _fieldLabel('Yeni Şifre'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newPasswordController,
              obscureText: !_showNewPassword,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              decoration: _inputDecoration(
                icon: Icons.lock_reset_outlined,
                hint: '••••••••',
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.gray400,
                  ),
                  onPressed: () =>
                      setState(() => _showNewPassword = !_showNewPassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Yeni şifre zorunludur';
                if (v.length < 8) return 'En az 8 karakter olmalıdır';
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            _fieldLabel('Şifre Tekrarı'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              style: const TextStyle(color: AppColors.gray900, fontSize: 14),
              decoration: _inputDecoration(
                icon: Icons.lock_reset_outlined,
                hint: '••••••••',
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.gray400,
                  ),
                  onPressed: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Şifre tekrarı zorunludur';
                if (v != _newPasswordController.text) {
                  return 'Şifreler eşleşmiyor';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _changePassword(),
            ),
            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: profileState.isChangingPassword
                    ? null
                    : _changePassword,
                icon: profileState.isChangingPassword
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.lock_reset, size: 18),
                label: Text(
                  profileState.isChangingPassword
                      ? 'Değiştiriliyor...'
                      : 'Şifreyi Değiştir',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: _primaryButtonStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitials(String name) {
    return Center(
      child: Text(
        _getInitials(name),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary600),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.gray900,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.gray700,
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.gray200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required IconData icon, String? hint}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.gray400),
      filled: true,
      fillColor: Colors.white,
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary600,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'İptal',
              style: TextStyle(color: AppColors.gray600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red700,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}
