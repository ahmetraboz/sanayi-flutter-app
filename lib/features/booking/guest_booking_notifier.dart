import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_client.dart';
import '../../shared/models/provider_model.dart';
import '../services/service_repository.dart';
import 'booking_repository.dart';
import 'models/booking_form_data.dart';

const _sentinel = Object();

class GuestBookingState {
  final int currentStep;
  final BookingFormData form;
  final bool imageUploading;
  final bool vinLookupLoading;
  final bool vinLookupSuccess;
  final String? vinError;
  final bool submitting;
  final String? submitError;
  final String? referenceCode;
  final String? accessToken;
  final List<ProviderModel> availableProviders;
  final bool providersLoading;
  final Map<String, String?> errors;

  const GuestBookingState({
    this.currentStep = 1,
    required this.form,
    this.imageUploading = false,
    this.vinLookupLoading = false,
    this.vinLookupSuccess = false,
    this.vinError,
    this.submitting = false,
    this.submitError,
    this.referenceCode,
    this.accessToken,
    this.availableProviders = const [],
    this.providersLoading = false,
    this.errors = const {},
  });

  GuestBookingState copyWith({
    int? currentStep,
    BookingFormData? form,
    bool? imageUploading,
    bool? vinLookupLoading,
    bool? vinLookupSuccess,
    Object? vinError = _sentinel,
    bool? submitting,
    Object? submitError = _sentinel,
    Object? referenceCode = _sentinel,
    Object? accessToken = _sentinel,
    List<ProviderModel>? availableProviders,
    bool? providersLoading,
    Map<String, String?>? errors,
  }) {
    return GuestBookingState(
      currentStep: currentStep ?? this.currentStep,
      form: form ?? this.form,
      imageUploading: imageUploading ?? this.imageUploading,
      vinLookupLoading: vinLookupLoading ?? this.vinLookupLoading,
      vinLookupSuccess: vinLookupSuccess ?? this.vinLookupSuccess,
      vinError: identical(vinError, _sentinel) ? this.vinError : vinError as String?,
      submitting: submitting ?? this.submitting,
      submitError: identical(submitError, _sentinel) ? this.submitError : submitError as String?,
      referenceCode: identical(referenceCode, _sentinel) ? this.referenceCode : referenceCode as String?,
      accessToken: identical(accessToken, _sentinel) ? this.accessToken : accessToken as String?,
      availableProviders: availableProviders ?? this.availableProviders,
      providersLoading: providersLoading ?? this.providersLoading,
      errors: errors ?? this.errors,
    );
  }
}

class GuestBookingNotifier extends StateNotifier<GuestBookingState> {
  final BookingRepository _bookingRepo;
  final ServiceRepository _serviceRepo;

  GuestBookingNotifier(this._bookingRepo, this._serviceRepo)
      : super(GuestBookingState(form: BookingFormData()));

  void init({int? preselectedServiceId, String? preselectedCity}) {
    final form = BookingFormData(
      selectedCity: preselectedCity,
      selectedServiceIds: preselectedServiceId != null ? [preselectedServiceId] : [],
    );
    state = GuestBookingState(form: form);
    if (preselectedCity != null) _loadProviders(preselectedCity);
  }

  // ── Step 1 ──────────────────────────────────────────────────────────────────
  void updateTitle(String v) => _mutate((f) => f.title = v);
  void updateDescription(String v) => _mutate((f) => f.description = v);
  void updateDamageReports(List<DamageReport> reports) => _mutate((f) => f.damageReports = reports);

  void updateCity(String? city) {
    _mutate((f) {
      f.selectedCity = city;
      f.selectedServiceIds = [];
    });
    state = state.copyWith(availableProviders: []);
    if (city != null) _loadProviders(city);
  }

  void toggleService(int id) {
    _mutate((f) {
      final ids = List<int>.from(f.selectedServiceIds);
      if (ids.contains(id)) {
        ids.remove(id);
      } else {
        ids.add(id);
      }
      f.selectedServiceIds = ids;
    });
  }

  Future<void> uploadImage(XFile file) async {
    state = state.copyWith(imageUploading: true);
    try {
      final url = await _bookingRepo.uploadImage(file);
      _mutate((f) => f.imageUrl = url);
    } catch (_) {
      // user can retry
    } finally {
      state = state.copyWith(imageUploading: false);
    }
  }

  // ── Step 2 ──────────────────────────────────────────────────────────────────
  void toggleChassisMode(bool v) {
    _mutate((f) => f.useChassisMode = v);
    state = state.copyWith(vinLookupSuccess: false, vinError: null);
  }

  void updateChassisCode(String v) => _mutate((f) => f.chassisCode = v.toUpperCase());
  void updateBrand(String? v) => _mutate((f) => f.brand = v ?? '');
  void updateModel(String v) => _mutate((f) => f.model = v);
  void updateYear(String v) => _mutate((f) => f.year = v);
  void updateColor(String v) => _mutate((f) => f.color = v);
  void updateLicensePlate(String v) => _mutate((f) => f.licensePlate = v.toUpperCase());
  void updateFuelType(String? v) => _mutate((f) => f.fuelType = v ?? '');
  void updateTransmission(String? v) => _mutate((f) => f.transmissionType = v ?? '');
  void updateEngineDisplacement(String v) => _mutate((f) => f.engineDisplacement = v);
  void updateMileage(String v) => _mutate((f) => f.mileage = v);

  Future<void> lookupVin(String vin) async {
    if (vin.length < 5) return;
    state = state.copyWith(vinLookupLoading: true, vinError: null, vinLookupSuccess: false);
    try {
      final result = await _bookingRepo.lookupVin(vin);
      _mutate((f) {
        f.brand = result.brand;
        f.model = result.model;
        f.year = result.year;
        if (result.engineDisplacement != null) f.engineDisplacement = result.engineDisplacement!;
        if (result.fuelType != null) f.fuelType = result.fuelType!;
      });
      state = state.copyWith(vinLookupSuccess: true, vinLookupLoading: false);
    } catch (e) {
      state = state.copyWith(
        vinLookupLoading: false,
        vinError: e is ApiException ? e.message : 'Araç bilgisi bulunamadı',
      );
    }
  }

  // ── Step 3 ──────────────────────────────────────────────────────────────────
  void updateName(String v) => _mutate((f) => f.name = v);
  void updatePhone(String v) => _mutate((f) => f.phone = v);

  // ── Navigation ──────────────────────────────────────────────────────────────
  void validateAndNext() {
    switch (state.currentStep) {
      case 1:
        _validateStep1();
      case 2:
        _validateStep2();
      case 3:
        _submitBooking();
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1, submitError: null);
    }
  }

  // ── Private ──────────────────────────────────────────────────────────────────
  void _mutate(void Function(BookingFormData f) mutation) {
    final newForm = state.form.copy();
    mutation(newForm);
    state = state.copyWith(form: newForm);
  }

  void _validateStep1() {
    final errors = <String, String?>{};
    if (state.form.title.length < 3) errors['title'] = 'En az 3 karakter giriniz';
    if (state.form.description.length < 10) errors['description'] = 'En az 10 karakter giriniz';
    if (state.form.selectedCity == null) errors['city'] = 'Şehir seçiniz';
    if (state.form.selectedServiceIds.isEmpty) errors['services'] = 'En az 1 servis seçiniz';
    state = state.copyWith(errors: errors);
    if (errors.isEmpty) state = state.copyWith(currentStep: 2);
  }

  void _validateStep2() {
    final errors = <String, String?>{};
    if (state.form.useChassisMode) {
      if (state.form.chassisCode.isEmpty) errors['chassis'] = 'Şasi numarası giriniz';
    } else {
      if (state.form.brand.isEmpty) errors['brand'] = 'Marka seçiniz';
      if (state.form.model.isEmpty) errors['model'] = 'Model giriniz';
    }
    state = state.copyWith(errors: errors);
    if (errors.isEmpty) state = state.copyWith(currentStep: 3);
  }

  Future<void> _submitBooking() async {
    final errors = <String, String?>{};
    if (state.form.name.length < 2) errors['name'] = 'En az 2 karakter giriniz';
    if (state.form.phone.length < 10) errors['phone'] = 'Geçerli telefon giriniz';
    state = state.copyWith(errors: errors);
    if (errors.isNotEmpty) return;

    state = state.copyWith(submitting: true, submitError: null);
    try {
      final result = await _bookingRepo.submitBooking(state.form.toJson());
      state = state.copyWith(
        submitting: false,
        currentStep: 4,
        referenceCode: result.referenceCode,
        accessToken: result.accessToken,
      );
    } catch (e) {
      state = state.copyWith(
        submitting: false,
        submitError: e is ApiException ? e.message : 'Bir hata oluştu. Tekrar deneyin.',
      );
    }
  }

  Future<void> _loadProviders(String city) async {
    state = state.copyWith(providersLoading: true);
    try {
      final result = await _serviceRepo.fetchProviders(city: city, limit: 30);
      state = state.copyWith(availableProviders: result.providers, providersLoading: false);
    } catch (_) {
      state = state.copyWith(providersLoading: false);
    }
  }
}

final guestBookingProvider =
    StateNotifierProvider.autoDispose<GuestBookingNotifier, GuestBookingState>((ref) {
  return GuestBookingNotifier(
    ref.read(bookingRepositoryProvider),
    ref.read(serviceRepositoryProvider),
  );
});
