class AdminStats {
  final int totalUsers;
  final int totalProviders;
  final int totalRequests;
  final int openRequests;
  final int pendingReview;
  final int completed;
  final int totalBids;
  final int totalReviews;

  const AdminStats({
    required this.totalUsers,
    required this.totalProviders,
    required this.totalRequests,
    required this.openRequests,
    required this.pendingReview,
    required this.completed,
    required this.totalBids,
    required this.totalReviews,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: json['totalUsers'] as int? ?? 0,
        totalProviders: json['totalProviders'] as int? ?? 0,
        totalRequests: json['totalRequests'] as int? ?? 0,
        openRequests: json['openRequests'] as int? ?? 0,
        pendingReview: json['pendingReview'] as int? ?? 0,
        completed: json['completed'] as int? ?? 0,
        totalBids: json['totalBids'] as int? ?? 0,
        totalReviews: json['totalReviews'] as int? ?? 0,
      );
}
