import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_repository.dart';
import '../../shared/models/provider_model.dart';

class ServiceDirectoryState {
  final List<ProviderModel> providers;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final String search;
  final String? selectedCity;
  final String? selectedServiceArea;
  final String sortBy;
  final double? minRating;
  final int page;
  final int totalPages;

  const ServiceDirectoryState({
    this.providers = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.search = '',
    this.selectedCity,
    this.selectedServiceArea,
    this.sortBy = 'rating',
    this.minRating,
    this.page = 1,
    this.totalPages = 1,
  });

  bool get hasMore => page < totalPages;

  ServiceDirectoryState copyWith({
    List<ProviderModel>? providers,
    bool? loading,
    bool? loadingMore,
    String? error,
    String? search,
    Object? selectedCity = _sentinel,
    Object? selectedServiceArea = _sentinel,
    String? sortBy,
    Object? minRating = _sentinel,
    int? page,
    int? totalPages,
  }) =>
      ServiceDirectoryState(
        providers: providers ?? this.providers,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        error: error,
        search: search ?? this.search,
        selectedCity: identical(selectedCity, _sentinel)
            ? this.selectedCity
            : selectedCity as String?,
        selectedServiceArea: identical(selectedServiceArea, _sentinel)
            ? this.selectedServiceArea
            : selectedServiceArea as String?,
        sortBy: sortBy ?? this.sortBy,
        minRating: identical(minRating, _sentinel)
            ? this.minRating
            : minRating as double?,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
      );
}

const _sentinel = Object();

final serviceDirectoryProvider =
    StateNotifierProvider<ServiceDirectoryNotifier, ServiceDirectoryState>((ref) {
  return ServiceDirectoryNotifier(ref.read(serviceRepositoryProvider));
});

class ServiceDirectoryNotifier extends StateNotifier<ServiceDirectoryState> {
  final ServiceRepository _repo;
  Timer? _debounceTimer;

  ServiceDirectoryNotifier(this._repo) : super(const ServiceDirectoryState()) {
    fetchProviders();
  }

  Future<void> fetchProviders({bool loadMore = false}) async {
    if (loadMore && !state.hasMore) return;

    final nextPage = loadMore ? state.page + 1 : 1;

    state = state.copyWith(
      loading: !loadMore,
      loadingMore: loadMore,
      error: null,
    );

    try {
      final result = await _repo.fetchProviders(
        city: state.selectedCity,
        serviceArea: state.selectedServiceArea,
        search: state.search,
        sort: state.sortBy,
        minRating: state.minRating,
        page: nextPage,
      );

      state = state.copyWith(
        providers: loadMore
            ? [...state.providers, ...result.providers]
            : result.providers,
        loading: false,
        loadingMore: false,
        page: result.pagination.page,
        totalPages: result.pagination.totalPages,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        loadingMore: false,
        error: e.toString(),
      );
    }
  }

  void onSearchChanged(String query) {
    state = state.copyWith(search: query);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), fetchProviders);
  }

  void applyFilters({
    String? city,
    String? serviceArea,
    String? sortBy,
    double? minRating,
  }) {
    state = state.copyWith(
      selectedCity: city,
      selectedServiceArea: serviceArea,
      sortBy: sortBy ?? 'rating',
      minRating: minRating,
    );
    fetchProviders();
  }

  void onCityChanged(String? city) {
    state = state.copyWith(selectedCity: city);
    fetchProviders();
  }

  void onSortChanged(String sort) {
    state = state.copyWith(sortBy: sort);
    fetchProviders();
  }

  void onMinRatingChanged(double? rating) {
    state = state.copyWith(minRating: rating);
    fetchProviders();
  }

  void onServiceAreaChanged(String? serviceArea) {
    state = state.copyWith(selectedServiceArea: serviceArea);
    fetchProviders();
  }

  void clearFilters() {
    state = const ServiceDirectoryState();
    fetchProviders();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
