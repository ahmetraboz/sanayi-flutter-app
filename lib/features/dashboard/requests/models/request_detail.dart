import 'dart:convert';

class RequestDetail {
  final int id;
  final String title;
  final String description;
  final String status;
  final String? problemCategory;
  final String? urgencyLevel;
  final String? imageUrl;
  final String vehicleBrand;
  final String vehicleModel;
  final int? vehicleYear;
  final String? vehiclePlate;
  final String? vehicleFuelType;
  final String? vehicleTransmissionType;
  final String? vehicleEngineDisplacement;
  final String? vehicleBodyType;
  final String? vehicleColor;
  final String? vehicleDriveType;
  final String? aiDetectedPart;
  final double? aiConfidence;
  final dynamic damageReports;
  final DateTime createdAt;
  final DateTime? preferredDateFrom;
  final DateTime? preferredDateTo;

  const RequestDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.problemCategory,
    this.urgencyLevel,
    this.imageUrl,
    required this.vehicleBrand,
    required this.vehicleModel,
    this.vehicleYear,
    this.vehiclePlate,
    this.vehicleFuelType,
    this.vehicleTransmissionType,
    this.vehicleEngineDisplacement,
    this.vehicleBodyType,
    this.vehicleColor,
    this.vehicleDriveType,
    this.aiDetectedPart,
    this.aiConfidence,
    this.damageReports,
    required this.createdAt,
    this.preferredDateFrom,
    this.preferredDateTo,
  });

  factory RequestDetail.fromJson(Map<String, dynamic> json) => RequestDetail(
    id: json['id'] as int,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    status: json['status'] as String,
    problemCategory: json['problemCategory'] as String?,
    urgencyLevel: json['urgencyLevel'] as String?,
    imageUrl: json['imageUrl'] as String?,
    vehicleBrand: json['vehicleBrand'] as String? ?? '',
    vehicleModel: json['vehicleModel'] as String? ?? '',
    vehicleYear: json['vehicleYear'] as int?,
    vehiclePlate: json['vehiclePlate'] as String?,
    vehicleFuelType: json['vehicleFuelType'] as String?,
    vehicleTransmissionType: json['vehicleTransmissionType'] as String?,
    vehicleEngineDisplacement: json['vehicleEngineDisplacement'] as String?,
    vehicleBodyType: json['vehicleBodyType'] as String?,
    vehicleColor: json['vehicleColor'] as String?,
    vehicleDriveType: json['vehicleDriveType'] as String?,
    aiDetectedPart: json['aiDetectedPart'] as String?,
    aiConfidence: (json['aiConfidence'] as num?)?.toDouble(),
    damageReports: json['damageReports'],
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    preferredDateFrom: json['preferredDateFrom'] != null
        ? DateTime.tryParse(json['preferredDateFrom'] as String)
        : null,
    preferredDateTo: json['preferredDateTo'] != null
        ? DateTime.tryParse(json['preferredDateTo'] as String)
        : null,
  );
}

// ─── Cost Item ────────────────────────────────────────────────────────────────

class CostItem {
  final String name;
  final double amount;

  const CostItem({required this.name, required this.amount});

  factory CostItem.fromJson(Map<String, dynamic> json) => CostItem(
    name: json['name'] as String? ?? '',
    amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
  );
}

// ─── Job Update ───────────────────────────────────────────────────────────────

class JobUpdate {
  final int id;
  final String updateType;
  final String description;
  final String companyName;
  final double? totalCost;
  final List<CostItem> costItems;
  final double? kdvRate;
  final double? kdvAmount;
  final String? overBudgetReason;
  final DateTime createdAt;

  const JobUpdate({
    required this.id,
    required this.updateType,
    required this.description,
    required this.companyName,
    this.totalCost,
    this.costItems = const [],
    this.kdvRate,
    this.kdvAmount,
    this.overBudgetReason,
    required this.createdAt,
  });

  bool get hasInvoice => costItems.isNotEmpty || (totalCost != null && totalCost! > 0);

  double get subtotal => costItems.fold(0.0, (sum, item) => sum + item.amount);

  factory JobUpdate.fromJson(Map<String, dynamic> json) {
    List<CostItem> items = [];
    final raw = json['costItems'];
    try {
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          items = decoded
              .whereType<Map<String, dynamic>>()
              .map(CostItem.fromJson)
              .toList();
        }
      } else if (raw is List) {
        items = raw
            .whereType<Map<String, dynamic>>()
            .map(CostItem.fromJson)
            .toList();
      }
    } catch (_) {}

    return JobUpdate(
      id: json['id'] as int,
      updateType: json['updateType'] as String? ?? 'progress',
      description: json['description'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      totalCost: double.tryParse(json['totalCost']?.toString() ?? ''),
      costItems: items,
      kdvRate: double.tryParse(json['kdvRate']?.toString() ?? ''),
      kdvAmount: double.tryParse(json['kdvAmount']?.toString() ?? ''),
      overBudgetReason: json['overBudgetReason'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

// ─── Info Request Data ────────────────────────────────────────────────────────

class InfoRequestData {
  final int id;
  final bool wantsEngineDisplacement;
  final bool wantsFuelType;
  final bool wantsTransmissionType;
  final bool wantsBodyType;
  final bool wantsMileage;
  final String? additionalNotes;

  const InfoRequestData({
    required this.id,
    required this.wantsEngineDisplacement,
    required this.wantsFuelType,
    required this.wantsTransmissionType,
    required this.wantsBodyType,
    required this.wantsMileage,
    this.additionalNotes,
  });

  bool get hasAnyField =>
      wantsEngineDisplacement || wantsFuelType || wantsTransmissionType || wantsBodyType || wantsMileage;

  factory InfoRequestData.fromJson(Map<String, dynamic> json) => InfoRequestData(
    id: json['id'] as int,
    wantsEngineDisplacement: json['engineDisplacement'] != null,
    wantsFuelType: json['fuelType'] != null,
    wantsTransmissionType: json['transmissionType'] != null,
    wantsBodyType: json['bodyType'] != null,
    wantsMileage: json['mileage'] != null,
    additionalNotes: json['additionalNotes'] as String?,
  );
}

// ─── Bid Item ─────────────────────────────────────────────────────────────────

class BidItem {
  final int id;
  final double price;
  final String description;
  final String estimatedDuration;
  final String status;
  final String companyName;
  final String? providerName;
  final String? city;
  final String? logoUrl;
  final double? averageRating;
  final int? reviewCount;
  final DateTime? createdAt;

  const BidItem({
    required this.id,
    required this.price,
    required this.description,
    required this.estimatedDuration,
    required this.status,
    required this.companyName,
    this.providerName,
    this.city,
    this.logoUrl,
    this.averageRating,
    this.reviewCount,
    this.createdAt,
  });

  factory BidItem.fromJson(Map<String, dynamic> json) => BidItem(
    id: json['id'] as int,
    price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
    description: json['description'] as String? ?? '',
    estimatedDuration: json['estimatedDuration'] as String? ?? '',
    status: json['status'] as String,
    companyName: json['companyName'] as String? ?? '',
    providerName: json['providerName'] as String?,
    city: json['city'] as String?,
    logoUrl: json['logoUrl'] as String?,
    averageRating: double.tryParse(json['averageRating']?.toString() ?? ''),
    reviewCount: json['reviewCount'] as int?,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
  );
}
