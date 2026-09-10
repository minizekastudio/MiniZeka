import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Giris ekranindaki dairesel logo sahnesi.
///
/// Daire kucuk bir pencere gibi dusunuldu: arkada proje logosu duruyor,
/// onunde gunes doguyor, bulutlar suzuluyor, kuslar geciyor. Arada bir
/// bir ziyaretci one gelip cami tiklatiyor ve cocugu iceri cagiriyor.
///
/// Logo bir PNG oldugu icin ic parcalari ayri oynatilamiyor; butun
/// canlilik ustune cizilen `CustomPainter` katmanlarindan geliyor.
class AnimasyonluLogo extends StatefulWidget {
  final double cap;

  const AnimasyonluLogo({super.key, this.cap = 210});

  @override
  State<AnimasyonluLogo> createState() => _AnimasyonluLogoState();
}

class _AnimasyonluLogoState extends State<AnimasyonluLogo>
    with TickerProviderStateMixin {
  /// Gunesin dogusu — yalnizca bir kez.
  late final AnimationController _dogus;

  /// Donen isinlar, suzulen bulutlar, nefes alan logo, parildayan yildizlar.
  late final AnimationController _dongu;

  /// Gokyuzunden gecen kuslar.
  late final AnimationController _kus;

  /// Ziyaretci sahnesi: kelebek, ari, cami tiklatan ugur bocegi.
  late final AnimationController _sahne;

  @override
  void initState() {
    super.initState();

    _dogus = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _dongu = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _kus = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _sahne = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
  }

  @override
  void dispose() {
    _dogus.dispose();
    _dongu.dispose();
    _kus.dispose();
    _sahne.dispose();
    super.dispose();
  }

  /// Katmanlari kisaltmak icin: verilen ressami tam daireye yayar.
  Widget _katman(Listenable canlandirma, CustomPainter Function() ressam) {
    return AnimatedBuilder(
      animation: canlandirma,
      builder: (context, _) => Positioned.fill(
        child: CustomPaint(painter: ressam()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cap = widget.cap;

    return SizedBox(
      width: cap,
      height: cap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF47E15E).withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 6,
              offset: const Offset(0, 11),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ---- GÖKYÜZÜ (logo yüklenene kadarki zemin) ----
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF7FD0FF), Color(0xFFD9F3FF)],
                  ),
                ),
              ),

              // ---- LOGO ----
              //
              // Cizim bozulmasin diye kirpilmiyor; yalnizca nefes aliyor.
              AnimatedBuilder(
                animation: _dongu,
                builder: (context, child) {
                  final salinim = math.sin(_dongu.value * 2 * math.pi) * 3;

                  return Transform.translate(
                    offset: Offset(0, salinim),
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/splash/splash_logo.png',
                  fit: BoxFit.cover,
                ),
              ),

              _katman(_dongu, () => _BulutRessam(ilerleme: _dongu.value)),

              _katman(
                Listenable.merge([_dogus, _dongu]),
                () => _GunesRessam(
                  dogus: Curves.easeOutBack.transform(
                    _dogus.value.clamp(0.0, 1.0),
                  ),
                  aci: _dongu.value * 2 * math.pi,
                ),
              ),

              _katman(_kus, () => _KusRessam(ilerleme: _kus.value)),

              // ---- ZİYARETÇİLER ----
              _katman(_sahne, () => _ZiyaretciRessam(zaman: _sahne.value)),

              // ---- CAM PARLAMASI ----
              // Daireyi pencere gibi gosterir; tiklatma jesti bu sayede
              // "cama vuruyor" gibi okunuyor.
              const Positioned.fill(
                child: CustomPaint(painter: _CamRessam()),
              ),

              _katman(_dongu, () => _YildizRessam(ilerleme: _dongu.value)),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// ORTAK YARDIMCI
// =============================================================

/// Emojiyi tuvale ortalayarak cizer.
///
/// Renkli emoji fontu boyanamadigi icin saydamlik ayri bir katmanla
/// (saveLayer) uygulanir.
void _emojiCiz(
  Canvas canvas,
  String emoji,
  Offset merkez,
  double boy, {
  double aci = 0,
  double opaklik = 1,
  bool aynala = false,
}) {
  if (opaklik <= 0.01) return;

  final yazi = TextPainter(
    text: TextSpan(text: emoji, style: TextStyle(fontSize: boy)),
    textDirection: TextDirection.ltr,
  )..layout();

  canvas.save();
  canvas.translate(merkez.dx, merkez.dy);

  if (aci != 0) canvas.rotate(aci);
  if (aynala) canvas.scale(-1, 1);

  final saydam = opaklik < 0.99;

  if (saydam) {
    canvas.saveLayer(
      Rect.fromCenter(
        center: Offset.zero,
        width: yazi.width * 2,
        height: yazi.height * 2,
      ),
      Paint()..color = Colors.white.withValues(alpha: opaklik),
    );
  }

  yazi.paint(canvas, Offset(-yazi.width / 2, -yazi.height / 2));

  if (saydam) canvas.restore();

  canvas.restore();
}

/// Zaman `bas`–`son` araliginda mi? Ise 0..1 yerel ilerleme dondurur.
double? _pencere(double zaman, double bas, double son) {
  if (zaman < bas || zaman > son) return null;
  return (zaman - bas) / (son - bas);
}

// =============================================================
// ZİYARETÇİLER
// =============================================================

class _ZiyaretciRessam extends CustomPainter {
  /// 26 saniyelik sahnenin 0..1 arasindaki yeri.
  final double zaman;

  _ZiyaretciRessam({required this.zaman});

  @override
  void paint(Canvas canvas, Size size) {
    _salyangoz(canvas, size);
    _kelebek(canvas, size);
    _ari(canvas, size);
    _camdakiZiyaretci(canvas, size);
  }

  /// Dipteki cimende agir agir ilerleyen salyangoz.
  ///
  /// Digerlerinden cok daha yavas: sahneye sakin bir ritim katiyor.
  void _salyangoz(Canvas canvas, Size size) {
    final t = _pencere(zaman, 0.05, 0.58);
    if (t == null) return;

    final x = -0.10 + 1.20 * t;

    // Kabugu hafifce sallanarak yurur.
    final sallanma = math.sin(t * math.pi * 26) * 0.05;

    _emojiCiz(
      canvas,
      '🐌',
      Offset(size.width * x, size.height * 0.88),
      size.width * 0.085,
      aci: sallanma,
      opaklik: _girisCikis(t),
    );
  }

  /// Soldan girip saga suzulen kelebek — yukari asagi dalgalanir.
  void _kelebek(Canvas canvas, Size size) {
    final t = _pencere(zaman, 0.03, 0.26);
    if (t == null) return;

    final x = -0.16 + 1.32 * t;
    final y = 0.60 + 0.13 * math.sin(t * math.pi * 3);

    // Kanat cirpisi egimle taklit ediliyor.
    final egim = math.sin(t * math.pi * 16) * 0.28;

    _emojiCiz(
      canvas,
      '🦋',
      Offset(size.width * x, size.height * y),
      size.width * 0.115,
      aci: egim,
      opaklik: _girisCikis(t),
    );
  }

  /// Sagdan gelip zikzak cizerek geri donen ari.
  void _ari(Canvas canvas, Size size) {
    final t = _pencere(zaman, 0.32, 0.52);
    if (t == null) return;

    final x = 1.14 - 1.30 * t;
    final y = 0.32 + 0.12 * math.sin(t * math.pi * 4);

    _emojiCiz(
      canvas,
      '🐝',
      Offset(size.width * x, size.height * y),
      size.width * 0.10,
      aci: math.sin(t * math.pi * 4) * 0.22,
      aynala: true,
      opaklik: _girisCikis(t),
    );
  }

  /// Öne gelip cami tiklatan ve iceri cagiran sincap.
  ///
  /// Logoda zaten bir ugur bocegi var; ziyaretci farkli bir hayvan
  /// olsun diye sincap secildi.
  ///
  /// Bolumler: gelis → iki tiklatma → cagirma → gidis.
  void _camdakiZiyaretci(Canvas canvas, Size size) {
    final t = _pencere(zaman, 0.58, 0.98);
    if (t == null) return;

    const camMerkez = Offset(0.50, 0.52);

    double x, y, boyut, egim;
    double opaklik = 1;

    if (t < 0.22) {
      // Sag alttan one dogru ucar, yaklastikca buyur.
      final g = t / 0.22;
      final yumusak = Curves.easeOutCubic.transform(g);

      x = 1.18 + (camMerkez.dx - 1.18) * yumusak;
      y = 1.05 + (camMerkez.dy - 1.05) * yumusak;
      boyut = 0.09 + 0.10 * yumusak;
      egim = -0.35 * (1 - yumusak);
      opaklik = g.clamp(0.0, 1.0);
    } else if (t < 0.46) {
      // İki kez cama vurur: her vurusta hafifce one atilir.
      final g = (t - 0.22) / 0.24;

      x = camMerkez.dx;
      y = camMerkez.dy;
      boyut = 0.19 + 0.022 * _vurusIvmesi(g);
      egim = 0.05 * math.sin(g * math.pi * 6);
    } else if (t < 0.72) {
      // "Gel!" — saga sola egilerek cagirir.
      final g = (t - 0.46) / 0.26;

      x = camMerkez.dx + 0.045 * math.sin(g * math.pi * 4);
      y = camMerkez.dy - 0.02 * math.sin(g * math.pi * 2);
      boyut = 0.19 + 0.012 * math.sin(g * math.pi * 4);
      egim = 0.30 * math.sin(g * math.pi * 4);
    } else {
      // Geldigi yerden geri doner.
      final g = (t - 0.72) / 0.28;
      final yumusak = Curves.easeInCubic.transform(g);

      x = camMerkez.dx + (1.18 - camMerkez.dx) * yumusak;
      y = camMerkez.dy + (1.05 - camMerkez.dy) * yumusak;
      boyut = 0.19 - 0.10 * yumusak;
      egim = 0.35 * yumusak;
      opaklik = (1 - g).clamp(0.0, 1.0);
    }

    // Vurus halkalari: cama dokundugu iki anda yayilir.
    for (final vurus in const [0.27, 0.37]) {
      final h = _pencere(t, vurus, vurus + 0.11);
      if (h == null) continue;

      canvas.drawCircle(
        Offset(size.width * camMerkez.dx, size.height * camMerkez.dy),
        size.width * (0.06 + 0.16 * h),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * (1 - h)
          ..color = Colors.white.withValues(alpha: 0.75 * (1 - h)),
      );
    }

    _emojiCiz(
      canvas,
      '🐿️',
      Offset(size.width * x, size.height * y),
      size.width * boyut,
      aci: egim,
      opaklik: opaklik,
    );
  }

  /// Kenarlarda yumusak belirme/kaybolma.
  double _girisCikis(double t) {
    if (t < 0.12) return t / 0.12;
    if (t > 0.88) return (1 - t) / 0.12;
    return 1;
  }

  /// İki vurusun one atilma egrisi (0..1 arasi iki tepe).
  double _vurusIvmesi(double g) {
    double tepe(double merkez) {
      final d = (g - merkez).abs();
      return d > 0.09 ? 0 : math.cos(d / 0.09 * math.pi / 2);
    }

    return math.max(tepe(0.22), tepe(0.62));
  }

  @override
  bool shouldRepaint(_ZiyaretciRessam eski) => eski.zaman != zaman;
}

// =============================================================
// CAM PARLAMASI
// =============================================================

class _CamRessam extends CustomPainter {
  const _CamRessam();

  @override
  void paint(Canvas canvas, Size size) {
    // Sol ustten sag alta inen ince isik seridi.
    final yol = Path()
      ..moveTo(size.width * 0.04, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.06,
        size.width * 0.62,
        size.height * 0.02,
      )
      ..lineTo(size.width * 0.40, size.height * 0.03)
      ..quadraticBezierTo(
        size.width * 0.12,
        size.height * 0.20,
        size.width * 0.04,
        size.height * 0.52,
      )
      ..close();

    canvas.drawPath(
      yol,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // Cam kenari
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.41,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_CamRessam eski) => false;
}

// =============================================================
// GÜNEŞ
// =============================================================

class _GunesRessam extends CustomPainter {
  /// 0 = henuz dogmamis, 1 = tam dogmus.
  final double dogus;

  /// Isinlarin donme acisi.
  final double aci;

  _GunesRessam({required this.dogus, required this.aci});

  @override
  void paint(Canvas canvas, Size size) {
    // Logodaki cizili gunesin tam uzerine denk gelir.
    const konum = Offset(0.805, 0.175);

    final merkez = Offset(size.width * konum.dx, size.height * konum.dy);
    final yaricap = size.width * 0.072;

    // Hale
    canvas.drawCircle(
      merkez,
      yaricap * 2.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE07A).withValues(alpha: 0.55 * dogus),
            const Color(0xFFFFE07A).withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: merkez, radius: yaricap * 2.6),
        ),
    );

    // Isinlar
    final isinBoya = Paint()
      ..color = const Color(0xFFFFD53D).withValues(alpha: dogus)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 8; i++) {
      final a = aci + i * math.pi / 4;
      final ic = yaricap * 1.35;
      final dis = ic + yaricap * 0.75 * dogus;

      canvas.drawLine(
        merkez + Offset(math.cos(a), math.sin(a)) * ic,
        merkez + Offset(math.cos(a), math.sin(a)) * dis,
        isinBoya,
      );
    }

    // Cizili gunesi bastirmadan uzerine sicak bir parlaklik.
    canvas.drawCircle(
      merkez,
      yaricap * 0.92,
      Paint()..color = const Color(0xFFFFF0A8).withValues(alpha: 0.55 * dogus),
    );
  }

  @override
  bool shouldRepaint(_GunesRessam eski) =>
      eski.dogus != dogus || eski.aci != aci;
}

// =============================================================
// BULUTLAR
// =============================================================

class _BulutRessam extends CustomPainter {
  final double ilerleme;

  _BulutRessam({required this.ilerleme});

  @override
  void paint(Canvas canvas, Size size) {
    final boya = Paint()..color = Colors.white.withValues(alpha: 0.72);

    void bulut(double x, double y, double olcek) {
      final kayma = ((x + ilerleme) % 1.4) - 0.2;
      final merkez = Offset(size.width * kayma, size.height * y);
      final r = size.width * 0.05 * olcek;

      canvas.drawCircle(merkez, r, boya);
      canvas.drawCircle(merkez + Offset(r * 0.9, r * 0.2), r * 0.78, boya);
      canvas.drawCircle(merkez + Offset(-r * 0.85, r * 0.25), r * 0.7, boya);
    }

    bulut(0.10, 0.13, 0.85);
    bulut(0.62, 0.22, 0.6);
  }

  @override
  bool shouldRepaint(_BulutRessam eski) => eski.ilerleme != ilerleme;
}

// =============================================================
// KUŞLAR
// =============================================================

class _KusRessam extends CustomPainter {
  final double ilerleme;

  _KusRessam({required this.ilerleme});

  @override
  void paint(Canvas canvas, Size size) {
    _kus(canvas, size, ilerleme, 0.30, 1.0);
    // İkinci kus biraz gecikmeli ve daha kucuk: derinlik hissi verir.
    _kus(canvas, size, (ilerleme + 0.18) % 1.0, 0.20, 0.72);
  }

  void _kus(
    Canvas canvas,
    Size size,
    double ilerleme,
    double yukseklik,
    double olcek,
  ) {
    // Kus dongunun ilk yarisinda gorunur, sonra dinlenir.
    if (ilerleme > 0.5) return;

    final t = ilerleme / 0.5;

    final x = size.width * (-0.12 + 1.26 * t);
    final y = size.height * (yukseklik - 0.09 * math.sin(t * math.pi));

    final cirpi = math.sin(t * math.pi * 14).abs();
    final kanat = size.width * 0.030 * olcek * (0.55 + 0.45 * cirpi);
    final genislik = size.width * 0.042 * olcek;

    final boya = Paint()
      ..color = const Color(0xFF3C4A55).withValues(alpha: 0.85 * olcek)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * olcek
      ..strokeCap = StrokeCap.round;

    final yol = Path()
      ..moveTo(x - genislik, y)
      ..quadraticBezierTo(x - genislik * 0.5, y - kanat, x, y)
      ..quadraticBezierTo(x + genislik * 0.5, y - kanat, x + genislik, y);

    canvas.drawPath(yol, boya);
  }

  @override
  bool shouldRepaint(_KusRessam eski) => eski.ilerleme != ilerleme;
}

// =============================================================
// YILDIZLAR
// =============================================================

class _YildizRessam extends CustomPainter {
  final double ilerleme;

  _YildizRessam({required this.ilerleme});

  @override
  void paint(Canvas canvas, Size size) {
    void yildiz(double x, double y, double r, double faz) {
      final parlaklik = 0.35 +
          0.65 * (0.5 + 0.5 * math.sin((ilerleme + faz) * 2 * math.pi * 3));

      final boya = Paint()
        ..color = Colors.white.withValues(alpha: parlaklik)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      final merkez = Offset(size.width * x, size.height * y);

      canvas.drawLine(merkez - Offset(r, 0), merkez + Offset(r, 0), boya);
      canvas.drawLine(merkez - Offset(0, r), merkez + Offset(0, r), boya);
    }

    yildiz(0.24, 0.16, 5, 0.0);
    yildiz(0.84, 0.62, 4, 0.35);
    yildiz(0.16, 0.72, 3.5, 0.7);
  }

  @override
  bool shouldRepaint(_YildizRessam eski) => eski.ilerleme != ilerleme;
}
