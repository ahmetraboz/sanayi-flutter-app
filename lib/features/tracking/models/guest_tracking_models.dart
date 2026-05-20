import 'dart:convert';

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
  final String updateType;
  final String description;
  final String? partsUsed;
  final List<String> attachmentUrls;
  final String? delayReason;
  final int? delayEstimateDays;
  final double? laborCost;
  final double? partsCost;
  final double? totalCost;
  final String companyName;
  final DateTime createdAt;

  const BookingUpdate({
    required this.id,
    required this.updateType,
    required this.description,
    this.partsUsed,
    required this.attachmentUrls,
    this.delayReason,
    this.delayEstimateDays,
    this.laborCost,
    this.partsCost,
    this.totalCost,
    required this.companyName,
    required this.createdAt,
  });

  factory BookingUpdate.fromJson(Map<String, dynamic> json) {
    List<String> attachments = [];
    final rawAttachments = json['attachmentUrls'];
    try {
      if (rawAttachments is String && rawAttachments.isNotEmpty) {
        final decoded = jsonDecode(rawAttachments);
        if (decoded is List) {
          attachments = decoded.map((e) => e.toString()).toList();
        }
      } else if (rawAttachments is List) {
        attachments = rawAttachments.map((e) => e.toString()).toList();
      }
    } catch (_) {}

    return BookingUpdate(
      id: json['id'] as int,
      updateType: json['updateType'] as String? ?? 'progress',
      description: json['description'] as String? ?? '',
      partsUsed: json['partsUsed'] as String?,
      attachmentUrls: attachments,
      delayReason: json['delayReason'] as String?,
      delayEstimateDays: json['delayEstimateDays'] as int?,
      laborCost: double.tryParse(json['laborCost']?.toString() ?? ''),
      partsCost: double.tryParse(json['partsCost']?.toString() ?? ''),
      totalCost: double.tryParse(json['totalCost']?.toString() ?? ''),
      companyName: json['companyName'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
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
