import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              return Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: const BoxDecoration(
                        color: AppColors.primary600,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.message,
                              style: const TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.4)),
                          const SizedBox(height: 2),
                          Text(_fmtDate(u.createdAt),
                              style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
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
