import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/app_select_field.dart';
import '../../../shared/widgets/skeleton.dart';
import 'models/request_detail.dart';
import 'request_detail_notifier.dart';
import 'widgets/bid_card.dart';
import 'widgets/request_info_card.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final int requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  bool _showInfoForm = false;
  bool _showReviewForm = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestDetailProvider(widget.requestId));
    final notifier = ref.read(requestDetailProvider(widget.requestId).notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          state.request?.title ?? 'Talep Detayı',
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

  Widget _buildBody(BuildContext context, RequestDetailState state, RequestDetailNotifier notifier) {
    if (state.loading && state.request == null) {
      return const _RequestDetailSkeleton();
    }

    if (state.error != null && state.request == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.gray500, fontSize: 14)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: notifier.loadDetail,
              child: const Text('Tekrar Dene', style: TextStyle(color: AppColors.primary600)),
            ),
          ],
        ),
      );
    }

    final request = state.request!;
    final canAccept = request.status == 'open' ||
        request.status == 'bidding' ||
        request.status == 'info_requested' ||
        request.status == 'info_provided';

    return RefreshIndicator(
      color: AppColors.primary600,
      onRefresh: notifier.loadDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gray200),
              ),
              child: RequestInfoCard(request: request),
            ),
            const SizedBox(height: 16),

            // Action error
            if (state.actionError != null) ...[
              _ErrorBanner(message: state.actionError!),
              const SizedBox(height: 12),
            ],

            // Ek bilgi talebi bölümü
            if (state.isInfoRequested) ...[
              if (!_showInfoForm)
                _InfoRequestedCard(
                  infoRequest: state.infoRequest,
                  onRespond: () => setState(() => _showInfoForm = true),
                  onReject: () async {
                    final ok = await notifier.rejectInfo();
                    if (ok && mounted) setState(() {});
                  },
                  rejectingInfo: state.rejectingInfo,
                )
              else
                _InfoSubmitForm(
                  infoRequest: state.infoRequest,
                  submitting: state.submittingInfo,
                  onSubmit: (data) async {
                    final ok = await notifier.submitInfo(data);
                    if (ok && mounted) setState(() => _showInfoForm = false);
                  },
                  onCancel: () => setState(() => _showInfoForm = false),
                ),
              const SizedBox(height: 12),
            ],

            // Fatura görünümü
            if (state.completionUpdate != null) ...[
              _InvoiceCard(update: state.completionUpdate!),
              const SizedBox(height: 12),
            ],

            // Tamamla butonu
            if (state.canComplete) ...[
              _CompleteRequestButton(
                completing: state.completing,
                onTap: () async {
                  final confirm = await _confirmDialog(
                    context,
                    title: 'Talebi Tamamla',
                    message: 'Hizmet tamamlandı olarak işaretlenecek. Devam etmek istiyor musunuz?',
                    confirmLabel: 'Tamamla',
                  );
                  if (confirm == true) notifier.completeRequest();
                },
              ),
              const SizedBox(height: 12),
            ],

            // İptal butonu
            if (state.canCancel) ...[
              _CancelRequestButton(
                cancelling: state.cancelling,
                onTap: () async {
                  final confirm = await _confirmDialog(
                    context,
                    title: 'Talebi İptal Et',
                    message: 'Bu talebi iptal etmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
                    confirmLabel: 'İptal Et',
                    isDestructive: true,
                  );
                  if (confirm == true) notifier.cancelRequest();
                },
              ),
              const SizedBox(height: 12),
            ],

            // Değerlendirme bölümü
            if (state.isPendingReview) ...[
              if (!_showReviewForm)
                _PendingReviewCard(
                  onReview: () => setState(() => _showReviewForm = true),
                  onSkip: () => notifier.skipReview(),
                  skipping: state.reviewing,
                ),
              if (_showReviewForm)
                _ReviewForm(
                  submitting: state.reviewing,
                  onSubmit: (rating, comment) async {
                    final ok = await notifier.submitReview(rating: rating, comment: comment);
                    if (ok && mounted) setState(() => _showReviewForm = false);
                  },
                  onCancel: () => setState(() => _showReviewForm = false),
                ),
              const SizedBox(height: 12),
            ],

            // Teklif hatası
            if (state.acceptError != null || state.rejectError != null) ...[
              _ErrorBanner(message: state.acceptError ?? state.rejectError!),
              const SizedBox(height: 12),
            ],

            // Teklifler
            _buildBidsSection(context, state, notifier, canAccept),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBidsSection(
    BuildContext context,
    RequestDetailState state,
    RequestDetailNotifier notifier,
    bool canAccept,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Teklifler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primary600, borderRadius: BorderRadius.circular(9999)),
              child: Text('${state.bids.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.bids.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 40, color: AppColors.gray300),
                  SizedBox(height: 8),
                  Text('Henüz teklif gelmedi.', style: TextStyle(fontSize: 14, color: AppColors.gray400)),
                ],
              ),
            ),
          )
        else
          ...state.bids.map(
            (bid) => BidCard(
              bid: bid,
              canAccept: canAccept,
              accepting: state.accepting,
              rejecting: state.rejecting,
              onAccept: () => notifier.acceptBid(bid.id),
              onReject: () => notifier.rejectBid(bid.id),
              onCounterDate: (date) => notifier.counterDate(bidId: bid.id, date: date),
              onAcceptDate: () => notifier.acceptDate(bidId: bid.id),
            ),
          ),
      ],
    );
  }

  Future<bool?> _confirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    final confirmColor = isDestructive ? AppColors.red700 : AppColors.primary600;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text(message, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç', style: TextStyle(color: AppColors.gray500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.red100),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.red700),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.red700))),
        ],
      ),
    );
  }
}

// ─── Info Requested Card ──────────────────────────────────────────────────────

class _InfoRequestedCard extends StatelessWidget {
  final InfoRequestData? infoRequest;
  final VoidCallback onRespond;
  final VoidCallback onReject;
  final bool rejectingInfo;

  const _InfoRequestedCard({
    required this.infoRequest,
    required this.onRespond,
    required this.onReject,
    required this.rejectingInfo,
  });

  @override
  Widget build(BuildContext context) {
    final ir = infoRequest;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.amber600, size: 18),
              SizedBox(width: 8),
              Text('Ek Bilgi Talep Edildi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gray900)),
            ],
          ),
          const SizedBox(height: 8),
          if (ir?.additionalNotes != null && ir!.additionalNotes!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber200),
              ),
              child: Text(
                ir.additionalNotes!,
                style: const TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.5),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (ir != null && ir.hasAnyField) ...[
            const Text('İstenen bilgiler:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray500)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (ir.wantsFuelType) _FieldChip('Yakıt Tipi'),
                if (ir.wantsTransmissionType) _FieldChip('Şanzıman'),
                if (ir.wantsBodyType) _FieldChip('Kasa Tipi'),
                if (ir.wantsEngineDisplacement) _FieldChip('Motor Hacmi'),
                if (ir.wantsMileage) _FieldChip('Kilometre'),
              ],
            ),
            const SizedBox(height: 12),
          ] else ...[
            const Text(
              'Servis sağlayıcı aracınız hakkında ek bilgi istedi.',
              style: TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.5),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: rejectingInfo ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red700,
                    side: const BorderSide(color: AppColors.red700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: rejectingInfo
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.red700))
                      : const Text('Reddet'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRespond,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Bilgi Gönder'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldChip extends StatelessWidget {
  final String label;
  const _FieldChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.amber100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.amber700)),
    );
  }
}

// ─── Info Submit Form ─────────────────────────────────────────────────────────

const _kFuelTypes = ['Benzin', 'Dizel', 'LPG', 'Hibrit', 'Elektrik'];
const _kTransmissions = ['Manuel', 'Otomatik', 'Yarı Otomatik'];
const _kBodyTypes = ['Sedan', 'Hatchback', 'SUV', 'Station Wagon', 'Coupe', 'Cabrio', 'Pickup', 'Van'];

class _InfoSubmitForm extends StatefulWidget {
  final InfoRequestData? infoRequest;
  final bool submitting;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onCancel;

  const _InfoSubmitForm({
    required this.infoRequest,
    required this.submitting,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<_InfoSubmitForm> createState() => _InfoSubmitFormState();
}

class _InfoSubmitFormState extends State<_InfoSubmitForm> {
  String? _fuelType;
  String? _transmission;
  String? _bodyType;
  final _engineCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();

  @override
  void dispose() {
    _engineCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }

  bool get _showFuelType => widget.infoRequest?.wantsFuelType ?? true;
  bool get _showTransmission => widget.infoRequest?.wantsTransmissionType ?? true;
  bool get _showBodyType => widget.infoRequest?.wantsBodyType ?? true;
  bool get _showEngine => widget.infoRequest?.wantsEngineDisplacement ?? true;
  bool get _showMileage => widget.infoRequest?.wantsMileage ?? true;

  @override
  Widget build(BuildContext context) {
    final ir = widget.infoRequest;
    final showDropdownRow = _showFuelType || _showTransmission;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber600, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ek Bilgileri Doldurun', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gray900)),
          if (ir?.additionalNotes != null && ir!.additionalNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amber50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(ir.additionalNotes!, style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.4)),
            ),
          ],
          const SizedBox(height: 14),
          if (showDropdownRow) ...[
            Row(
              children: [
                if (_showFuelType)
                  Expanded(child: _Dropdown(label: 'Yakıt Tipi', value: _fuelType, items: _kFuelTypes, onChanged: (v) => setState(() => _fuelType = v))),
                if (_showFuelType && _showTransmission)
                  const SizedBox(width: 10),
                if (_showTransmission)
                  Expanded(child: _Dropdown(label: 'Şanzıman', value: _transmission, items: _kTransmissions, onChanged: (v) => setState(() => _transmission = v))),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (_showBodyType) ...[
            _Dropdown(label: 'Kasa Tipi', value: _bodyType, items: _kBodyTypes, onChanged: (v) => setState(() => _bodyType = v)),
            const SizedBox(height: 10),
          ],
          if (_showEngine || _showMileage) ...[
            Row(
              children: [
                if (_showEngine)
                  Expanded(
                    child: TextField(
                      controller: _engineCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _fd('Motor Hacmi (L)'),
                    ),
                  ),
                if (_showEngine && _showMileage) const SizedBox(width: 10),
                if (_showMileage)
                  Expanded(
                    child: TextField(
                      controller: _mileageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _fd('Kilometre'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.submitting ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray600,
                    side: const BorderSide(color: AppColors.gray300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Vazgeç'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.submitting
                      ? null
                      : () {
                          final mileageRaw = _mileageCtrl.text.trim();
                          final engineRaw = _engineCtrl.text.trim();
                          widget.onSubmit({
                            if (_fuelType != null) 'fuelType': _fuelType,
                            if (_transmission != null) 'transmissionType': _transmission,
                            if (_bodyType != null) 'bodyType': _bodyType,
                            if (engineRaw.isNotEmpty && int.tryParse(engineRaw) != null)
                              'engineDisplacement': int.parse(engineRaw),
                            if (mileageRaw.isNotEmpty && int.tryParse(mileageRaw) != null)
                              'mileage': int.parse(mileageRaw),
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: widget.submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Gönder'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _fd(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 13, color: AppColors.gray500),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary600)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true,
    fillColor: AppColors.gray50,
  );
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppSelectField(
      options: items,
      value: value,
      hintText: label,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray500),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary600)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: AppColors.gray50,
      ),
      style: const TextStyle(color: AppColors.gray900, fontSize: 13),
      onChanged: onChanged,
    );
  }
}

// ─── Complete Request Button ──────────────────────────────────────────────────

class _CompleteRequestButton extends StatelessWidget {
  final bool completing;
  final VoidCallback onTap;

  const _CompleteRequestButton({required this.completing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: completing ? null : onTap,
        icon: completing
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.check_circle_outline, size: 18),
        label: const Text('Hizmeti Tamamla', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─── Cancel Request Button ────────────────────────────────────────────────────

class _CancelRequestButton extends StatelessWidget {
  final bool cancelling;
  final VoidCallback onTap;

  const _CancelRequestButton({required this.cancelling, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: cancelling ? null : onTap,
        icon: cancelling
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.cancel_outlined, size: 18),
        label: const Text('Talebi İptal Et', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─── Pending Review Card ──────────────────────────────────────────────────────

class _PendingReviewCard extends StatelessWidget {
  final VoidCallback onReview;
  final Future<void> Function() onSkip;
  final bool skipping;

  const _PendingReviewCard({required this.onReview, required this.onSkip, required this.skipping});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emerald200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star_outline, color: AppColors.primary600, size: 18),
              SizedBox(width: 8),
              Text('Hizmet Tamamlandı!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gray900)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Servis sağlayıcıyı değerlendirin. Değerlendirmeniz diğer kullanıcılara yardımcı olacak.',
            style: TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: skipping ? null : onReview,
              icon: const Icon(Icons.star, size: 16),
              label: const Text('Değerlendirme Yap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: skipping ? null : onSkip,
              child: skipping
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Değerlendirmeyi Atla', style: TextStyle(color: AppColors.gray500, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Review Form ──────────────────────────────────────────────────────────────

class _ReviewForm extends StatefulWidget {
  final bool submitting;
  final Future<void> Function(int rating, String? comment) onSubmit;
  final VoidCallback onCancel;

  const _ReviewForm({required this.submitting, required this.onSubmit, required this.onCancel});

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary600, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Değerlendirme', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gray900)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color: star <= _rating ? AppColors.amber600 : AppColors.gray300,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _ratingLabel(_rating),
              style: const TextStyle(fontSize: 13, color: AppColors.gray500),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Yorumunuzu yazın (opsiyonel)...',
              hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary600)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.submitting ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray600,
                    side: const BorderSide(color: AppColors.gray300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Vazgeç'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.submitting
                      ? null
                      : () => widget.onSubmit(_rating, _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: widget.submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Gönder'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _ratingLabel(int rating) => switch (rating) {
    1 => 'Çok Kötü',
    2 => 'Kötü',
    3 => 'Orta',
    4 => 'İyi',
    5 => 'Mükemmel',
    _ => '',
  };
}

// ─── Invoice Card ─────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final JobUpdate update;
  const _InvoiceCard({required this.update});

  @override
  Widget build(BuildContext context) {
    final hasItems = update.costItems.isNotEmpty;
    final hasKdv = update.kdvAmount != null && update.kdvAmount! > 0;
    final total = update.totalCost ?? (update.subtotal + (update.kdvAmount ?? 0));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: AppColors.primary600,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Servis Faturası',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    Text(
                      update.companyName,
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

          // Bütçe aşım uyarısı
          if (update.overBudgetReason != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.red100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.red700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bütçe Aşım Nedeni',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          update.overBudgetReason!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.red700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 1, color: AppColors.gray100),

          // Kalem listesi
          if (hasItems) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                children: update.costItems
                    .map((item) => _InvoiceRow(label: item.name, amount: item.amount))
                    .toList(),
              ),
            ),
            const Divider(height: 24, indent: 16, endIndent: 16, color: AppColors.gray100),
          ],

          // Ara toplam + KDV + Toplam
          Padding(
            padding: EdgeInsets.fromLTRB(16, hasItems ? 0 : 14, 16, 16),
            child: Column(
              children: [
                if (hasItems && hasKdv) ...[
                  _InvoiceRow(
                    label: 'Ara Toplam',
                    amount: update.subtotal,
                    isSubtle: true,
                  ),
                  const SizedBox(height: 6),
                ],
                if (hasKdv) ...[
                  _InvoiceRow(
                    label: 'KDV (%${update.kdvRate?.toStringAsFixed(0) ?? ''})',
                    amount: update.kdvAmount!,
                    isSubtle: true,
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.gray200),
                  const SizedBox(height: 10),
                ],
                _InvoiceRow(
                  label: 'Genel Toplam',
                  amount: total,
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isSubtle;
  final bool isTotal;

  const _InvoiceRow({
    required this.label,
    required this.amount,
    this.isSubtle = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isSubtle ? AppColors.gray500 : AppColors.gray700,
            ),
          ),
          Text(
            '₺${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 17 : 13,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal ? AppColors.primary600 : AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestDetailSkeleton extends StatelessWidget {
  const _RequestDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(child: SkeletonBox(height: 22, radius: 6)),
              SizedBox(width: 12),
              SkeletonBox(width: 70, height: 28, radius: 8),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonBox(height: 13, radius: 4),
          const SizedBox(height: 6),
          const SkeletonBox(height: 13, radius: 4),
          const SizedBox(height: 6),
          const SkeletonBox(height: 13, width: 200, radius: 4),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: List.generate(4, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: const Row(
                  children: [
                    SkeletonBox(width: 70, height: 12, radius: 4),
                    SizedBox(width: 16),
                    Expanded(child: SkeletonBox(height: 12, radius: 4)),
                  ],
                ),
              )),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              SkeletonBox(width: 110, height: 28, radius: 8),
              SizedBox(width: 8),
              SkeletonBox(width: 70, height: 28, radius: 8),
              SizedBox(width: 8),
              SkeletonBox(width: 80, height: 28, radius: 8),
            ],
          ),
        ],
      ),
    );
  }
}
