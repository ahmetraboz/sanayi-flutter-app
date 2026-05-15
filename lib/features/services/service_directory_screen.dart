import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../shared/widgets/app_select_field.dart';
import 'service_directory_notifier.dart';
import 'widgets/provider_card.dart';
import 'widgets/provider_detail_sheet.dart';
import '../../core/constants/turkey_cities.dart';

const _kSortOptions = [
  (value: 'rating', label: 'Puana Göre'),
  (value: 'reviews', label: 'Değerlendirmeye Göre'),
  (value: 'jobs', label: 'İş Sayısına Göre'),
];

class ServiceDirectoryScreen extends ConsumerWidget {
  const ServiceDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceDirectoryProvider);
    final notifier = ref.read(serviceDirectoryProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text('Servisler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          if (state.selectedCity != null || state.search.isNotEmpty || state.minRating != null)
            TextButton(
              onPressed: notifier.clearFilters,
              child: const Text('Temizle', style: TextStyle(color: AppColors.primary600, fontSize: 13)),
            ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(state: state, notifier: notifier),
          Expanded(child: _buildContent(context, ref, state, notifier)),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ServiceDirectoryState state,
    ServiceDirectoryNotifier notifier,
  ) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.gray500)),
            const SizedBox(height: 12),
            TextButton(onPressed: notifier.fetchProviders, child: const Text('Tekrar Dene')),
          ],
        ),
      );
    }
    if (state.providers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 48, color: AppColors.gray300),
            SizedBox(height: 12),
            Text('Servis bulunamadı', style: TextStyle(color: AppColors.gray500, fontSize: 15)),
          ],
        ),
      );
    }

    final crossAxisCount = MediaQuery.sizeOf(context).width >= 900 ? 3 : 2;

    return RefreshIndicator(
      color: AppColors.primary600,
      onRefresh: () => notifier.fetchProviders(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: state.providers.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == state.providers.length) {
            return _LoadMoreButton(
              loading: state.loadingMore,
              onTap: () => notifier.fetchProviders(loadMore: true),
            );
          }
          final provider = state.providers[i];
          return ProviderCard(
            provider: provider,
            onTap: () => _showDetail(context, provider),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderDetailSheet(
        provider: provider,
        onRequestTap: () {
          Navigator.of(context).pop();
          context.push('/book', extra: {'serviceId': provider.id, 'city': provider.city});
        },
      ),
    );
  }
}

// ── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final ServiceDirectoryState state;
  final ServiceDirectoryNotifier notifier;

  const _FilterBar({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            onChanged: notifier.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Servis ara...',
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.gray400),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary600)),
              hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _CityDropdown(value: state.selectedCity, onChanged: notifier.onCityChanged)),
              const SizedBox(width: 8),
              Expanded(child: _SortDropdown(value: state.sortBy, onChanged: notifier.onSortChanged)),
            ],
          ),
          const SizedBox(height: 8),
          _RatingFilterChips(state: state, notifier: notifier),
        ],
      ),
    );
  }
}

class _CityDropdown extends StatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _CityDropdown({required this.value, required this.onChanged});

  @override
  State<_CityDropdown> createState() => _CityDropdownState();
}

class _CityDropdownState extends State<_CityDropdown> {
  FocusNode? _focusNode;

  @override
  Widget build(BuildContext context) {
    return _DropdownContainer(
      child: Autocomplete<String>(
        key: ValueKey(widget.value),
        initialValue: TextEditingValue(text: widget.value ?? ''),
        optionsBuilder: (textValue) {
          if (textValue.text.isEmpty) return kTurkeyCities;
          return kTurkeyCities.where(
            (c) => c.toLowerCase().contains(textValue.text.toLowerCase()),
          );
        },
        fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
          _focusNode = focusNode;
          return TextField(
            controller: ctrl,
            focusNode: focusNode,
            style: const TextStyle(color: AppColors.gray700, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Tüm Şehirler',
              hintStyle: TextStyle(fontSize: 13, color: AppColors.gray400),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              isCollapsed: false,
            ),
            onChanged: (v) {
              if (v.isEmpty) widget.onChanged(null);
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
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray100),
                itemBuilder: (context, i) {
                  final city = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(city),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      child: Text(city, style: const TextStyle(fontSize: 13, color: AppColors.gray900)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        onSelected: (city) {
          widget.onChanged(city);
          _focusNode?.unfocus();
        },
      ),
    );
  }
}

class _SortDropdown extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SortDropdown({required this.value, required this.onChanged});

  @override
  State<_SortDropdown> createState() => _SortDropdownState();
}

class _SortDropdownState extends State<_SortDropdown> {
  FocusNode? _focusNode;

  String _labelForValue(String v) =>
      _kSortOptions.firstWhere((o) => o.value == v, orElse: () => _kSortOptions.first).label;

  @override
  Widget build(BuildContext context) {
    final labels = _kSortOptions.map((o) => o.label).toList();
    final currentLabel = _labelForValue(widget.value);

    return _DropdownContainer(
      child: Autocomplete<String>(
        key: ValueKey(widget.value),
        initialValue: TextEditingValue(text: currentLabel),
        optionsBuilder: (textValue) {
          if (textValue.text.isEmpty) return labels;
          return labels.where(
            (l) => l.toLowerCase().contains(textValue.text.toLowerCase()),
          );
        },
        fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
          _focusNode = focusNode;
          return TextField(
            controller: ctrl,
            focusNode: focusNode,
            style: const TextStyle(color: AppColors.gray700, fontSize: 13),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              isCollapsed: false,
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
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray100),
                itemBuilder: (context, i) {
                  final label = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(label),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray900)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        onSelected: (label) {
          final opt = _kSortOptions.firstWhere((o) => o.label == label, orElse: () => _kSortOptions.first);
          widget.onChanged(opt.value);
          _focusNode?.unfocus();
        },
      ),
    );
  }
}

class _DropdownContainer extends StatelessWidget {
  final Widget child;
  const _DropdownContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray200),
      ),
      child: child,
    );
  }
}

// ── Rating Filter Chips ──────────────────────────────────────────────────────

class _RatingFilterChips extends StatelessWidget {
  final ServiceDirectoryState state;
  final ServiceDirectoryNotifier notifier;

  const _RatingFilterChips({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    const options = <({String label, double? value})>[
      (label: 'Tümü', value: null),
      (label: '3+', value: 3.0),
      (label: '4+', value: 4.0),
      (label: '4.5+', value: 4.5),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((o) {
          final selected = state.minRating == o.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => notifier.onMinRatingChanged(o.value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary600 : AppColors.gray50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: selected ? AppColors.primary600 : AppColors.gray200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (o.value != null) ...[
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      o.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Load More Button ─────────────────────────────────────────────────────────

class _LoadMoreButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _LoadMoreButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Daha fazla', style: TextStyle(fontSize: 13, color: AppColors.primary600, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
