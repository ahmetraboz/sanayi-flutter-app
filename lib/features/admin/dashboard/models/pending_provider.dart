class PendingProvider {
  final int id;
  final String companyName;
  final String? city;
  final String status;
  final String createdAt;

  const PendingProvider({
    required this.id,
    required this.companyName,
    this.city,
    required this.status,
    required this.createdAt,
  });

  factory PendingProvider.fromJson(Map<String, dynamic> json) => PendingProvider(
        id: json['id'] as int,
        companyName: json['companyName'] as String? ?? '',
        city: json['city'] as String?,
        status: json['status'] as String? ?? 'pending',
        createdAt: json['createdAt'] as String? ?? '',
      );
}
