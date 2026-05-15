class QuoteResponse {
  final int id;
  final String companyName;
  final String? city;
  final String? logoUrl;
  final String price;
  final String? note;
  final String? guestStatus;
  final String? estimatedDuration;

  const QuoteResponse({
    required this.id,
    required this.companyName,
    this.city,
    this.logoUrl,
    required this.price,
    this.note,
    this.guestStatus,
    this.estimatedDuration,
  });

  factory QuoteResponse.fromJson(Map<String, dynamic> json) => QuoteResponse(
        id: json['id'] as int,
        companyName: json['companyName'] as String? ?? '',
        city: json['city'] as String?,
        logoUrl: json['logoUrl'] as String?,
        price: json['price'] as String? ?? '0',
        note: json['note'] as String?,
        guestStatus: json['guestStatus'] as String?,
        estimatedDuration: json['estimatedDuration'] as String?,
      );
}

class BookingUpdate {
  final int id;
  final String message;
  final DateTime createdAt;

  const BookingUpdate({required this.id, required this.message, required this.createdAt});

  factory BookingUpdate.fromJson(Map<String, dynamic> json) => BookingUpdate(
        id: json['id'] as int,
        message: json['message'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class GuestBookingTracking {
  final int id;
  final String referenceCode;
  final String status;
  final String name;
  final String? phone;
  final String city;
  final String brand;
  final String model;
  final String title;
  final String? description;
  final String? imageUrl;
  final DateTime createdAt;
  final List<QuoteResponse> responses;
  final List<BookingUpdate> updates;

  const GuestBookingTracking({
    required this.id,
    required this.referenceCode,
    required this.status,
    required this.name,
    this.phone,
    required this.city,
    required this.brand,
    required this.model,
    required this.title,
    this.description,
    this.imageUrl,
    required this.createdAt,
    required this.responses,
    required this.updates,
  });

  factory GuestBookingTracking.fromJson(Map<String, dynamic> json) => GuestBookingTracking(
        id: json['id'] as int,
        referenceCode: json['referenceCode'] as String? ?? '',
        status: json['status'] as String? ?? 'new',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        city: json['city'] as String? ?? '',
        brand: json['brand'] as String? ?? '',
        model: json['model'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        imageUrl: json['imageUrl'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        responses: (json['responses'] as List? ?? [])
            .map((e) => QuoteResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        updates: (json['updates'] as List? ?? [])
            .map((e) => BookingUpdate.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
