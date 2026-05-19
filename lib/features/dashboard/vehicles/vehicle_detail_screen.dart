import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/services/car_api_service.dart';
import '../../../shared/widgets/skeleton.dart';
import 'vehicle_detail_notifier.dart';
import 'models/vehicle_detail.dart';

const _categoryIcons = <String, IconData>{
  'motor': Icons.local_fire_department_outlined,
  'elektrik': Icons.bolt_outlined,
  'fren': Icons.stop_circle_outlined,
  'suspan': Icons.tune_outlined,
  'kaporta': Icons.format_paint_outlined,
  'klima': Icons.ac_unit_outlined,
  'lastik': Icons.tire_repair_outlined,
  'vites': Icons.settings_outlined,
  'egzoz': Icons.cloud_outlined,
  'diger': Icons.help_outline,
};

const _categoryLabels = <String, String>{
  'motor': 'Motor',
  'elektrik': 'Elektrik',
  'fren': 'Fren',
  'suspan': 'Süspansiyon',
  'kaporta': 'Kaporta',
  'klima': 'Klima',
  'lastik': 'Lastik',
  'vites': 'Vites',
  'egzoz': 'Egzoz',
  'diger': 'Diğer',
};

const _statusColors = <String, Color>{
  'open': AppColors.blue600,
  'bidding': AppColors.amber600,
  'accepted': AppColors.green700,
  'in_progress': AppColors.amber600,
  'completed': AppColors.green700,
  'cancelled': AppColors.gray500,
};

const _statusBgColors = <String, Color>{
  'open': AppColors.info50,
  'bidding': AppColors.warning50,
  'accepted': AppColors.success50,
  'in_progress': AppColors.warning50,
  'completed': AppColors.success50,
  'cancelled': AppColors.gray100,
};

const _statusLabels = <String, String>{
  'open': 'Açık',
  'bidding': 'Teklifler Var',
  'info_requested': 'Bilgi Bekleniyor',
  'info_provided': 'Bilgi Verildi',
  'accepted': 'Kabul Edildi',
  'in_progress': 'Devam Ediyor',
  'completed': 'Tamamlandı',
  'cancelled': 'İptal',
};

class VehicleDetailScreen extends ConsumerWidget {
  final int vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehicleDetailProvider(vehicleId));
    final notifier = ref.read(vehicleDetailProvider(vehicleId).notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Araç Detayı',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.vehicle != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.red700),
              onPressed:
                  () => _showDeleteConfirm(context, notifier, state.vehicle!),
            ),
        ],
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    VehicleDetailState state,
    VehicleDetailNotifier notifier,
  ) {
    if (state.loading && state.vehicle == null) {
      return const _VehicleDetailSkeleton();
    }

    if (state.error != null && state.vehicle == null) {
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

    final vehicle = state.vehicle;
    if (vehicle == null) {
      return const Center(child: Text('Araç bulunamadı'));
    }

    return RefreshIndicator(
      color: AppColors.primary600,
      onRefresh: notifier.load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildVehicleCard(vehicle),
          const SizedBox(height: 24),
          _buildRequestsSection(context, state.requests),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(VehicleDetail vehicle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VehicleImageBanner(vehicle),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle.brand} ${vehicle.model}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (vehicle.year != null)
                      _buildChip(
                        Icons.calendar_month_outlined,
                        '${vehicle.year} Model',
                      ),
                    if (vehicle.licensePlate != null &&
                        vehicle.licensePlate!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 16,
                              color: AppColors.gray600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              vehicle.licensePlate!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                                color: AppColors.gray900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (vehicle.engineDisplacement != null ||
                    vehicle.fuelType != null ||
                    vehicle.transmissionType != null) ...[
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.gray100),
                  const SizedBox(height: 16),
                  const Text(
                    'TEKNİK DETAYLAR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (vehicle.engineDisplacement != null &&
                          vehicle.engineDisplacement!.isNotEmpty)
                        _buildTechSpec(
                          Icons.settings_outlined,
                          'Motor',
                          vehicle.engineDisplacement!,
                        ),
                      if (vehicle.fuelType != null &&
                          vehicle.fuelType!.isNotEmpty)
                        _buildTechSpec(
                          Icons.local_fire_department_outlined,
                          'Yakıt',
                          vehicle.fuelType!,
                          color: AppColors.amber700,
                        ),
                      if (vehicle.transmissionType != null &&
                          vehicle.transmissionType!.isNotEmpty)
                        _buildTechSpec(
                          Icons.tune_outlined,
                          'Şanzıman',
                          vehicle.transmissionType!,
                          color: AppColors.blue600,
                        ),
                      if (vehicle.driveType != null &&
                          vehicle.driveType!.isNotEmpty)
                        _buildTechSpec(
                          Icons.open_with_outlined,
                          'Çekiş',
                          vehicle.driveType!,
                          color: AppColors.violet700,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.gray500),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.gray600),
        ),
      ],
    );
  }

  Widget _buildTechSpec(
    IconData icon,
    String title,
    String value, {
    Color color = AppColors.gray500,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsSection(
    BuildContext context,
    List<VehicleRequestItem> requests,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.build_outlined,
                  size: 20,
                  color: AppColors.primary600,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Servis Geçmişi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                if (requests.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${requests.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            TextButton.icon(
              onPressed: () => context.push('/dashboard/requests/new'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Yeni Talep'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (requests.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gray200,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: AppColors.gray300,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bu araç için henüz servis talebi yok',
                    style: TextStyle(fontSize: 14, color: AppColors.gray500),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/dashboard/requests/new'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('İlk Talebi Oluştur'),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _buildRequestItem(context, requests[i]),
          ),
      ],
    );
  }

  Widget _buildRequestItem(BuildContext context, VehicleRequestItem req) {
    final label = _statusLabels[req.status] ?? req.status;
    final color = _statusColors[req.status] ?? AppColors.gray500;
    final bgColor = _statusBgColors[req.status] ?? AppColors.gray100;

    return InkWell(
      onTap: () => context.push('/dashboard/requests/${req.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _categoryIcons[req.problemCategory] ?? Icons.build_outlined,
                size: 20,
                color: AppColors.primary600,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    req.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (req.problemCategory != null &&
                          _categoryLabels[req.problemCategory] != null) ...[
                        Text(
                          _categoryLabels[req.problemCategory]!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '·',
                            style: TextStyle(color: AppColors.gray400),
                          ),
                        ),
                      ],
                      Text(
                        '${req.createdAt.day.toString().padLeft(2, '0')}.${req.createdAt.month.toString().padLeft(2, '0')}.${req.createdAt.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.gray300),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    VehicleDetailNotifier notifier,
    VehicleDetail vehicle,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text(
              'Aracı Sil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            content: Text(
              '${vehicle.brand} ${vehicle.model} aracını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'İptal',
                  style: TextStyle(color: AppColors.gray600),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await notifier.deleteVehicle();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Araç başarıyla silindi')),
                      );
                      context.pop(); // Go back to vehicles list
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppColors.red700,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Sil'),
              ),
            ],
          ),
    );
  }
}

// ─── Vehicle Image Banner ─────────────────────────────────────────────────────

final _vehicleImageProvider = FutureProvider.autoDispose.family<String?, VehicleDetail>((ref, vehicle) {
  return ref.read(carApiServiceProvider).getVehicleImage(vehicle.brand, vehicle.model, vehicle.year);
});

class _VehicleImageBanner extends ConsumerWidget {
  final VehicleDetail vehicle;
  const _VehicleImageBanner(this.vehicle);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageAsync = ref.watch(_vehicleImageProvider(vehicle));
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: imageAsync.when(
          loading: () => const _CarPlaceholder(),
          error: (_, __) => const _CarPlaceholder(),
          data: (url) => url != null
              ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
              : const _CarPlaceholder(),
        ),
      ),
    );
  }
}

class _CarPlaceholder extends StatelessWidget {
  const _CarPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray100,
      child: const Center(
        child: Icon(Icons.directions_car_outlined, size: 64, color: AppColors.gray300),
      ),
    );
  }
}

class _VehicleDetailSkeleton extends StatelessWidget {
  const _VehicleDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Row(
              children: [
                SkeletonBox(width: 60, height: 60, radius: 14),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 16, radius: 5),
                      SizedBox(height: 8),
                      SkeletonBox(height: 13, width: 100, radius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: List.generate(6, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: const Row(
                  children: [
                    SkeletonBox(width: 80, height: 12, radius: 4),
                    SizedBox(width: 16),
                    Expanded(child: SkeletonBox(height: 12, radius: 4)),
                  ],
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
