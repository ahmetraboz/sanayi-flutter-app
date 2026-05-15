import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../services/widgets/provider_card.dart';
import '../../services/widgets/provider_detail_sheet.dart';
import '../../../core/constants/turkey_cities.dart';
import 'workplaces_notifier.dart';

class WorkplacesScreen extends ConsumerWidget {
  const WorkplacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workplacesProvider);
    final notifier = ref.read(workplacesProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: CustomScrollView(
        slivers: [
          _buildHeroSection(context, state, notifier),
          if (state.selectedCity == null)
            _buildEmptyCityState()
          else if (state.loading)
            _buildLoadingState()
          else if (state.error != null)
            _buildErrorState(state.error!)
          else if (state.providers.isEmpty)
            _buildNoProvidersState(state.selectedCity!)
          else
            _buildProviderGrid(context, state),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, WorkplacesState state, WorkplacesNotifier notifier) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF065F46)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF6EE7B7), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Konum Bazlı Arama',
                  style: TextStyle(color: const Color(0xFFA7F3D0).withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'İş Yerleri',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'İlinizde kayıtlı servis sağlayıcıları bulun ve talep gönderin',
              style: TextStyle(color: const Color(0xFFA7F3D0).withValues(alpha: 0.8), fontSize: 14),
            ),
            const SizedBox(height: 24),
            _CitySearchField(
              selectedCity: state.selectedCity,
              onSelected: (city) {
                if (city != null) notifier.selectCity(city);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCityState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.green50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.location_on, size: 32, color: AppColors.green700),
            ),
            const SizedBox(height: 16),
            const Text('Şehir seçin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray700)),
            const SizedBox(height: 8),
            const Text('Şehrinizi seçerek bölgenizdeki\nonaylı servisleri görün', textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray500)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary600)),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.red700),
              const SizedBox(height: 16),
              Text(error, style: const TextStyle(color: AppColors.gray700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoProvidersState(String city) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.storefront, size: 32, color: AppColors.gray400),
            ),
            const SizedBox(height: 16),
            Text('$city ilinde kayıtlı servis bulunamadı', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray700)),
            const SizedBox(height: 8),
            const Text('Başka bir il seçmeyi deneyin', textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray500)),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderGrid(BuildContext context, WorkplacesState state) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final provider = state.providers[i];
            return ProviderCard(
              provider: provider,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ProviderDetailSheet(
                    provider: provider,
                    onRequestTap: () {
                      Navigator.of(context).pop();
                      context.push('/dashboard/requests/new', extra: {
                        'serviceId': provider.id,
                        'serviceName': provider.companyName,
                      });
                    },
                  ),
                );
              },
            );
          },
          childCount: state.providers.length,
        ),
      ),
    );
  }
}

class _CitySearchField extends StatefulWidget {
  final String? selectedCity;
  final ValueChanged<String?> onSelected;

  const _CitySearchField({required this.selectedCity, required this.onSelected});

  @override
  State<_CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends State<_CitySearchField> {
  FocusNode? _focusNode;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      key: ValueKey(widget.selectedCity),
      initialValue: TextEditingValue(text: widget.selectedCity ?? ''),
      optionsBuilder: (textValue) {
        if (textValue.text.isEmpty) return kTurkeyCities;
        return kTurkeyCities.where(
          (c) => c.toLowerCase().contains(textValue.text.toLowerCase()),
        );
      },
      fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
        _focusNode = focusNode;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: ctrl,
            focusNode: focusNode,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Şehir ara...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(Icons.location_city, color: Colors.white.withValues(alpha: 0.6), size: 20),
              suffixIcon: Icon(Icons.keyboard_arrow_down, color: Colors.white.withValues(alpha: 0.8), size: 20),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: options.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
              itemBuilder: (context, i) {
                final city = options.elementAt(i);
                return InkWell(
                  onTap: () => onSelected(city),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    child: Text(city, style: const TextStyle(fontSize: 14, color: Color(0xFF111827))),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      onSelected: (city) {
        widget.onSelected(city);
        _focusNode?.unfocus();
      },
    );
  }
}
