import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The circular logo scene on the welcome screen.
///
/// Daire kucuk bir pencere gibi dusunuldu: arkada proje logosu duruyor,
/// onunde sun doguyor, bulutlar suzuluyor, kuslar geciyor. Arada bir
/// bir ziyaretci one gelip cami tiklatiyor ve cocugu iceri cagiriyor.
///
/// Logo bir PNG oldugu icin inner parcalari ayri oynatilamiyor; butun
/// canlilik ustune cizilen `CustomPainter` katmanlarindan geliyor.
class AnimatedLogo extends StatefulWidget {
  final double diameter;

  const AnimatedLogo({super.key, this.diameter = 210});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  /// Sunrise — plays once.
  late final AnimationController _sunrise;

  /// Turning rays, drifting clouds, the breathing logo, twinkling sparkles.
  late final AnimationController _ambient;

  /// Birds crossing the sky.
  late final AnimationController _bird;

  /// The visitor scene: butterfly, bee, and the squirrel that taps the glass.
  late final AnimationController _visitors;

  @override
  void initState() {
    super.initState();

    _sunrise = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _bird = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _visitors = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
  }

  @override
  void dispose() {
    _sunrise.dispose();
    _ambient.dispose();
    _bird.dispose();
    _visitors.dispose();
    super.dispose();
  }

  /// Stretches the given painter across the whole circle.
  Widget _layer(Listenable canlandirma, CustomPainter Function() ressam) {
    return AnimatedBuilder(
      animation: canlandirma,
      builder: (context, _) => Positioned.fill(
        child: CustomPaint(painter: ressam()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diameter = widget.diameter;

    return SizedBox(
      width: diameter,
      height: diameter,
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
                animation: _ambient,
                builder: (context, child) {
                  final drift = math.sin(_ambient.value * 2 * math.pi) * 3;

                  return Transform.translate(
                    offset: Offset(0, drift),
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/splash/splash_logo.png',
                  fit: BoxFit.cover,
                  // Kaynak 1152x1152; daire en fazla ~diameter*3 fiziksel piksel
                  // kaplar. Tam boyutta cozulurse ilk ekranda ~5 MB bellek
                  // tutuyordu.
                  cacheWidth: (diameter * 3).round(),
                ),
              ),

              _layer(_ambient, () => _CloudPainter(progress: _ambient.value)),

              _layer(
                Listenable.merge([_sunrise, _ambient]),
                () => _SunPainter(
                  rise: Curves.easeOutBack.transform(
                    _sunrise.value.clamp(0.0, 1.0),
                  ),
                  angle: _ambient.value * 2 * math.pi,
                ),
              ),

              _layer(_bird, () => _BirdPainter(progress: _bird.value)),

              // ---- ZİYARETÇİLER ----
              _layer(_visitors, () => _VisitorPainter(time: _visitors.value)),

              // ---- CAM PARLAMASI ----
              // Daireyi pencere gibi gosterir; tiklatma jesti bu sayede
              // "cama vuruyor" gibi okunuyor.
              const Positioned.fill(
                child: CustomPaint(painter: _GlassPainter()),
              ),

              _layer(_ambient, () => _SparklePainter(progress: _ambient.value)),
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

/// Draws an emoji centred on the given point.
///
/// A colour emoji font cannot be tinted, so opacity is applied through a
/// separate layer (saveLayer).
void _drawEmoji(
  Canvas canvas,
  String emoji,
  Offset center,
  double boy, {
  double angle = 0,
  double opacity = 1,
  bool mirror = false,
}) {
  if (opacity <= 0.01) return;

  final textPainter = TextPainter(
    text: TextSpan(text: emoji, style: TextStyle(fontSize: boy)),
    textDirection: TextDirection.ltr,
  )..layout();

  canvas.save();
  canvas.translate(center.dx, center.dy);

  if (angle != 0) canvas.rotate(angle);
  if (mirror) canvas.scale(-1, 1);

  final translucent = opacity < 0.99;

  if (translucent) {
    canvas.saveLayer(
      Rect.fromCenter(
        center: Offset.zero,
        width: textPainter.width * 2,
        height: textPainter.height * 2,
      ),
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
  }

  textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

  if (translucent) canvas.restore();

  canvas.restore();
}

/// Zaman `bas`–`son` araliginda mi? Ise 0..1 yerel progress dondurur.
double? _window(double time, double bas, double son) {
  if (time < bas || time > son) return null;
  return (time - bas) / (son - bas);
}

// =============================================================
// ZİYARETÇİLER
// =============================================================

class _VisitorPainter extends CustomPainter {
  /// Position within the 26 second scene, 0..1.
  final double time;

  _VisitorPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    _snail(canvas, size);
    _butterfly(canvas, size);
    _bee(canvas, size);
    _windowVisitor(canvas, size);
  }

  /// A snail crawling slowly along the grass at the bottom.
  ///
  /// Much slower than the others: it gives the scene a calm pulse.
  void _snail(Canvas canvas, Size size) {
    final t = _window(time, 0.05, 0.58);
    if (t == null) return;

    final x = -0.10 + 1.20 * t;

    // Kabugu hafifce sallanarak yurur.
    final sway = math.sin(t * math.pi * 26) * 0.05;

    _drawEmoji(
      canvas,
      '🐌',
      Offset(size.width * x, size.height * 0.88),
      size.width * 0.085,
      angle: sway,
      opacity: _fadeInOut(t),
    );
  }

  /// A butterfly drifting left to right, bobbing as it goes.
  void _butterfly(Canvas canvas, Size size) {
    final t = _window(time, 0.03, 0.26);
    if (t == null) return;

    final x = -0.16 + 1.32 * t;
    final y = 0.60 + 0.13 * math.sin(t * math.pi * 3);

    // Kanat cirpisi egimle taklit ediliyor.
    final tilt = math.sin(t * math.pi * 16) * 0.28;

    _drawEmoji(
      canvas,
      '🦋',
      Offset(size.width * x, size.height * y),
      size.width * 0.115,
      angle: tilt,
      opacity: _fadeInOut(t),
    );
  }

  /// A bee entering from the right, zig-zagging back out.
  void _bee(Canvas canvas, Size size) {
    final t = _window(time, 0.32, 0.52);
    if (t == null) return;

    final x = 1.14 - 1.30 * t;
    final y = 0.32 + 0.12 * math.sin(t * math.pi * 4);

    _drawEmoji(
      canvas,
      '🐝',
      Offset(size.width * x, size.height * y),
      size.width * 0.10,
      angle: math.sin(t * math.pi * 4) * 0.22,
      mirror: true,
      opacity: _fadeInOut(t),
    );
  }

  /// The squirrel that comes forward, taps the glass and beckons.
  ///
  /// The logo already contains a ladybug, so a different animal was chosen
  /// for the visitor.
  ///
  /// Bolumler: gelis → iki tiklatma → cagirma → gidis.
  void _windowVisitor(Canvas canvas, Size size) {
    final t = _window(time, 0.58, 0.98);
    if (t == null) return;

    const windowCenter = Offset(0.50, 0.52);

    double x, y, boyut, tilt;
    double opacity = 1;

    if (t < 0.22) {
      // Sag alttan one dogru ucar, yaklastikca buyur.
      final g = t / 0.22;
      final yumusak = Curves.easeOutCubic.transform(g);

      x = 1.18 + (windowCenter.dx - 1.18) * yumusak;
      y = 1.05 + (windowCenter.dy - 1.05) * yumusak;
      boyut = 0.09 + 0.10 * yumusak;
      tilt = -0.35 * (1 - yumusak);
      opacity = g.clamp(0.0, 1.0);
    } else if (t < 0.46) {
      // İki kez cama vurur: her vurusta hafifce one atilir.
      final g = (t - 0.22) / 0.24;

      x = windowCenter.dx;
      y = windowCenter.dy;
      boyut = 0.19 + 0.022 * _tapImpulse(g);
      tilt = 0.05 * math.sin(g * math.pi * 6);
    } else if (t < 0.72) {
      // "Gel!" — saga sola egilerek cagirir.
      final g = (t - 0.46) / 0.26;

      x = windowCenter.dx + 0.045 * math.sin(g * math.pi * 4);
      y = windowCenter.dy - 0.02 * math.sin(g * math.pi * 2);
      boyut = 0.19 + 0.012 * math.sin(g * math.pi * 4);
      tilt = 0.30 * math.sin(g * math.pi * 4);
    } else {
      // Geldigi yerden geri doner.
      final g = (t - 0.72) / 0.28;
      final yumusak = Curves.easeInCubic.transform(g);

      x = windowCenter.dx + (1.18 - windowCenter.dx) * yumusak;
      y = windowCenter.dy + (1.05 - windowCenter.dy) * yumusak;
      boyut = 0.19 - 0.10 * yumusak;
      tilt = 0.35 * yumusak;
      opacity = (1 - g).clamp(0.0, 1.0);
    }

    // Vurus halkalari: cama dokundugu iki anda yayilir.
    for (final tap in const [0.27, 0.37]) {
      final h = _window(t, tap, tap + 0.11);
      if (h == null) continue;

      canvas.drawCircle(
        Offset(size.width * windowCenter.dx, size.height * windowCenter.dy),
        size.width * (0.06 + 0.16 * h),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * (1 - h)
          ..color = Colors.white.withValues(alpha: 0.75 * (1 - h)),
      );
    }

    _drawEmoji(
      canvas,
      '🐿️',
      Offset(size.width * x, size.height * y),
      size.width * boyut,
      angle: tilt,
      opacity: opacity,
    );
  }

  /// Soft fade in and out at the edges.
  double _fadeInOut(double t) {
    if (t < 0.12) return t / 0.12;
    if (t > 0.88) return (1 - t) / 0.12;
    return 1;
  }

  /// İki vurusun one atilma egrisi (0..1 arasi iki peak).
  double _tapImpulse(double g) {
    double peak(double center) {
      final d = (g - center).abs();
      return d > 0.09 ? 0 : math.cos(d / 0.09 * math.pi / 2);
    }

    return math.max(peak(0.22), peak(0.62));
  }

  @override
  bool shouldRepaint(_VisitorPainter old) => old.time != time;
}

// =============================================================
// CAM PARLAMASI
// =============================================================

class _GlassPainter extends CustomPainter {
  const _GlassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Sol ustten sag alta inen ince isik seridi.
    final path = Path()
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
      path,
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
  bool shouldRepaint(_GlassPainter old) => false;
}

// =============================================================
// GÜNEŞ
// =============================================================

class _SunPainter extends CustomPainter {
  /// 0 = below the horizon, 1 = fully risen.
  final double rise;

  /// Rotation angle of the rays.
  final double angle;

  _SunPainter({required this.rise, required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    // Logodaki cizili gunesin tam uzerine denk gelir.
    const konum = Offset(0.805, 0.175);

    final center = Offset(size.width * konum.dx, size.height * konum.dy);
    final radius = size.width * 0.072;

    // Hale
    canvas.drawCircle(
      center,
      radius * 2.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE07A).withValues(alpha: 0.55 * rise),
            const Color(0xFFFFE07A).withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius * 2.6),
        ),
    );

    // Isinlar
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD53D).withValues(alpha: rise)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 8; i++) {
      final a = angle + i * math.pi / 4;
      final inner = radius * 1.35;
      final outer = inner + radius * 0.75 * rise;

      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * inner,
        center + Offset(math.cos(a), math.sin(a)) * outer,
        rayPaint,
      );
    }

    // Cizili gunesi bastirmadan uzerine sicak bir brightness.
    canvas.drawCircle(
      center,
      radius * 0.92,
      Paint()..color = const Color(0xFFFFF0A8).withValues(alpha: 0.55 * rise),
    );
  }

  @override
  bool shouldRepaint(_SunPainter old) =>
      old.rise != rise || old.angle != angle;
}

// =============================================================
// BULUTLAR
// =============================================================

class _CloudPainter extends CustomPainter {
  final double progress;

  _CloudPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.72);

    void cloud(double x, double y, double scale) {
      final shift = ((x + progress) % 1.4) - 0.2;
      final center = Offset(size.width * shift, size.height * y);
      final r = size.width * 0.05 * scale;

      canvas.drawCircle(center, r, paint);
      canvas.drawCircle(center + Offset(r * 0.9, r * 0.2), r * 0.78, paint);
      canvas.drawCircle(center + Offset(-r * 0.85, r * 0.25), r * 0.7, paint);
    }

    cloud(0.10, 0.13, 0.85);
    cloud(0.62, 0.22, 0.6);
  }

  @override
  bool shouldRepaint(_CloudPainter old) => old.progress != progress;
}

// =============================================================
// KUŞLAR
// =============================================================

class _BirdPainter extends CustomPainter {
  final double progress;

  _BirdPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    _bird(canvas, size, progress, 0.30, 1.0);
    // İkinci kus biraz gecikmeli ve daha kucuk: derinlik hissi verir.
    _bird(canvas, size, (progress + 0.18) % 1.0, 0.20, 0.72);
  }

  void _bird(
    Canvas canvas,
    Size size,
    double progress,
    double height,
    double scale,
  ) {
    // Kus dongunun ilk yarisinda gorunur, sonra dinlenir.
    if (progress > 0.5) return;

    final t = progress / 0.5;

    final x = size.width * (-0.12 + 1.26 * t);
    final y = size.height * (height - 0.09 * math.sin(t * math.pi));

    final flap = math.sin(t * math.pi * 14).abs();
    final wing = size.width * 0.030 * scale * (0.55 + 0.45 * flap);
    final span = size.width * 0.042 * scale;

    final paint = Paint()
      ..color = const Color(0xFF3C4A55).withValues(alpha: 0.85 * scale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * scale
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(x - span, y)
      ..quadraticBezierTo(x - span * 0.5, y - wing, x, y)
      ..quadraticBezierTo(x + span * 0.5, y - wing, x + span, y);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BirdPainter old) => old.progress != progress;
}

// =============================================================
// YILDIZLAR
// =============================================================

class _SparklePainter extends CustomPainter {
  final double progress;

  _SparklePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    void sparkle(double x, double y, double r, double phase) {
      final brightness = 0.35 +
          0.65 * (0.5 + 0.5 * math.sin((progress + phase) * 2 * math.pi * 3));

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: brightness)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      final center = Offset(size.width * x, size.height * y);

      canvas.drawLine(center - Offset(r, 0), center + Offset(r, 0), paint);
      canvas.drawLine(center - Offset(0, r), center + Offset(0, r), paint);
    }

    sparkle(0.24, 0.16, 5, 0.0);
    sparkle(0.84, 0.62, 4, 0.35);
    sparkle(0.16, 0.72, 3.5, 0.7);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.progress != progress;
}
