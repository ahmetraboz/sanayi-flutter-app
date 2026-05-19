import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/services/car_api_service.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/header_actions.dart';
import '../../../shared/widgets/skeleton.dart';
import 'models/vehicle_detail.dart';
import 'vehicles_list_notifier.dart';
import 'widgets/vehicle_form_sheet.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehiclesListProvider);
    final notifier = ref.read(vehiclesListProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 56,
        ),
        child: FloatingActionButton(
          onPressed: () => _showVehicleForm(context),
          backgroundColor: AppColors.primary600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: 'Araçlarım',
              action: const HeaderActions(),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody(context, state, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, VehiclesListState state, VehiclesListNotifier notifier) {
    if (state.loading && state.vehicles.isEmpty) {
      return const _VehicleListSkeleton();
    }

    if (state.error != null && state.vehicles.isEmpty) {
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

    if (state.vehicles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success50,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.directions_car_outlined, size: 40, color: AppColors.primary600),
              ),
              const SizedBox(height: 24),
              const Text(
                'Henüz araç eklenmemiş',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.gray900),
              ),
              const SizedBox(height: 12),
              const Text(
                'Servis talebi oluşturabilmek için önce bir araç ekleyin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.gray500, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showVehicleForm(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('İlk Aracınızı Ekleyin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary600,
      onRefresh: notifier.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: state.vehicles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final vehicle = state.vehicles[index];
          return _VehicleCard(
            vehicle: vehicle,
            onEdit: () => _showVehicleForm(context, vehicle: vehicle),
            onDelete: () => _showDeleteConfirm(context, notifier, vehicle),
          );
        },
      ),
    );
  }

  void _showVehicleForm(BuildContext context, {VehicleDetail? vehicle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => VehicleFormSheet(vehicle: vehicle),
    );
  }

  void _showDeleteConfirm(BuildContext context, VehiclesListNotifier notifier, VehicleDetail vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aracı Sil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: Text('${vehicle.brand} ${vehicle.model} aracını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: AppColors.gray600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.deleteVehicle(vehicle.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Araç başarıyla silindi')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red700));
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

class _VehicleCard extends ConsumerWidget {
  final VehicleDetail vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carApi = ref.read(carApiServiceProvider);

    return InkWell(
      onTap: () => context.push('/dashboard/vehicles/${vehicle.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  FutureBuilder<String?>(
                    future: carApi.getVehicleImage(vehicle.brand, vehicle.model, vehicle.year),
                    builder: (context, snapshot) {
                      final url = snapshot.data;
                      if (url != null && url.isNotEmpty) {
                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.directions_car_outlined, size: 48, color: AppColors.gray300),
                            ),
                          ),
                        );
                      }
                      return const Center(child: Icon(Icons.directions_car_outlined, size: 48, color: AppColors.gray300));
                    },
                  ),
                  if (vehicle.year != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          vehicle.year.toString(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gray700),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(Icons.edit_outlined, AppColors.gray700, onEdit),
                        const SizedBox(width: 8),
                        _buildActionButton(Icons.delete_outline, AppColors.red700, onDelete),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle.brand} ${vehicle.model}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (vehicle.licensePlate != null && vehicle.licensePlate!.isNotEmpty) ...[
                        Icon(Icons.badge_outlined, size: 14, color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Text(
                          vehicle.licensePlate!,
                          style: const TextStyle(fontSize: 13, color: AppColors.gray600, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.gray500),
                      const SizedBox(width: 4),
                      Text(
                        '${vehicle.createdAt.day.toString().padLeft(2, '0')}.${vehicle.createdAt.month.toString().padLeft(2, '0')}.${vehicle.createdAt.year}',
                        style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detayları Gör',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary600),
                      ),
                      Icon(Icons.arrow_forward, size: 16, color: AppColors.primary600),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
          ],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _VehicleListSkeleton extends StatelessWidget {
  const _VehicleListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const SkeletonBox(width: 52, height: 52, radius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 15, radius: 5),
                  SizedBox(height: 7),
                  SkeletonBox(height: 12, width: 140, radius: 4),
                  SizedBox(height: 6),
                  SkeletonBox(height: 11, width: 90, radius: 4),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SkeletonBox(width: 24, height: 24, radius: 6),
          ],
        ),
      ),
    );
  }
}
