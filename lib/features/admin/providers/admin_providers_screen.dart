import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme.dart';
import 'admin_providers_notifier.dart';
import '../../../../shared/models/provider_model.dart';

class AdminProvidersScreen extends ConsumerWidget {
  const AdminProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminProvidersProvider);
    final notifier = ref.read(adminProvidersProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sağlayıcılar',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
            ),
            if (state.providers.isNotEmpty)
              Text(
                'Onaylı ${state.providers.length} sağlayıcı',
                style: const TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (!state.loading)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.gray600),
              onPressed: () => notifier.load(),
            ),
        ],
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminProvidersState state,
    AdminProvidersNotifier notifier,
  ) {
    if (state.loading && state.providers.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary600));
    }

    if (state.error != null && state.providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red700),
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(color: AppColors.red700)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => notifier.load(),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (state.providers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 48, color: AppColors.gray400),
            SizedBox(height: 16),
            Text('Onaylı sağlayıcı bulunamadı.', style: TextStyle(color: AppColors.gray600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      color: AppColors.primary600,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.providers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _ProviderCard(provider: state.providers[index]);
        },
      ),
    );
  }
}

// ─── Provider Card ─────────────────────────────────────────────────────────────

class _ProviderCard extends StatelessWidget {
  final ProviderModel provider;

  const _ProviderCard({required this.provider});

  Future<void> _openMaps() async {
    final uri = Uri.parse(provider.mapsUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final rating = double.tryParse(provider.averageRating ?? '') ?? 0.0;

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
          // Header row
          Row(
            children: [
              _Avatar(logoUrl: provider.logoUrl, companyName: provider.companyName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.companyName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (provider.isVerified)
                          const _VerifiedBadge(),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.gray400),
                        const SizedBox(width: 3),
                        Text(
                          [provider.district, provider.city]
                              .whereType<String>()
                              .join(', '),
                          style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Description
          if (provider.description != null && provider.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              provider.description!,
              style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.gray100),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.star_rounded,
                iconColor: AppColors.amber600,
                value: rating > 0 ? rating.toStringAsFixed(1) : '—',
                label: 'Puan',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.reviews_outlined,
                iconColor: AppColors.primary600,
                value: provider.totalReviews.toString(),
                label: 'Değerlendirme',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.work_outline,
                iconColor: AppColors.gray500,
                value: provider.totalJobs.toString(),
                label: 'İş',
              ),
              const Spacer(),
              if (provider.latitude != null || provider.longitude != null)
                GestureDetector(
                  onTap: _openMaps,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 14, color: AppColors.primary600),
                        SizedBox(width: 4),
                        Text(
                          'Haritada Gör',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary600),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? logoUrl;
  final String companyName;

  const _Avatar({required this.logoUrl, required this.companyName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.green50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray100),
      ),
      child: logoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _fallbackIcon(),
              ),
            )
          : _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Center(
      child: Text(
        companyName.isNotEmpty ? companyName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary600,
        ),
      ),
    );
  }
}

// ─── Verified Badge ───────────────────────────────────────────────────────────

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.green50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 11, color: AppColors.primary600),
          SizedBox(width: 3),
          Text(
            'Doğrulandı',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary600),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 3),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray900),
            ),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray500)),
      ],
    );
  }
}
