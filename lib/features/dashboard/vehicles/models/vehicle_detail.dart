class VehicleDetail {
  final int id;
  final String brand;
  final String model;
  final int? year;
  final String? licensePlate;
  final DateTime createdAt;
  final String? fuelType;
  final String? transmissionType;
  final String? engineDisplacement;
  final String? bodyType;
  final String? color;
  final String? driveType;
  final int? mileage;

  const VehicleDetail({
    required this.id,
    required this.brand,
    required this.model,
    this.year,
    this.licensePlate,
    required this.createdAt,
    this.fuelType,
    this.transmissionType,
    this.engineDisplacement,
    this.bodyType,
    this.color,
    this.driveType,
    this.mileage,
  });

  factory VehicleDetail.fromJson(Map<String, dynamic> json) => VehicleDetail(
    id: json['id'] as int,
    brand: json['brand'] as String,
    model: json['model'] as String,
    year: json['year'] as int?,
    licensePlate: json['licensePlate'] as String?,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    fuelType: json['fuelType'] as String?,
    transmissionType: json['transmissionType'] as String?,
    engineDisplacement: json['engineDisplacement'] as String?,
    bodyType: json['bodyType'] as String?,
    color: json['color'] as String?,
    driveType: json['driveType'] as String?,
    mileage: json['mileage'] as int?,
  );
}

class VehicleRequestItem {
  final int id;
  final String title;
  final String status;
  final DateTime createdAt;
  final String? problemCategory;

  const VehicleRequestItem({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    this.problemCategory,
  });

  factory VehicleRequestItem.fromJson(Map<String, dynamic> json) =>
      VehicleRequestItem(
        id: json['id'] as int,
        title: json['title'] as String,
        status: json['status'] as String,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        problemCategory: json['problemCategory'] as String?,
      );
}

class VehicleDetailResponse {
  final VehicleDetail vehicle;
  final List<VehicleRequestItem> requests;

  const VehicleDetailResponse({required this.vehicle, required this.requests});

  factory VehicleDetailResponse.fromJson(Map<String, dynamic> json) {
    return VehicleDetailResponse(
      vehicle: VehicleDetail.fromJson(json['vehicle'] as Map<String, dynamic>),
      requests:
          (json['requests'] as List?)
              ?.map(
                (e) => VehicleRequestItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
