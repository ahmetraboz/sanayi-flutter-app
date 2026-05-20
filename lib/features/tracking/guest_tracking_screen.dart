import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import 'guest_tracking_notifier.dart';
import 'models/guest_tracking_models.dart';
import 'widgets/progress_timeline.dart';
import 'widgets/quote_card.dart';
import 'widgets/review_form.dart';

const _kMonths = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
String _fmtDate(DateTime dt) => '${dt.day} ${_kMonths[dt.month - 1]} ${dt.year}';

class GuestTrackingScreen extends ConsumerStatefulWidget {
  final String token;
  final String name;
  final String code;

  const GuestTrackingScreen({
    super.key,
    required this.token,
    required this.name,
    required this.code,
  });

  @override
  ConsumerState<GuestTrackingScreen> createState() => _GuestTrackingScreenState();
}

class _GuestTrackingScreenState extends ConsumerState<GuestTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(guestTrackingProvider(widget.token).notifier)
          .loadBooking(name: widget.name, code: widget.code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guestTrackingProvider(widget.token));
    final notifier = ref.read(guestTrackingProvider(widget.token).notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Talep Takip',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: AppColors.gray700),
          onPressed: () => context.go('/servisler'),
        ),
        actions: [
          if (!state.loading)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, color: AppColors.gray600),
              onPressed: () => notifier.loadBooking(name: widget.name, code: widget.code),
            ),
        ],
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(BuildContext context, GuestTrackingState state, GuestTrackingNotifier notifier) {
    if (state.loading && state.booking == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary600, strokeWidth: 2),
      );
    }

    if (state.error != null && state.booking == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_outlined, size: 56, color: AppColors.gray300),
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: const TextStyle(color: AppColors.gray500, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => notifier.loadBooking(name: widget.name, code: widget.code),
                child: const Text('Tekrar Dene', style: TextStyle(color: AppColors.primary600)),
              ),
            ],
          ),
        ),
      );
    }

    final booking = state.booking!;

    return RefreshIndicator(
      color: AppColors.primary600,
      onRefresh: () => notifier.loadBooking(name: widget.name, code: widget.code),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReferenceCard(context, booking),
            const SizedBox(height: 16),
            _buildTimelineCard(booking),
            const SizedBox(height: 16),
            _buildInfoCard(booking),
            if (state.respondError != null) ...[
              const SizedBox(height: 12),
              _errorBanner(state.respondError!),
            ],
            if (booking.responses.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildQuotesSection(state, notifier, booking),
            ],
            if (booking.updates.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildUpdatesSection(booking.updates),
            ],
            if (booking.status == 'completed') ...[
              const SizedBox(height: 16),
              ReviewForm(
                submitting: state.submittingReview,
                submitted: state.reviewSubmitted,
                error: state.reviewError,
                onSubmit: (rating, comment) => notifier.submitReview(rating: rating, comment: comment),
              ),
            ],
            const SizedBox(height: 32),
            _buildCtaRow(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceCard(BuildContext context, GuestBookingTracking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary600, AppColors.primary700],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Referans Kodu',
                    style: TextStyle(fontSize: 12, color: AppColors.emerald200)),
                const SizedBox(height: 4),
                Text(
                  booking.referenceCode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.name,
                  style: const TextStyle(fontSize: 13, color: AppColors.emerald200),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, color: Colors.white),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: booking.referenceCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Referans kodu kopyalandı'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(GuestBookingTracking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: ProgressTimeline(status: booking.status),
    );
  }

  Widget _buildInfoCard(GuestBookingTracking booking) {
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
          Text(
            booking.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900),
          ),
          if (booking.description != null && booking.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(booking.description!,
                style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.5)),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.gray100),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.directions_car_outlined,
              text: '${booking.brand} ${booking.model}'.trim()),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.location_on_outlined, text: booking.city),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.calendar_today_outlined, text: _fmtDate(booking.createdAt)),
        ],
      ),
    );
  }

  Widget _buildQuotesSection(
    GuestTrackingState state,
    GuestTrackingNotifier notifier,
    GuestBookingTracking booking,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('Teklifler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary600,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text('${booking.responses.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        ...booking.responses.map((q) => QuoteCard(
              quote: q,
              responding: state.responding,
              onRespond: (action) => notifier.respondToQuote(q.id, action),
            )),
      ],
    );
  }

  Widget _buildUpdatesSection(List<BookingUpdate> updates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Güncellemeler',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray900)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: updates.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, thickness: 1, color: AppColors.gray100),
            itemBuilder: (context, i) {
              final u = updates[i];

              // Get style based on updateType
              final (typeLabel, typeIcon, typeColor, typeBg) = switch (u.updateType) {
                'completed' => ('Tamamlandı', Icons.check_circle_outline, AppColors.primary600, const Color(0xFFEFF6FF)),
                'delay' => ('Gecikme', Icons.schedule_outlined, AppColors.amber600, const Color(0xFFFFFBEB)),
                _ => ('Güncelleme', Icons.trending_up_outlined, AppColors.blue600, const Color(0xFFEFF6FF)),
              };

              final hasCost = u.laborCost != null || u.partsCost != null || u.totalCost != null;

              return Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(typeIcon, size: 16, color: typeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$typeLabel · ${u.companyName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: typeColor,
                                ),
                              ),
                              Text(
                                _fmtDate(u.createdAt),
                                style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            u.description,
                            style: const TextStyle(fontSize: 13, color: AppColors.gray900, height: 1.4),
                          ),
                          if (u.partsUsed != null && u.partsUsed!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.build_circle_outlined, size: 14, color: AppColors.gray400),
                                const SizedBox(width: 4),
                                const Text(
                                  'Kullanılan Parçalar: ',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray600),
                                ),
                                Expanded(
                                  child: Text(
                                    u.partsUsed!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.gray700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (u.updateType == 'delay' && u.delayReason != null && u.delayReason!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFDBA74).withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.warning_amber_outlined, size: 14, color: Color(0xFFEA580C)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Gecikme Nedeni',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEA580C)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          u.delayReason!,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFFC2410C)),
                                        ),
                                        if (u.delayEstimateDays != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Tahmini Ek Süre: ${u.delayEstimateDays} gün',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFC2410C)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (hasCost) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.gray50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.gray200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Maliyet Kırılımı',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray500),
                                  ),
                                  const SizedBox(height: 6),
                                  if (u.laborCost != null)
                                    _buildCostRow('İşçilik', u.laborCost!),
                                  if (u.partsCost != null)
                                    _buildCostRow('Yedek Parça', u.partsCost!),
                                  if (u.totalCost != null) ...[
                                    const Divider(height: 12, color: AppColors.gray200),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Toplam',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray900),
                                        ),
                                        Text(
                                          '₺${u.totalCost!.toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          if (u.attachmentUrls.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: u.attachmentUrls.map((url) {
                                final isPdf = url.toLowerCase().contains('.pdf') || url.toLowerCase().contains('pdf');
                                return GestureDetector(
                                  onTap: () async {
                                    final uri = Uri.parse(url);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: isPdf
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF2F2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFFCA5A5)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.picture_as_pdf_outlined, size: 14, color: AppColors.red700),
                                              SizedBox(width: 6),
                                              Text(
                                                'Fatura.pdf',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.red700),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            url,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              width: 56,
                                              height: 56,
                                              color: AppColors.gray100,
                                              child: const Icon(Icons.image_not_supported_outlined, size: 18, color: AppColors.gray400),
                                            ),
                                          ),
                                        ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
          Text('₺${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gray900)),
        ],
      ),
    );
  }

  Widget _buildCtaRow(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.go('/register'),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary600, AppColors.primaryTeal]),
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
              child: Text('Hesap Oluştur',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => context.go('/servisler'),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: const Center(
              child: Text('Ana Sayfa',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.gray700)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String message) {
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
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.red700)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.gray400),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.gray600))),
      ],
    );
  }
}
