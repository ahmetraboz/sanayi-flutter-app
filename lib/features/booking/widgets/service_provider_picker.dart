import 'package:flutter/material.dart';
import '../../../core/constants/turkey_cities.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/provider_model.dart';
import '../../../shared/widgets/app_select_field.dart';

class ServiceProviderPickerWidget extends StatelessWidget {
  final String? selectedCity;
  final List<int> selectedIds;
  final List<ProviderModel> providers;
  final bool providersLoading;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<int> onToggleService;
  final String? cityError;
  final String? servicesError;

  const ServiceProviderPickerWidget({
    super.key,
    required this.selectedCity,
    required this.selectedIds,
    required this.providers,
    required this.providersLoading,
    required this.onCityChanged,
    required this.onToggleService,
    this.cityError,
    this.servicesError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCityDropdown(),
        if (cityError != null) ...[
          const SizedBox(height: 4),
          Text(cityError!, style: const TextStyle(fontSize: 12, color: AppColors.red700)),
        ],
        const SizedBox(height: 12),
        _buildProviderList(),
        if (servicesError != null) ...[
          const SizedBox(height: 4),
          Text(servicesError!, style: const TextStyle(fontSize: 12, color: AppColors.red700)),
        ],
      ],
    );
  }

  Widget _buildCityDropdown() {
    return AppSelectField(
      options: kTurkeyCities,
      value: selectedCity,
      hintText: 'Şehir Seçin',
      allowClear: true,
      decoration: InputDecoration(
        hintText: 'Şehir Seçin',
        hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cityError != null ? AppColors.red700 : AppColors.gray200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary600)),
      ),
      onChanged: onCityChanged,
    );
  }

  Widget _buildProviderList() {
    if (selectedCity == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Servis sağlayıcıları görmek için şehir seçin.',
          style: TextStyle(fontSize: 13, color: AppColors.gray500),
        ),
      );
    }
    if (providersLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary600),
        ),
      );
    }
    if (providers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Bu şehirde servis sağlayıcı bulunamadı.',
          style: TextStyle(fontSize: 13, color: AppColors.gray500),
        ),
      );
    }
    return Column(
      children: providers.map((p) => _ProviderTile(
        provider: p,
        selected: selectedIds.contains(p.id),
        onTap: () => onToggleService(p.id),
      )).toList(),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final ProviderModel provider;
  final bool selected;
  final VoidCallback onTap;

  const _ProviderTile({required this.provider, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary600 : AppColors.gray200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary600 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary600 : AppColors.gray300,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.companyName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primary600 : AppColors.gray900,
                    ),
                  ),
                  if (provider.city.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      [provider.city, provider.district].whereType<String>().join(', '),
                      style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                  ],
                ],
              ),
            ),
            if (provider.averageRating != null) ...[
              const Icon(Icons.star, size: 13, color: Color(0xFFFBBF24)),
              const SizedBox(width: 2),
              Text(
                provider.averageRating!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
