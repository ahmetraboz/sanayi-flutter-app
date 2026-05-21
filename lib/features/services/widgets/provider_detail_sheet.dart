import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme.dart';
import '../../../core/constants/service_areas.dart';
import '../../../shared/models/provider_model.dart';
import '../service_repository.dart';

final _detailProvider = FutureProvider.family<ProviderDetailResult, int>((ref, id) {
  return ref.read(serviceRepositoryProvider).fetchProviderDetail(id);
});

class ProviderDetailSheet extends ConsumerWidget {
  final ProviderModel provider;
  final VoidCallback? onRequestTap;

  const ProviderDetailSheet({
    super.key,
    required this.provider,
    this.onRequestTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(_detailProvider(provider.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            _buildHandle(),
            _buildImageBanner(),
            _buildStatsRow(detailAsync.valueOrNull?.provider ?? provider),
            _buildInfoSection(detailAsync.valueOrNull?.provider ?? provider),
            _buildReviewsSection(detailAsync),
            _buildCta(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildImageBanner() {
    return Stack(
      children: [
        SizedBox(
          height: 192,
          width: double.infinity,
          child: provider.logoUrl != null
              ? CachedNetworkImage(imageUrl: provider.logoUrl!, fit: BoxFit.cover)
              : Container(
                  color: AppColors.gray100,
                  child: const Center(child: Icon(Icons.business, size: 64, color: AppColors.gray300)),
                ),
        ),
        Container(
          height: 192,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  provider.companyName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              if (provider.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary600,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Onaylı', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ProviderModel p) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          _StatItem(label: 'Puan', value: p.averageRating ?? '—'),
          _divider(),
          _StatItem(label: 'Değerlendirme', value: '${p.totalReviews}'),
          _divider(),
          _StatItem(label: 'Tamamlanan', value: '${p.totalJobs}'),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: AppColors.gray200);

  Widget _buildInfoSection(ProviderModel p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.serviceAreas.isNotEmpty) ...[
            const Text('Hizmet Alanları', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.serviceAreas.map((key) {
                final area = findServiceArea(key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: area?.bg ?? AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (area != null) ...[
                        Icon(area.icon, size: 13, color: area.color),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        area?.label ?? key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: area?.color ?? AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (p.description != null && p.description!.isNotEmpty) ...[
            const Text('Hakkında', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900)),
            const SizedBox(height: 8),
            Text(p.description!, style: const TextStyle(fontSize: 14, color: AppColors.gray600, height: 1.5)),
            const SizedBox(height: 16),
          ],
          if ((p.city ?? '').isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.gray400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [p.city, p.district, p.address].whereType<String>().join(', '),
                    style: const TextStyle(fontSize: 14, color: AppColors.gray600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (p.latitude != null && p.longitude != null) ...[
            _ProviderMap(provider: p),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openMaps(p),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Google Haritada Aç'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue600,
                side: const BorderSide(color: AppColors.blue600),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsSection(AsyncValue<ProviderDetailResult> detailAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.gray100),
          const SizedBox(height: 12),
          const Text('Değerlendirmeler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900)),
          const SizedBox(height: 12),
          detailAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, stack) => const Text('Değerlendirmeler yüklenemedi.', style: TextStyle(color: AppColors.gray500, fontSize: 13)),
            data: (detail) {
              if (detail.reviews.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Henüz değerlendirme yok.', style: TextStyle(color: AppColors.gray500, fontSize: 13)),
                );
              }
              return Column(
                children: detail.reviews.map(_ReviewCard.new).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: GestureDetector(
        onTap: onRequestTap ?? () => Navigator.of(context).pop(),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary600, AppColors.primaryTeal],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary600.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Bu Servise Talep Gönder',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMaps(ProviderModel p) async {
    final uri = Uri.parse(p.mapsUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.gray900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard(this.review);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary600.withValues(alpha: 0.1),
                child: Text(
                  review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                    _StarRow(rating: review.rating),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.4)),
          ],
          if (review.providerReply != null && review.providerReply!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary600.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: AppColors.primary600, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 13, color: AppColors.primary600),
                      const SizedBox(width: 4),
                      const Text(
                        'İşletme Yanıtı',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(review.providerReply!, style: const TextStyle(fontSize: 12, color: AppColors.gray700, height: 1.4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) => Icon(
        i < rating ? Icons.star : Icons.star_border,
        size: 12,
        color: i < rating ? const Color(0xFFFBBF24) : AppColors.gray200,
      )),
    );
  }
}

// ─── Provider Map ─────────────────────────────────────────────────────────────

class _ProviderMap extends StatelessWidget {
  final ProviderModel provider;
  const _ProviderMap({required this.provider});

  @override
  Widget build(BuildContext context) {
    final lat = double.tryParse(provider.latitude ?? '');
    final lng = double.tryParse(provider.longitude ?? '');
    if (lat == null || lng == null) return const SizedBox.shrink();

    final position = LatLng(lat, lng);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 160,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: position, zoom: 15),
          markers: {
            Marker(
              markerId: const MarkerId('provider'),
              position: position,
            ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
        ),
      ),
    );
  }
}
