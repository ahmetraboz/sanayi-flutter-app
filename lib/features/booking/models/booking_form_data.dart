class DamageReport {
  final String part;
  final String originalUrl;
  final String annotatedUrl;
  final int damageCount;
  final List<Map<String, dynamic>> damages;

  const DamageReport({
    required this.part,
    required this.originalUrl,
    required this.annotatedUrl,
    required this.damageCount,
    required this.damages,
  });

  factory DamageReport.fromJson(Map<String, dynamic> json) => DamageReport(
        // 'part' is not returned by the backend; fall back to userPart or a generic label
        part: json['part'] as String? ?? json['userPart'] as String? ?? 'Hasar Analizi',
        originalUrl: json['originalUrl'] as String? ?? '',
        annotatedUrl: json['annotatedUrl'] as String? ?? '',
        damageCount: json['damageCount'] as int? ?? 0,
        damages: (json['damages'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'part': part,
        'originalUrl': originalUrl,
        'annotatedUrl': annotatedUrl,
        'damageCount': damageCount,
        'damages': damages,
      };
}

class BookingFormData {
  String title;
  String description;
  String? imageUrl;
  String? selectedCity;
  List<int> selectedServiceIds;
  List<DamageReport> damageReports;

  bool useChassisMode;
  String chassisCode;
  String brand;
  String model;
  String year;
  String color;
  String licensePlate;
  String fuelType;
  String transmissionType;
  String engineDisplacement;
  String mileage;

  String name;
  String phone;

  BookingFormData({
    this.title = '',
    this.description = '',
    this.imageUrl,
    this.selectedCity,
    List<int>? selectedServiceIds,
    List<DamageReport>? damageReports,
    this.useChassisMode = true,
    this.chassisCode = '',
    this.brand = '',
    this.model = '',
    this.year = '',
    this.color = '',
    this.licensePlate = '',
    this.fuelType = '',
    this.transmissionType = '',
    this.engineDisplacement = '',
    this.mileage = '',
    this.name = '',
    this.phone = '',
  })  : selectedServiceIds = selectedServiceIds ?? [],
        damageReports = damageReports ?? [];

  BookingFormData copy() => BookingFormData(
        title: title,
        description: description,
        imageUrl: imageUrl,
        selectedCity: selectedCity,
        selectedServiceIds: List.from(selectedServiceIds),
        damageReports: List.from(damageReports),
        useChassisMode: useChassisMode,
        chassisCode: chassisCode,
        brand: brand,
        model: model,
        year: year,
        color: color,
        licensePlate: licensePlate,
        fuelType: fuelType,
        transmissionType: transmissionType,
        engineDisplacement: engineDisplacement,
        mileage: mileage,
        name: name,
        phone: phone,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'city': selectedCity ?? '',
      'serviceIds': selectedServiceIds,
      'damageReports': damageReports.map((r) => r.toJson()).toList(),
      'name': name,
      'phone': phone,
    };
    if (imageUrl != null) map['imageUrl'] = imageUrl;
    if (useChassisMode && chassisCode.isNotEmpty) map['chassisCode'] = chassisCode;
    if (brand.isNotEmpty) map['brand'] = brand;
    if (model.isNotEmpty) map['model'] = model;
    if (year.isNotEmpty) map['year'] = year;
    if (color.isNotEmpty) map['color'] = color;
    if (licensePlate.isNotEmpty) map['licensePlate'] = licensePlate.toUpperCase();
    if (fuelType.isNotEmpty) map['fuelType'] = fuelType;
    if (transmissionType.isNotEmpty) map['transmissionType'] = transmissionType;
    if (engineDisplacement.isNotEmpty) map['engineDisplacement'] = engineDisplacement;
    if (mileage.isNotEmpty) map['mileage'] = int.tryParse(mileage) ?? 0;
    return map;
  }
}
