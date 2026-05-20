class CustomerBidItem {
  final int id;
  final String status;
  final String price;
  final int requestId;
  final String requestTitle;
  final String companyName;
  final DateTime createdAt;
  final String? description;
  final String? estimatedDuration;
  final String? proposedDate;
  final String? dateProposedBy;

  const CustomerBidItem({
    required this.id,
    required this.status,
    required this.price,
    required this.requestId,
    required this.requestTitle,
    required this.companyName,
    required this.createdAt,
    this.description,
    this.estimatedDuration,
    this.proposedDate,
    this.dateProposedBy,
  });

  bool get isDateProposedByProvider => dateProposedBy == 'provider';
  bool get isDateAgreed => dateProposedBy == 'agreed';
  bool get isDateProposedByCustomer => dateProposedBy == 'customer';

  factory CustomerBidItem.fromJson(Map<String, dynamic> json) {
    return CustomerBidItem(
      id: json['id'] as int,
      status: json['status'] as String,
      price: json['price']?.toString() ?? '0',
      requestId: json['requestId'] as int,
      requestTitle: json['requestTitle'] as String? ?? 'İsimsiz Talep',
      companyName: json['companyName'] as String? ?? 'Bilinmeyen İş Yeri',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      description: json['description'] as String?,
      estimatedDuration: json['estimatedDuration'] as String?,
      proposedDate: json['proposedDate'] as String?,
      dateProposedBy: json['dateProposedBy'] as String?,
    );
  }
}
