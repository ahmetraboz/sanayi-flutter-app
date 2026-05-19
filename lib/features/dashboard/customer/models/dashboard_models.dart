class CustomerStats {
  final int vehicles;
  final int totalRequests;
  final int openRequests;
  final int pendingBids;

  const CustomerStats({
    required this.vehicles,
    required this.totalRequests,
    required this.openRequests,
    required this.pendingBids,
  });

  factory CustomerStats.fromJson(Map<String, dynamic> json) => CustomerStats(
    vehicles: json['vehicles'] as int? ?? 0,
    totalRequests: json['totalRequests'] as int? ?? 0,
    openRequests: json['openRequests'] as int? ?? 0,
    pendingBids: json['pendingBids'] as int? ?? 0,
  );
}

class ActiveJob {
  final int id;
  final String title;
  final String status;
  final String vehicleBrand;
  final String vehicleModel;

  const ActiveJob({
    required this.id,
    required this.title,
    required this.status,
    required this.vehicleBrand,
    required this.vehicleModel,
  });

  factory ActiveJob.fromJson(Map<String, dynamic> json) => ActiveJob(
    id: json['id'] as int,
    title: json['title'] as String,
    status: json['status'] as String,
    vehicleBrand: json['vehicleBrand'] as String? ?? '',
    vehicleModel: json['vehicleModel'] as String? ?? '',
  );
}

class RecentRequest {
  final int id;
  final String title;
  final String status;
  final String? imageUrl;
  final DateTime createdAt;
  final String vehicleBrand;
  final String vehicleModel;

  const RecentRequest({
    required this.id,
    required this.title,
    required this.status,
    required this.imageUrl,
    required this.createdAt,
    required this.vehicleBrand,
    required this.vehicleModel,
  });

  factory RecentRequest.fromJson(Map<String, dynamic> json) => RecentRequest(
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

class RecentBid {
  final int id;
  final int requestId;
  final String requestTitle;
  final String serviceCompanyName;
  final double? price;
  final String status;

  const RecentBid({
    required this.id,
    required this.requestId,
    required this.requestTitle,
    required this.serviceCompanyName,
    required this.price,
    required this.status,
  });

  factory RecentBid.fromJson(Map<String, dynamic> json) => RecentBid(
    id: json['id'] as int,
    requestId: json['requestId'] as int,
    requestTitle: json['requestTitle'] as String? ?? '',
    serviceCompanyName: json['serviceCompanyName'] as String? ?? '',
    price: double.tryParse(json['price']?.toString() ?? ''),
    status: json['status'] as String? ?? 'pending',
  );
}
