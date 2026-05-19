import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../shared/models/provider_model.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/header_actions.dart';
import '../../core/constants/turkey_cities.dart';
import '../../shared/widgets/skeleton.dart';
import '../../core/constants/service_areas.dart';
import 'service_directory_notifier.dart';
import 'widgets/provider_card.dart';
import 'widgets/provider_detail_sheet.dart';

const _kSortOptions = [
  (value: 'rating', label: 'En Yüksek Puan'),
  (value: 'reviews', label: 'En Fazla Değerlendirme'),
  (value: 'jobs', label: 'En Fazla İş'),
];

class ServiceDirectoryScreen extends ConsumerStatefulWidget {
  final bool asTab;

  const ServiceDirectoryScreen({super.key, this.asTab = false});

  @override
  ConsumerState<ServiceDirectoryScreen> createState() => _ServiceDirectoryScreenState();
}

class _ServiceDirectoryScreenState extends ConsumerState<ServiceDirectoryScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serviceDirectoryProvider);
    final notifier = ref.read(serviceDirectoryProvider.notifier);

    final activeFilterCount = (state.selectedCity != null ? 1 : 0) +
        (state.minRating != null ? 1 : 0) +
        (state.sortBy != 'rating' ? 1 : 0) +
        (state.selectedServiceArea != null ? 1 : 0);

    if (widget.asTab) {
      return Scaffold(
        backgroundColor: AppColors.gray50,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: PageHeader(
                title: 'Servisler',
                subtitle: 'Bölgenizdeki onaylı servisleri bulun',
                action: const HeaderActions(),
              ),
            ),
            _TabToggle(
              activeTab: _activeTab,
              onChanged: (i) => setState(() => _activeTab = i),
            ),
            if (_activeTab == 0)
              _SearchBar(
                state: state,
                notifier: notifier,
                activeFilterCount: activeFilterCount,
              ),
            Expanded(
              child: _activeTab == 0
                  ? _buildContent(context, state, notifier)
                  : _MapView(
                      providers: state.providers,
                      onTap: (p) => _showDetail(context, p),
                    ),
            ),
          ],
        ),
      );
    }

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
        title: const Text('Servisler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          _SearchBar(
            state: state,
            notifier: notifier,
            activeFilterCount: activeFilterCount,
          ),
          Expanded(child: _buildContent(context, state, notifier)),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ServiceDirectoryState state,
    ServiceDirectoryNotifier notifier,
  ) {
    if (state.loading) {
      return const _ServiceDirectorySkeleton();
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
            TextButton(
                onPressed: notifier.fetchProviders,
                child: const Text('Tekrar Dene')),
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
            Text('Servis bulunamadı',
                style: TextStyle(color: AppColors.gray500, fontSize: 15)),
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

  void _showDetail(BuildContext context, ProviderModel provider) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderDetailSheet(
        provider: provider,
        onRequestTap: () {
          Navigator.of(context, rootNavigator: true).pop();
          if (widget.asTab) {
            context.push('/dashboard/requests/new', extra: {
              'serviceId': provider.id,
              'serviceName': provider.companyName,
              'serviceCity': provider.city,
              'serviceAreas': provider.serviceAreas,
            });
          } else {
            context.push('/book',
                extra: {'serviceId': provider.id, 'city': provider.city});
          }
        },
      ),
    );
  }
}

// ── Tab Toggle ────────────────────────────────────────────────────────────────

class _TabToggle extends StatelessWidget {
  final int activeTab;
  final ValueChanged<int> onChanged;

  const _TabToggle({required this.activeTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _Tab(label: 'Liste', icon: Icons.list_alt_outlined, active: activeTab == 0, onTap: () => onChanged(0)),
            _Tab(label: 'Harita', icon: Icons.map_outlined, active: activeTab == 1, onTap: () => onChanged(1)),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: active ? AppColors.primary600 : AppColors.gray500),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppColors.primary600 : AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Map View ─────────────────────────────────────────────────────────────────

class _MapView extends StatefulWidget {
  final List<ProviderModel> providers;
  final void Function(ProviderModel) onTap;

  const _MapView({required this.providers, required this.onTap});

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  ProviderModel? _selected;
  GoogleMapController? _mapCtrl;

  static const _turkey = CameraPosition(target: LatLng(39.9334, 32.8597), zoom: 5.5);

  List<ProviderModel> get _withCoords => widget.providers
      .where((p) =>
          p.latitude != null &&
          p.longitude != null &&
          double.tryParse(p.latitude!) != null &&
          double.tryParse(p.longitude!) != null)
      .toList();

  Set<Marker> _buildMarkers() {
    return _withCoords.map((p) {
      final lat = double.parse(p.latitude!);
      final lng = double.parse(p.longitude!);
      final isSelected = _selected?.id == p.id;
      return Marker(
        markerId: MarkerId(p.id.toString()),
        position: LatLng(lat, lng),
        icon: isSelected
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(160),
        onTap: () {
          setState(() => _selected = p);
          _mapCtrl?.animateCamera(
            CameraUpdate.newLatLng(LatLng(lat, lng)),
          );
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final coords = _withCoords;
    final initialCamera = coords.isNotEmpty
        ? CameraPosition(
            target: LatLng(
              double.parse(coords.first.latitude!),
              double.parse(coords.first.longitude!),
            ),
            zoom: coords.length == 1 ? 14.0 : 5.5,
          )
        : _turkey;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: initialCamera,
          onMapCreated: (ctrl) => _mapCtrl = ctrl,
          markers: _buildMarkers(),
          onTap: (_) => setState(() => _selected = null),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
        if (coords.isEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off_outlined, size: 40, color: AppColors.gray300),
                  SizedBox(height: 12),
                  Text('Konum bilgisi olan servis bulunamadı',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.gray500, fontSize: 14)),
                ],
              ),
            ),
          ),
        if (_selected != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: GestureDetector(
              onTap: () => widget.onTap(_selected!),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.success50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: AppColors.primary600, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selected!.companyName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_selected!.city != null)
                            Text(
                              [_selected!.district, _selected!.city].whereType<String>().join(', '),
                              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Detay', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final ServiceDirectoryState state;
  final ServiceDirectoryNotifier notifier;
  final int activeFilterCount;

  const _SearchBar({
    required this.state,
    required this.notifier,
    required this.activeFilterCount,
  });

  void _openFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        state: state,
        notifier: notifier,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: notifier.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Servis ara...',
                prefixIcon:
                    const Icon(Icons.search, size: 20, color: AppColors.gray400),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppColors.gray50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.gray200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.gray200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary600)),
                hintStyle:
                    const TextStyle(color: AppColors.gray400, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _openFilters(context),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: activeFilterCount > 0
                    ? AppColors.primary600.withValues(alpha: 0.08)
                    : AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: activeFilterCount > 0
                      ? AppColors.primary600
                      : AppColors.gray200,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: activeFilterCount > 0
                        ? AppColors.primary600
                        : AppColors.gray500,
                  ),
                  if (activeFilterCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.primary600,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$activeFilterCount',
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Sheet ─────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final ServiceDirectoryState state;
  final ServiceDirectoryNotifier notifier;

  const _FilterSheet({required this.state, required this.notifier});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _city;
  late String? _sortBy;
  late double? _minRating;
  late String? _serviceArea;

  @override
  void initState() {
    super.initState();
    _city = widget.state.selectedCity;
    _sortBy = widget.state.sortBy == 'rating' ? null : widget.state.sortBy;
    _minRating = widget.state.minRating;
    _serviceArea = widget.state.selectedServiceArea;
  }

  void _apply() {
    widget.notifier.applyFilters(
      city: _city,
      serviceArea: _serviceArea,
      sortBy: _sortBy,
      minRating: _minRating,
    );
    Navigator.of(context).pop();
  }

  void _clear() {
    widget.notifier.clearFilters();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final hasActive = _city != null || _sortBy != null || _minRating != null || _serviceArea != null;

    return Container(
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
                borderRadius: BorderRadius.circular(99)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filtreler',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900)),
                if (hasActive)
                  GestureDetector(
                    onTap: _clear,
                    child: const Text('Temizle',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray500)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.gray100),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Hizmet Alanı'),
                  const SizedBox(height: 10),
                  _ServiceAreaPicker(
                    value: _serviceArea,
                    onChanged: (v) => setState(() => _serviceArea = v),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('Şehir'),
                  const SizedBox(height: 10),
                  _CityPicker(
                    value: _city,
                    onChanged: (v) => setState(() => _city = v),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('Sıralama'),
                  const SizedBox(height: 10),
                  _OptionGroup<String>(
                    options: _kSortOptions.map((o) => (value: o.value, label: o.label)).toList(),
                    selected: _sortBy,
                    onChanged: (v) => setState(() => _sortBy = v),
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('Minimum Puan'),
                  const SizedBox(height: 10),
                  _RatingPicker(
                    value: _minRating,
                    onChanged: (v) => setState(() => _minRating = v),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.gray200,
                  disabledForegroundColor: AppColors.gray400,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Uygula',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.gray500,
            letterSpacing: 0.3),
      );
}

// ── Service Area Picker ───────────────────────────────────────────────────────

class _ServiceAreaPicker extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _ServiceAreaPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kServiceAreas.map((area) {
        final isSelected = value == area.value;
        return GestureDetector(
          onTap: () => onChanged(isSelected ? null : area.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? area.bg : AppColors.gray50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? area.color : AppColors.gray200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(area.icon, size: 14, color: isSelected ? area.color : AppColors.gray400),
                const SizedBox(width: 6),
                Text(
                  area.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? area.color : AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── City Picker ───────────────────────────────────────────────────────────────

class _CityPicker extends StatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _CityPicker({required this.value, required this.onChanged});

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.value ?? ''),
      optionsBuilder: (tv) {
        if (tv.text.isEmpty) return kTurkeyCities;
        return kTurkeyCities
            .where((c) => c.toLowerCase().contains(tv.text.toLowerCase()));
      },
      fieldViewBuilder: (context, ctrl, focusNode, _) => TextField(
        controller: ctrl,
        focusNode: focusNode,
        style: const TextStyle(color: AppColors.gray700, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Şehir seçin...',
          hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
          prefixIcon:
              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.gray400),
          suffixIcon: ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AppColors.gray400),
                  onPressed: () {
                    ctrl.clear();
                    widget.onChanged(null);
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.gray50,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.gray200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.gray200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary600)),
        ),
        onChanged: (v) {
          if (v.isEmpty) widget.onChanged(null);
        },
      ),
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
              separatorBuilder: (context, i) =>
                  const Divider(height: 1, color: AppColors.gray100),
              itemBuilder: (context, i) {
                final city = options.elementAt(i);
                return InkWell(
                  onTap: () => onSelected(city),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    child: Text(city,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.gray900)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      onSelected: widget.onChanged,
    );
  }
}

// ── Generic Option Group ──────────────────────────────────────────────────────

class _OptionGroup<T> extends StatelessWidget {
  final List<({T value, String label})> options;
  final T? selected;
  final ValueChanged<T?> onChanged;

  const _OptionGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = o.value == selected;
        return GestureDetector(
          onTap: () => onChanged(isSelected ? null : o.value),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary600.withValues(alpha: 0.08)
                  : AppColors.gray50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary600
                    : AppColors.gray200,
              ),
            ),
            child: Text(
              o.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary600
                    : AppColors.gray600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Rating Picker ─────────────────────────────────────────────────────────────

class _RatingPicker extends StatelessWidget {
  final double? value;
  final ValueChanged<double?> onChanged;

  const _RatingPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = <({double? value, String label})>[
      (value: null, label: 'Tümü'),
      (value: 3.0, label: '3+'),
      (value: 4.0, label: '4+'),
      (value: 4.5, label: '4.5+'),
    ];

    return Wrap(
      spacing: 8,
      children: options.map((o) {
        final isSelected = value == o.value;
        return GestureDetector(
          onTap: () => onChanged(o.value),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary600.withValues(alpha: 0.08)
                  : AppColors.gray50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary600
                    : AppColors.gray200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (o.value != null) ...[
                  const Icon(Icons.star_rounded,
                      size: 14, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 4),
                ],
                Text(
                  o.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary600
                        : AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Daha fazla',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary600,
                      fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

class _ServiceDirectorySkeleton extends StatelessWidget {
  const _ServiceDirectorySkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(height: 120, radius: 0),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(height: 13, radius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(height: 11, width: 80, radius: 3),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        SkeletonBox(width: 50, height: 18, radius: 5),
                        SizedBox(width: 6),
                        SkeletonBox(width: 40, height: 18, radius: 5),
                      ],
                    ),
                    Spacer(),
                    Row(
                      children: [
                        SkeletonBox(width: 30, height: 11, radius: 3),
                        SizedBox(width: 8),
                        SkeletonBox(width: 25, height: 11, radius: 3),
                        SizedBox(width: 8),
                        SkeletonBox(width: 25, height: 11, radius: 3),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
