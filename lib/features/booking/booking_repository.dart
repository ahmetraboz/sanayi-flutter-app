import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_client.dart';
import 'models/booking_form_data.dart';

typedef BookingResult = ({String referenceCode, String accessToken});
typedef VinLookupResult = ({
  String brand,
  String model,
  String year,
  String? engineDisplacement,
  String? fuelType,
});

class BookingRepository {
  final ApiClient _api;

  BookingRepository(this._api);

  Future<String> uploadImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: file.name),
      });
      final res = await _api.postFormData('/api/upload', formData);
      return res.data['url'] as String;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Görsel yüklenemedi');
    }
  }

  Future<String> uploadPdf(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name,
          contentType: DioMediaType('application', 'pdf'),
        ),
      });
      final res = await _api.postFormData('/api/upload/pdf', formData);
      return res.data['url'] as String;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'PDF yüklenemedi');
    }
  }

  Future<VinLookupResult> lookupVin(String vin) async {
    try {
      final res = await _api.get('/api/public/vin/$vin');
      final data = res.data as Map<String, dynamic>;
      // API returns: make, model, year, fuelType, transmissionType, engineDisplacement
      return (
        brand: (data['make'] as String?) ?? '',
        model: (data['model'] as String?) ?? '',
        year: '${data['year'] ?? ''}',
        engineDisplacement: data['engineDisplacement'] as String?,
        fuelType: data['fuelType'] as String?,
      );
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Araç bilgisi bulunamadı');
    }
  }

  Future<BookingResult> submitBooking(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/api/guest/book', data: data);
      final body = res.data as Map<String, dynamic>;
      return (
        referenceCode: body['referenceCode'] as String,
        accessToken: body['accessToken'] as String,
      );
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Rezervasyon gönderilemedi');
    }
  }

  Future<String> lookupBooking({required String name, required String code}) async {
    try {
      final res = await _api.post(
        '/api/guest/lookup',
        data: {'name': name, 'code': code},
      );
      return res.data['accessToken'] as String;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Talep bulunamadı');
    }
  }

  Future<List<DamageReport>> analyzeDamage(XFile file, {String userPart = 'Ön Tampon'}) async {
    try {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: file.name),
        'userPart': userPart,
      });
      final res = await _api.postFormData('/api/public/analyze-damage', formData);
      final data = res.data as Map<String, dynamic>;
      // API returns a single report object (not a reports array)
      // Shape: { originalUrl, annotatedUrl, damageCount, damages[] }
      return [DamageReport.fromJson(data)];
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Analiz yapılamadı');
    }
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.read(apiClientProvider));
});
