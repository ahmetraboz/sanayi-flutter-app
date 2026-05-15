import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/provider_model.dart';

class ProviderCard extends StatelessWidget {
  final ProviderModel provider;
  final VoidCallback onTap;

  const ProviderCard({super.key, required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageBanner(),
            Expanded(child: _buildCardBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBanner() {
    return Stack(
      children: [
        SizedBox(
          height: 120,
          width: double.infinity,
          child: provider.logoUrl != null
              ? CachedNetworkImage(
                  imageUrl: provider.logoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: AppColors.gray100),
                  errorWidget: (context, url, error) => _buildPlaceholderBanner(),
                )
              : _buildPlaceholderBanner(),
        ),
        if (provider.isVerified)
          Positioned(
            top: 8,
            left: 8,
            child: _VerificationBadge(),
          ),
        if (provider.averageRating != null)
          Positioned(
            top: 8,
            right: 8,
            child: _RatingBadge(rating: provider.averageRating!),
          ),
      ],
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      color: AppColors.gray100,
      child: const Center(
        child: Icon(Icons.business, size: 40, color: AppColors.gray300),
      ),
    );
  }

  Widget _buildCardBody() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.companyName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 11, color: AppColors.gray400),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  [provider.city, provider.district].whereType<String>().join(', '),
                  style: const TextStyle(fontSize: 11, color: AppColors.gray500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _MiniChip(icon: Icons.star, value: provider.averageRating ?? '—', color: const Color(0xFFFBBF24)),
        _MiniChip(icon: Icons.chat_bubble_outline, value: '${provider.totalReviews}', color: AppColors.blue600),
        _MiniChip(icon: Icons.build_outlined, value: '${provider.totalJobs}', color: AppColors.primary600),
      ],
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary600,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield, size: 10, color: Colors.white),
          SizedBox(width: 3),
          Text('Onaylı', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final String rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: Color(0xFFFBBF24)),
          const SizedBox(width: 3),
          Text(rating, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gray900)),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MiniChip({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 2),
        Text(value, style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
      ],
    );
  }
}
