class RequestItem {
  final int id;
  final String title;
  final String status;
  final String? imageUrl;
  final DateTime createdAt;
  final String vehicleBrand;
  final String vehicleModel;

  const RequestItem({
    required this.id,
    required this.title,
    required this.status,
    required this.imageUrl,
    required this.createdAt,
    required this.vehicleBrand,
    required this.vehicleModel,
  });

  factory RequestItem.fromJson(Map<String, dynamic> json) => RequestItem(
    id: json['id'] as int,
    title: json['title'] as String,
    status: json['status'] as String,
    imageUrl: json['imageUrl'] as String?,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    vehicleBrand: json['vehicleBrand'] as String? ?? '',
    vehicleModel: json['vehicleModel'] as String? ?? '',
  );
}
