import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme.dart';
import 'admin_service_detail_notifier.dart';

class AdminServiceDetailScreen extends ConsumerWidget {
  final int serviceId;

  const AdminServiceDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminServiceDetailProvider(serviceId));
    final notifier = ref.read(adminServiceDetailProvider(serviceId).notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
          onPressed: () => context.go('/admin/services'),
        ),
        title: Text(
          state.profile?['companyName'] as String? ?? 'Servis Detayı',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!state.loading)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, color: AppColors.gray600),
              onPressed: notifier.loadDetail,
            ),
        ],
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminServiceDetailState state,
    AdminServiceDetailNotifier notifier,
  ) {
    if (state.loading && state.profile == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary600, strokeWidth: 2),
      );
    }

    if (state.error != null && state.profile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.gray500, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: notifier.loadDetail,
              child: const Text('Tekrar Dene', style: TextStyle(color: AppColors.primary600)),
            ),
          ],
        ),
      );
    }

    if (state.profile == null) {
      return const Center(
        child: Text('Servis profili bulunamadı.', style: TextStyle(color: AppColors.gray500)),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary600,
      onRefresh: notifier.loadDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feedback banners
            if (state.updateSuccess != null)
              _FeedbackBanner(message: state.updateSuccess!, isError: false),
            if (state.updateError != null)
              _FeedbackBanner(message: state.updateError!, isError: true),

            // Header with approve/reject buttons
            _HeaderCard(
              profile: state.profile!,
              updating: state.updating,
              onApprove: () => _confirmAction(context, notifier, 'approved'),
              onReject: () => _confirmAction(context, notifier, 'rejected'),
            ),
            const SizedBox(height: 12),

            // Company details
            _CompanyDetailsCard(profile: state.profile!),
            const SizedBox(height: 12),

            // Owner / user info
            _UserInfoCard(profile: state.profile!),
            const SizedBox(height: 12),

            // Location
            if (_hasLocation(state.profile!)) ...[
              _LocationCard(profile: state.profile!),
              const SizedBox(height: 12),
            ],

            // Stats row
            _StatsRow(
              reviewCount: state.reviews.length,
              bidCount: state.bids.length,
              requestCount: state.requests.length,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  bool _hasLocation(Map<String, dynamic> profile) {
    return (profile['latitude'] as String?)?.isNotEmpty == true &&
        (profile['longitude'] as String?)?.isNotEmpty == true;
  }

  void _confirmAction(
    BuildContext context,
    AdminServiceDetailNotifier notifier,
    String newStatus,
  ) {
    final isApprove = newStatus == 'approved';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isApprove ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: isApprove ? AppColors.primary600 : AppColors.red700,
            ),
            const SizedBox(width: 8),
            Text(
              isApprove ? 'Servisi Onayla' : 'Servisi Reddet',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          isApprove
              ? 'Bu servis profili onaylanacak ve provider talepler üzerinde işlem yapabilecek.'
              : 'Bu servis profili reddedilecek. Provider bildirim alacak.',
          style: const TextStyle(fontSize: 14, color: AppColors.gray600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: AppColors.gray500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppColors.primary600 : AppColors.red700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await notifier.updateStatus(newStatus);
            },
            child: Text(isApprove ? 'Onayla' : 'Reddet'),
          ),
        ],
      ),
    );
  }
}

// ─── Feedback Banner ──────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _FeedbackBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? AppColors.red50 : AppColors.green50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isError ? AppColors.red100 : const Color(0xFFD1FAE5)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: isError ? AppColors.red700 : AppColors.primary600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: isError ? AppColors.red700 : AppColors.primary600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header Card ─────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final bool updating;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _HeaderCard({
    required this.profile,
    required this.updating,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = profile['status'] as String? ?? 'pending';
    final companyName = profile['companyName'] as String? ?? '—';
    final address = profile['address'] as String?;
    final isPending = status == 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.storefront_outlined, size: 28, color: AppColors.blue600),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900),
                    ),
                    const SizedBox(height: 4),
                    _StatusBadge(status: status),
                    if (address != null && address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppColors.gray400),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.gray100),
            const SizedBox(height: 16),
            if (updating)
              const Center(
                child: SizedBox(
                  height: 36,
                  child: CircularProgressIndicator(color: AppColors.primary600, strokeWidth: 2),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Onayla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reddet'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red700,
                        side: const BorderSide(color: AppColors.red700),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      'approved' => ('Onaylandı', AppColors.primary600, AppColors.green50),
      'rejected' => ('Reddedildi', AppColors.red700, AppColors.red50),
      _ => ('Onay Bekliyor', AppColors.amber600, AppColors.amber50),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ─── Company Details Card ─────────────────────────────────────────────────────

class _CompanyDetailsCard extends StatelessWidget {
  final Map<String, dynamic> profile;

  const _CompanyDetailsCard({required this.profile});

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso);
      const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = profile['city'] as String?;
    final district = profile['district'] as String?;
    final location = [district, city].where((s) => s != null && s.isNotEmpty).join(', ');
    final description = profile['description'] as String?;
    final taxNumber = profile['taxNumber'] as String?;
    final phone = profile['phone'] as String?;
    final website = profile['website'] as String?;
    final createdAt = profile['createdAt'] as String?;
    final verifiedAt = profile['verifiedAt'] as String?;
    final status = profile['status'] as String? ?? 'pending';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(Icons.business_outlined, size: 16, color: AppColors.blue600),
                SizedBox(width: 8),
                Text('İşletme Detayları', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.gray900)),
              ],
            ),
          ),
          const Divider(height: 20, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _InfoRow(label: 'Firma Adı', value: profile['companyName'] as String? ?? '—'),
                _InfoRow(label: 'Vergi No', value: taxNumber?.isNotEmpty == true ? taxNumber! : '—'),
                _InfoRow(label: 'İl / İlçe', value: location.isNotEmpty ? location : '—'),
                if (phone?.isNotEmpty == true)
                  _InfoRow(label: 'Telefon', value: phone!, isLink: 'tel:$phone'),
                if (website?.isNotEmpty == true)
                  _InfoRow(label: 'Website', value: website!, isLink: website),
                _InfoRow(label: 'Kayıt Tarihi', value: _formatDate(createdAt)),
                _InfoRow(
                  label: 'Durum',
                  value: switch (status) {
                    'approved' => 'Onaylandı${verifiedAt != null ? ' (${_formatDate(verifiedAt)})' : ''}',
                    'rejected' => 'Reddedildi',
                    _ => 'Onay Bekliyor',
                  },
                ),
                if (description?.isNotEmpty == true) ...[
                  const Divider(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Açıklama', style: TextStyle(fontSize: 12, color: AppColors.gray400, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: const TextStyle(fontSize: 14, color: AppColors.gray700, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? isLink;

  const _InfoRow({required this.label, required this.value, this.isLink});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray400, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: isLink != null
                ? GestureDetector(
                    onTap: () => launchUrl(Uri.parse(isLink!)),
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 14, color: AppColors.blue600, fontWeight: FontWeight.w500, decoration: TextDecoration.underline),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(fontSize: 14, color: AppColors.gray700, fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── User Info Card ───────────────────────────────────────────────────────────

class _UserInfoCard extends StatelessWidget {
  final Map<String, dynamic> profile;

  const _UserInfoCard({required this.profile});

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso);
      const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = profile['userName'] as String? ?? '—';
    final userEmail = profile['userEmail'] as String?;
    final userPhone = profile['userPhone'] as String?;
    final userCreatedAt = profile['userCreatedAt'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: AppColors.blue600),
              SizedBox(width: 8),
              Text('Kullanıcı Bilgileri', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.gray900)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.green50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, size: 22, color: AppColors.primary600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                    const SizedBox(height: 6),
                    if (userEmail?.isNotEmpty == true)
                      _UserInfoRow(icon: Icons.email_outlined, text: userEmail!),
                    if (userPhone?.isNotEmpty == true)
                      _UserInfoRow(icon: Icons.phone_outlined, text: userPhone!),
                    _UserInfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: 'Kayıt: ${_formatDate(userCreatedAt)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _UserInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.gray400),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.gray500))),
        ],
      ),
    );
  }
}

// ─── Location Card ────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final Map<String, dynamic> profile;

  const _LocationCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final lat = profile['latitude'] as String?;
    final lng = profile['longitude'] as String?;
    final googlePlaceId = profile['googlePlaceId'] as String?;
    final companyName = profile['companyName'] as String? ?? '';
    final city = profile['city'] as String?;
    final district = profile['district'] as String?;

    String mapUrl;
    if (googlePlaceId?.isNotEmpty == true) {
      mapUrl = 'https://www.google.com/maps/place/?q=place_id:$googlePlaceId';
    } else if (lat != null && lng != null) {
      mapUrl = 'https://www.google.com/maps?q=$lat,$lng';
    } else {
      final q = Uri.encodeComponent([companyName, district, city].where((s) => s?.isNotEmpty == true).join(' '));
      mapUrl = 'https://www.google.com/maps/search/?api=1&query=$q';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.map_outlined, size: 16, color: AppColors.blue600),
              SizedBox(width: 8),
              Text('Konum', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.gray900)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: lat != null && lng != null
                  ? _OsmEmbed(lat: lat, lng: lng)
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_outlined, size: 32, color: AppColors.gray300),
                          SizedBox(height: 8),
                          Text('Koordinat bilgisi yok', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse(mapUrl), mode: LaunchMode.externalApplication),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.open_in_new, size: 14, color: AppColors.blue600),
                SizedBox(width: 4),
                Text('Google Maps\'te Aç', style: TextStyle(fontSize: 13, color: AppColors.blue600, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OsmEmbed extends StatelessWidget {
  final String lat;
  final String lng;

  const _OsmEmbed({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    // OSM tile approximation using a simple placeholder since webview not available
    return Container(
      color: const Color(0xFFE8F4F8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
              ),
              child: const Icon(Icons.location_pin, size: 32, color: AppColors.red700),
            ),
            const SizedBox(height: 8),
            Text(
              '$lat, $lng',
              style: const TextStyle(fontSize: 11, color: AppColors.gray500, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int reviewCount;
  final int bidCount;
  final int requestCount;

  const _StatsRow({
    required this.reviewCount,
    required this.bidCount,
    required this.requestCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          icon: Icons.star_outline,
          iconColor: AppColors.amber600,
          bg: AppColors.amber50,
          count: reviewCount,
          label: 'Değerlendirme',
        ),
        const SizedBox(width: 10),
        _StatTile(
          icon: Icons.receipt_long_outlined,
          iconColor: AppColors.blue600,
          bg: const Color(0xFFEFF6FF),
          count: bidCount,
          label: 'Teklif',
        ),
        const SizedBox(width: 10),
        _StatTile(
          icon: Icons.inbox_outlined,
          iconColor: AppColors.primary600,
          bg: AppColors.green50,
          count: requestCount,
          label: 'Talep',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final int count;
  final String label;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: iconColor),
            ),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
          ],
        ),
      ),
    );
  }
}
