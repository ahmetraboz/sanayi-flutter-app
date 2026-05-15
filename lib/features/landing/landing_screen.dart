import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pageCount = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipToLast() {
    _pageController.animateToPage(
      _pageCount - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pageCount - 1;
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _PageBackground(
                color: const Color(0xFFECFDF5),
                child: SingleChildScrollView(child: _HeroSection(onNext: _nextPage, topPadding: top)),
              ),
              _PageBackground(
                color: AppColors.gray50,
                child: SingleChildScrollView(child: const _HowItWorksSection()),
              ),
              _PageBackground(
                color: Colors.white,
                child: SingleChildScrollView(child: const _FeaturesSection()),
              ),
              _PageBackground(
                color: AppColors.gray50,
                child: SingleChildScrollView(
                  child: Column(
                    children: const [
                      _TestimonialsSection(),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _AuthPage(
                onLogin: () => context.push('/login'),
                onRegister: () => context.push('/register'),
                bottomPadding: bottom,
              ),
            ],
          ),
          if (!isLastPage)
            Positioned(
              top: top + 8,
              right: 16,
              child: TextButton(
                onPressed: _skipToLast,
                child: const Text('Atla', style: TextStyle(color: AppColors.gray400, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ),
          Positioned(
            bottom: bottom + 16,
            left: 0,
            right: 0,
            child: _buildPageIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pageCount, (i) {
        final active = i == _currentPage;
        return GestureDetector(
          onTap: () => _pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? AppColors.primary600 : AppColors.gray200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}


// ── Hero Section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final VoidCallback? onNext;
  final double topPadding;
  const _HeroSection({this.onNext, this.topPadding = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5), Colors.white],
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 24 + topPadding, 24, 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Text('🚗  Araç sahipleri için ücretsiz', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aracınız için\nEn İyi Servisi Bulun',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.gray900, height: 1.2),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tek talepte birden fazla doğrulanmış servisten teklif alın.\nFiyatları karşılaştırın, en iyisini seçin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.gray500, height: 1.5),
          ),
          const SizedBox(height: 24),
          const _DiagnosisCard(),
          const SizedBox(height: 24),
          _HeroCta(),
          const SizedBox(height: 24),
          _TrustRow(),
          if (onNext != null) ...[
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onNext,
              child: const Column(
                children: [
                  Text('Daha fazla bilgi', style: TextStyle(fontSize: 13, color: AppColors.gray400, fontWeight: FontWeight.w500)),
                  SizedBox(height: 4),
                  Icon(Icons.keyboard_arrow_down, color: AppColors.gray400, size: 22),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.push('/book'),
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary600, AppColors.primaryTeal]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.primary600.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Ücretsiz Talep Oluştur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OutlineBtn(
                icon: Icons.business_outlined,
                label: 'Servisleri Keşfet',
                onTap: () => context.push('/servisler'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OutlineBtn(
                icon: Icons.search_outlined,
                label: 'Talep Sorgula',
                onTap: () => context.go('/talebim'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.gray600),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
          ],
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _TrustItem(value: '500+', label: 'Doğrulanmış Servis'),
        _TrustDivider(),
        _TrustItem(value: '%30', label: 'Ortalama Tasarruf'),
        _TrustDivider(),
        _TrustItem(value: '4.8★', label: 'Kullanıcı Puanı'),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  final String value;
  final String label;
  const _TrustItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary600)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray500, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _TrustDivider extends StatelessWidget {
  const _TrustDivider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 32, color: AppColors.gray200);
}

// ── How It Works ─────────────────────────────────────────────────────────────

class _HowItWorksSection extends StatefulWidget {
  const _HowItWorksSection();
  @override
  State<_HowItWorksSection> createState() => _HowItWorksSectionState();
}

class _HowItWorksSectionState extends State<_HowItWorksSection> {
  bool _showOwner = true;

  static const _ownerSteps = [
    (icon: Icons.person_add_outlined, title: 'Ücretsiz Hesap Aç', desc: 'Ad, e-posta ve telefon ile 1 dakikada kayıt ol. Kredi kartı gerekmez.'),
    (icon: Icons.directions_car_outlined, title: 'Aracını Ekle', desc: 'Marka, model ve yıl bilgilerini girerek aracını profiline ekle.'),
    (icon: Icons.camera_alt_outlined, title: 'Talep Oluştur', desc: 'Yapılacak işi açıkla, fotoğraf yükle. Detay ne kadar fazlaysa teklif o kadar isabetli.'),
    (icon: Icons.compare_arrows_outlined, title: 'Teklifleri Karşılaştır', desc: 'Doğrulanmış servislerden gelen teklifleri fiyat ve puana göre yan yana değerlendir.'),
    (icon: Icons.star_outline, title: 'Seç ve Değerlendir', desc: 'En uygun teklifi kabul et. İş bittikten sonra servise yıldız ve yorum bırak.'),
  ];

  static const _providerSteps = [
    (icon: Icons.storefront_outlined, title: 'İşletme Hesabı Aç', desc: 'Firma adı, vergi numarası, adres ve iletişim bilgilerini gir.'),
    (icon: Icons.shield_outlined, title: 'Admin Onayını Bekle', desc: 'Ekibimiz başvuruyu inceler. Onaylanan servisler "Doğrulanmış" rozeti kazanır.'),
    (icon: Icons.visibility_outlined, title: 'Açık Talepleri Gör', desc: 'Platformdaki tüm açık talepleri gör. Araç bilgisi, yapılacak iş ve fotoğrafları incele.'),
    (icon: Icons.attach_money_outlined, title: 'Teklif Ver', desc: 'Teklif fiyatını ve açıklamanı gir. Gerekirse müşteriden ek bilgi iste.'),
    (icon: Icons.emoji_events_outlined, title: 'İşi Al, İtibar Kazan', desc: 'Teklif kabul edildiğinde bildirim al, işi tamamla, değerlendirmelerle sıralamanda yüksel.'),
  ];

  @override
  Widget build(BuildContext context) {
    final steps = _showOwner ? _ownerSteps : _providerSteps;

    return Container(
      color: AppColors.gray50,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Column(
        children: [
          const Text('NASIL ÇALIŞIR?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text('Birkaç adımda başlayın', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.gray900)),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _TabBtn(label: 'Araç Sahibiyim', active: _showOwner, onTap: () => setState(() => _showOwner = true)),
                _TabBtn(label: 'Servis Sahibiyim', active: !_showOwner, onTap: () => setState(() => _showOwner = false)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ...steps.asMap().entries.map((e) => _StepItem(index: e.key, step: e.value, total: steps.length)),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? AppColors.gray900 : AppColors.gray500),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int index;
  final ({IconData icon, String title, String desc}) step;
  final int total;
  const _StepItem({required this.index, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary600, AppColors.primaryTeal]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(step.icon, size: 22, color: Colors.white),
              ),
              if (index < total - 1)
                Container(width: 2, height: 40, color: AppColors.gray200),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                  const SizedBox(height: 4),
                  Text(step.desc, style: const TextStyle(fontSize: 13, color: AppColors.gray500, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Features ──────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  static const _features = [
    (icon: Icons.shield_outlined, title: 'Doğrulanmış Servisler', desc: 'Her servis vergi numarası ve adres doğrulamasından geçer. Sahte işletme sıfır.'),
    (icon: Icons.balance_outlined, title: 'Rekabetçi Fiyatlar', desc: 'Tek talepte birden fazla teklif — kullanıcılarımız ortalama %30 tasarruf bildiriyor.'),
    (icon: Icons.visibility_outlined, title: 'Şeffaf Süreç', desc: 'İş güncellemeleri, kullanılan parçalar ve maliyetler anlık takip edilebilir.'),
    (icon: Icons.star_outline, title: 'Gerçek Yorumlar', desc: 'Yalnızca tamamlanmış iş sonrası yorum bırakılabilir. Sahte değerlendirme sıfır.'),
    (icon: Icons.notifications_outlined, title: 'Anlık Bildirimler', desc: 'Teklif geldiğinde, kabul edildiğinde veya soru sorulduğunda anında bildirim alırsınız.'),
    (icon: Icons.phone_android_outlined, title: 'Mobil Uyumlu', desc: 'Telefon, tablet ve bilgisayarda kusursuz çalışır. Uygulama indirmenize gerek yok.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Column(
        children: [
          const Text('ÖZELLİKLER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text('Neden Sanayi?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.gray900)),
          const SizedBox(height: 4),
          const Text('Araç sahiplerinin güvendiği platform.', style: TextStyle(fontSize: 14, color: AppColors.gray500), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: _features.map(_FeatureCard.new).toList(),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final ({IconData icon, String title, String desc}) feature;
  const _FeatureCard(this.feature);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.success50, borderRadius: BorderRadius.circular(10)),
            child: Icon(feature.icon, size: 20, color: AppColors.primary600),
          ),
          const SizedBox(height: 10),
          Text(feature.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray900)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(feature.desc, style: const TextStyle(fontSize: 11, color: AppColors.gray500, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Testimonials ──────────────────────────────────────────────────────────────

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

  static const _testimonials = [
    (init: 'AY', name: 'Ahmet Y.', role: 'Araç Sahibi', city: 'İstanbul', comment: 'Tampon değişimi için 4 farklı teklif aldım, en uygununu seçtim. Hem %25 ucuz çıktı hem çok kısa sürede hallettim.'),
    (init: 'FK', name: 'Fatma K.', role: 'Araç Sahibi', city: 'Ankara', comment: 'Motor kapotundan ses geliyordu. Fotoğraf yükledim, iki servis ek soru sordu. En detaylıyı seçtim — mükemmeldi.'),
    (init: 'MA', name: 'Mehmet A.', role: 'Servis Sahibi', city: 'Bursa', comment: 'Platforma katılmadan önce sadece çevremdeki müşterilerle çalışıyordum. Şimdi farklı illerden de iş alıyorum.'),
    (init: 'AB', name: 'Ayşe B.', role: 'Araç Sahibi', city: 'Antalya', comment: 'Fiyatı netleşince ve puanı yüksek servisi seçince çok daha rahat hissediyorum. Keşke daha önce bilseydim.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray50,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Column(
        children: [
          const Text('KULLANICI YORUMLARI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text('Gerçek Kullanıcılar, Gerçek Sonuçlar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.gray900), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ..._testimonials.map(_TestimonialCard.new),
          const SizedBox(height: 8),
          const Text('Tüm yorumlar gerçek kullanıcılardan alınmıştır.', style: TextStyle(fontSize: 11, color: AppColors.gray400), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final ({String init, String name, String role, String city, String comment}) t;
  const _TestimonialCard(this.t);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: List.generate(5, (_) => const Icon(Icons.star, size: 14, color: Color(0xFFFBBF24)))),
          const SizedBox(height: 8),
          Text('"${t.comment}"', style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.4, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary600.withValues(alpha: 0.1),
                child: Text(t.init, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary600)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                  Text('${t.role} · ${t.city}', style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── FAQ ───────────────────────────────────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  static const _faqs = [
    (q: 'Platform kullanımı ücretsiz mi?', a: 'Evet. Araç sahipleri için talep oluşturmak, teklif almak ve servis seçmek tamamen ücretsizdir. Servis sağlayıcılar için de platforma katılım ve teklif vermek ücretsizdir.'),
    (q: 'Servisler nasıl doğrulanır?', a: 'Servis sağlayıcılar kayıt olurken firma adı, vergi numarası, adres ve iletişim bilgilerini girer. Admin ekibimiz bu bilgileri inceler ve onayladıktan sonra "Doğrulanmış" rozeti verilir.'),
    (q: 'Kaç teklif alabilirim?', a: 'Tüm doğrulanmış servisler talepleri görebilir ve teklif verebilir. Ortalama 3–5 teklif alınmakta; yoğun talepli illerde bu sayı daha yükselebilmektedir.'),
    (q: 'Fotoğraf yüklemek zorunlu mu?', a: 'Hayır, zorunlu değil. Ancak fotoğraf yüklemek servislerin daha isabetli teklif vermesini sağlar. Fotoğraf yüklemenizi şiddetle tavsiye ederiz.'),
    (q: 'Teklifi kabul ettikten sonra ne oluyor?', a: 'Talep "Kabul Edildi" statüsüne geçer, servis iş güncellemeleri paylaşmaya başlar. İş tamamlandığında servis "Tamamlandı" bildirir, siz de yorum bırakabilirsiniz.'),
    (q: 'Anlaşmazlık olursa ne yapılır?', a: 'Ödeme platformumuz üzerinden gerçekleşmediği için doğrudan ödeme iadesi yapamayız. Ancak şikayetleri inceleyerek servis profillerine not ekleyebilir veya gerekli durumlarda platformdan çıkarabiliriz.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Column(
        children: [
          const Text('SSS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text('Sık Sorulan Sorular', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.gray900)),
          const SizedBox(height: 4),
          const Text('Aklınızdaki soruların cevapları burada.', style: TextStyle(fontSize: 14, color: AppColors.gray500), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ..._faqs.map((f) => _FaqItem(faq: f)),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final ({String q, String a}) faq;
  const _FaqItem({required this.faq});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _open ? AppColors.primary600.withValues(alpha: 0.4) : AppColors.gray200),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.faq.q, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _open ? AppColors.primary600 : AppColors.gray900)),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down, size: 20, color: _open ? AppColors.primary600 : AppColors.gray400),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(widget.faq.a, style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.5)),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── CTA ───────────────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  const _CtaSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary600, AppColors.primaryTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary600.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text('Hemen Başlayın', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Ücretsiz hesap oluşturun ve ilk talebinizi dakikalar içinde yayınlayın.', style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.push('/register'),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Center(
                child: Text('Ücretsiz Kayıt Ol', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary600)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/servisler'),
            child: const Text('Servislere Göz At →', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Auth Page ─────────────────────────────────────────────────────────────────

class _AuthPage extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final double bottomPadding;

  const _AuthPage({required this.onLogin, required this.onRegister, this.bottomPadding = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary600, AppColors.primaryTeal]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary600.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.build_outlined, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hemen Başlayın',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.gray900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Ücretsiz hesap oluşturun ve ilk talebinizi dakikalar içinde yayınlayın.',
            style: TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          GestureDetector(
            onTap: onRegister,
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary600, AppColors.primaryTeal]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primary600.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Center(
                child: Text('Ücretsiz Üye Ol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onLogin,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gray200),
              ),
              child: const Center(
                child: Text('Giriş Yap', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray700)),
              ),
            ),
          ),
          SizedBox(height: 8 + bottomPadding),
          const Spacer(),
        ],
      ),
    );
  }
}

// ── Diagnosis Card ────────────────────────────────────────────────────────────

class _DiagnosisCard extends StatefulWidget {
  const _DiagnosisCard();

  @override
  State<_DiagnosisCard> createState() => _DiagnosisCardState();
}

class _DiagnosisCardState extends State<_DiagnosisCard> with TickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          _buildTopBar(),
          const SizedBox(height: 12),
          _buildScanArea(),
          const SizedBox(height: 12),
          _buildServiceCards(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFDCFCE7), Color(0xFFECFDF5)]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: const Icon(Icons.memory_outlined, size: 22, color: AppColors.primary600),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Akıllı Teşhis', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.gray900)),
              Text('Araç durumu analiz ediliyor...', style: TextStyle(fontSize: 11, color: AppColors.gray500, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(34, 197, 94, _pulseCtrl.value.clamp(0.4, 1.0)),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text('CANLI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF15803D), letterSpacing: 1)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanArea() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FAFB), Color(0xFFF3F4F6)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 72, color: Colors.grey.withValues(alpha: 0.22)),
            AnimatedBuilder(
              animation: _scanCtrl,
              builder: (_, __) => Positioned(
                top: _scanCtrl.value * 130,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.primary600,
                    boxShadow: [BoxShadow(color: const Color(0xFF4ADE80).withValues(alpha: 0.8), blurRadius: 12, spreadRadius: 2)],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _bounceCtrl,
              builder: (_, __) => Positioned(
                top: 22 + _bounceCtrl.value * 5,
                left: 36,
                child: _FaultDot(color: const Color(0xFFEF4444), bg: const Color(0xFFFEE2E2), border: const Color(0xFFFECACA)),
              ),
            ),
            AnimatedBuilder(
              animation: _bounceCtrl,
              builder: (_, __) => Positioned(
                bottom: 22 + _bounceCtrl.value * 5,
                right: 44,
                child: _FaultDot(color: const Color(0xFFF59E0B), bg: const Color(0xFFFEF3C7), border: const Color(0xFFFDE68A)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCards() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray100),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 17, backgroundColor: AppColors.primary600.withValues(alpha: 0.1), child: const Text('ÖS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary600))),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Özel Örnek Servis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                    Row(
                      children: [
                        Icon(Icons.star, size: 11, color: Color(0xFFFBBF24)),
                        SizedBox(width: 3),
                        Text('4.9 (120 Yorum)', style: TextStyle(fontSize: 10, color: AppColors.gray500, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('₺2,450', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(5), border: Border.all(color: const Color(0xFFBBF7D0))),
                    child: const Text('YENİ TEKLİF', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.primary600, letterSpacing: 0.4)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: 0.55,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray100.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 17, backgroundColor: AppColors.gray200, child: const Icon(Icons.store_outlined, size: 14, color: AppColors.gray400)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Garaj İstanbul', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                      Text('Teklif Hazırlanıyor...', style: TextStyle(fontSize: 10, color: AppColors.gray400, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(height: 12, width: 48, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 5),
                    Container(height: 9, width: 34, decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FaultDot extends StatelessWidget {
  final Color color;
  final Color bg;
  final Color border;
  const _FaultDot({required this.color, required this.bg, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: border)),
      child: Center(child: Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
    );
  }
}

// ── Page Background ───────────────────────────────────────────────────────────

class _PageBackground extends StatelessWidget {
  final Color color;
  final Widget child;
  const _PageBackground({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: SizedBox.expand(child: child),
    );
  }
}
