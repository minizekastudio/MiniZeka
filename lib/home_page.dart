import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'settings_page.dart';
import 'avatar_manager.dart';
import 'avatar_selection_page.dart';
import 'word_game.dart';
import 'letter_game.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onAchievementsTap;

  final VoidCallback onMemoryTap;
  final VoidCallback onAttentionTap;
  final VoidCallback onMathTap;
  final VoidCallback onShapeTap;
  final VoidCallback onLogicTap;

  const HomePage({
    super.key,
    required this.onAchievementsTap,
    required this.onMemoryTap,
    required this.onAttentionTap,
    required this.onMathTap,
    required this.onShapeTap,
    required this.onLogicTap,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _titleAnimation;
  late Animation<double> _infoAnimation;

  late Animation<double> _game1Animation;
  late Animation<double> _game2Animation;
  late Animation<double> _game3Animation;
  late Animation<double> _game4Animation;
  late Animation<double> _game5Animation;
  late Animation<double> _game6Animation;
  late Animation<double> _game7Animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _titleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.25,
        curve: Curves.easeOutCubic,
      ),
    );


    _infoAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.25,
        0.48,
        curve: Curves.easeOutCubic,
      ),
    );

    _game1Animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.35,
        0.57,
        curve: Curves.easeOutCubic,
      ),
    );

    _game2Animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.42,
        0.64,
        curve: Curves.easeOutCubic,
      ),
    );

    _game3Animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.49,
        0.71,
        curve: Curves.easeOutCubic,
      ),
    );

    _game4Animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.56,
        0.78,
        curve: Curves.easeOutCubic,
      ),
    );

    _game5Animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.63,
        0.85,
        curve: Curves.easeOutCubic,
      ),
    );
    _game6Animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.70,
        0.92,
        curve: Curves.easeOutCubic,
      ),
    );

    _game7Animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.76,
        0.98,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();

    _loadAvatar();
  }
  Future<void> _loadAvatar() async {
    await AvatarManager.loadAvatar();

    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animatedSection({
    required Animation<double> animation,
    required Widget child,
    double slideBegin = 0.18,
  }) {
    final slide = Tween<Offset>(
      begin: Offset(0, slideBegin),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // =====================================================
          // ARKA PLAN DEKORASYONLARI
          // =====================================================

          Positioned(
            top: -75,
            left: -55,
            child: Container(
              width: 165,
              height: 165,
              decoration: BoxDecoration(
                color: const Color(0xFFD3FFD7).withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            top: -55,
            right: -50,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                color: const Color(0xFFDFFFE2).withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 185,
              height: 185,
              decoration: BoxDecoration(
                color: const Color(0xFFDDF3FF).withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -70,
            right: -55,
            child: Container(
              width: 175,
              height: 175,
              decoration: BoxDecoration(
                color: const Color(0xFFD0FFD5).withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Küçük dekoratif parıltılar
          const Positioned(
            top: 100,
            left: 55,
            child: _Sparkle(
              size: 16,
              color: Colors.white,
            ),
          ),

          const Positioned(
            top: 165,
            right: 55,
            child: _Sparkle(
              size: 13,
              color: Colors.white,
            ),
          ),

          const Positioned(
            top: 305,
            right: 25,
            child: _Sparkle(
              size: 15,
              color: Color(0xFFB5FFBC),
            ),
          ),

          // =====================================================
          // ANA İÇERİK
          // =====================================================

          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                30,
              ),
              children: [
                // =================================================
                // SADE ÜST BAR
                // =================================================

                _animatedSection(
                  animation: _titleAnimation,
                  slideBegin: 0.08,
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      // SADE GERİ OKU
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.72),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 17,
                            color: Color(0xFF21823B),
                          ),
                        ),
                      ),

                      // AYARLAR + BAŞARILAR
                      Row(
                        children: [
                          // AYARLAR
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsPage(),
                                ),
                              );
                            },
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.90),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 9,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.settings_rounded,
                                color: Color(0xFF23D83E),
                                size: 21,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // BAŞARILAR
                          GestureDetector(
                            onTap: widget.onAchievementsTap,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.90),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 9,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '🏆',
                                  style: TextStyle(
                                    fontSize: 21,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // =================================================
// TEK MİNİZEKA BAŞLIĞI + AVATAR
// =================================================

                _animatedSection(
                  animation: _titleAnimation,
                  slideBegin: 0.12,
                  child: Row(
                    children: [
                      // MİNİZEKA İKONU
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFD8FFDC),
                              Color(0xFFDDF5FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(19),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5FE573).withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '🧠',
                            style: TextStyle(fontSize: 31),
                          ),
                        ),
                      ),

                      const SizedBox(width: 13),

                      // BAŞLIK
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Zeka Bahçesi',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: Color(0xFF259242),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Oyna • Öğren • Keşfet! ✨',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF30DD4A),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // SEÇİLEN AVATAR
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AvatarSelectionPage(),
                            ),
                          ).then((_) async {
                            await AvatarManager.loadAvatar();

                            if (!mounted) return;

                            setState(() {});
                          });
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFD8FFDC),
                                Color(0xFFDDF5FF),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF23D83E).withValues(alpha: 0.14),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              AvatarManager.selectedAvatar,
                              style: const TextStyle(
                                fontSize: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // =================================================
                // OYUNLAR BAŞLIĞI
                // =================================================

                _animatedSection(
                  animation: _infoAnimation,
                  slideBegin: 0.10,
                  child: const Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '🎮',
                            style:
                            TextStyle(fontSize: 24),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Bir oyun seç!',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E7936),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 15),
                    ],
                  ),
                ),

                // =================================================
                // HAFIZA
                // =================================================

                // ÖRNEK: yeni kare kart tasarimi (2 sutun, yazi yok,
                // zorluk yildizla, kartin tamami tiklanabilir)
                Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _animatedSection(
                          animation: _game1Animation,
                          child: OyunKartiKare(
                            emoji: '🧠',
                            baslik: 'Hafıza',
                            yildiz: 1,
                            renk: Marka.oyunHafiza,
                            onTap: widget.onMemoryTap,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: _animatedSection(
                          animation: _game2Animation,
                          child: OyunKartiKare(
                            emoji: '👀',
                            baslik: 'Dikkat',
                            yildiz: 2,
                            renk: Marka.oyunDikkat,
                            onTap: widget.onAttentionTap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // =================================================
                // MATEMATİK  ·  EŞLEŞTİRME
                // =================================================

                Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _animatedSection(
                          animation: _game3Animation,
                          child: OyunKartiKare(
                            emoji: '🔢',
                            baslik: 'Matematik',
                            yildiz: 2,
                            renk: Marka.oyunMatematik,
                            onTap: widget.onMathTap,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: _animatedSection(
                          animation: _game4Animation,
                          child: OyunKartiKare(
                            emoji: '🔷',
                            baslik: 'Eşleştirme',
                            yildiz: 1,
                            renk: Marka.oyunEslestirme,
                            onTap: widget.onShapeTap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // =================================================
                // MANTIK  ·  KELİME AVI
                // =================================================

                Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _animatedSection(
                          animation: _game5Animation,
                          child: OyunKartiKare(
                            emoji: '🧩',
                            baslik: 'Mantık',
                            yildiz: 3,
                            renk: Marka.oyunMantik,
                            onTap: widget.onLogicTap,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: _animatedSection(
                          animation: _game6Animation,
                          slideBegin: 0.10,
                          child: OyunKartiKare(
                            emoji: '🔎',
                            baslik: 'Kelime Avı',
                            yildiz: 2,
                            renk: Marka.oyunKelimeAvi,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WordGame(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // =================================================
                // HARFLER  (tek kalan — yarim genislik)
                // =================================================

                Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _animatedSection(
                          animation: _game7Animation,
                          slideBegin: 0.10,
                          child: OyunKartiKare(
                            emoji: '🔤',
                            baslik: 'Harfler',
                            yildiz: 1,
                            renk: Marka.oyunHarf,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LetterGame(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      // Yedinci oyun tek kaldi; sag hucre bos birakiliyor.
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// YENİ KARE OYUN KARTI  (örnek tasarım)
// =============================================================
//
// CLAUDE.md "ekran sadeleştirmesi" 1. maddesi:
// 2 sutunlu buyuk kare kart, sadece ikon + oyun adi, zorluk 1-3
// yildizla, kartin tamami tiklanabilir. Renkler Marka'dan gelir.

class OyunKartiKare extends StatefulWidget {
  final String emoji;
  final String baslik;

  /// 1 = kolay, 2 = orta, 3 = zor
  final int yildiz;

  /// Marka.oyunHafiza gibi, oyuna ait sabit renk.
  final Color renk;

  final VoidCallback onTap;

  const OyunKartiKare({
    super.key,
    required this.emoji,
    required this.baslik,
    required this.yildiz,
    required this.renk,
    required this.onTap,
  });

  @override
  State<OyunKartiKare> createState() => _OyunKartiKareState();
}

class _OyunKartiKareState extends State<OyunKartiKare> {
  bool _basili = false;

  Future<void> _dokun() async {
    if (_basili) return;

    setState(() => _basili = true);

    await Future.delayed(const Duration(milliseconds: 110));

    if (!mounted) return;

    setState(() => _basili = false);

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final zemin = Color.lerp(widget.renk, Colors.white, 0.86)!;
    final yazi = Color.lerp(widget.renk, Colors.black, 0.35)!;
    final sonukYildiz = Color.lerp(widget.renk, Colors.white, 0.62)!;

    return GestureDetector(
      // Kartin tamami tiklanabilir — eskiden yalnizca kucuk ▶ dugmesiydi.
      onTap: _dokun,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _basili ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  zemin,
                  Color.lerp(zemin, Colors.white, 0.45)!,
                ],
              ),
              borderRadius: BorderRadius.circular(Marka.kartYaricap),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.renk.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // İKON
                Container(
                  width: Marka.dokunmaEnAz,
                  height: Marka.dokunmaEnAz,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 34),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // OYUN ADI — tek kelime, aciklama cumlesi yok
                Text(
                  widget.baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: yazi,
                  ),
                ),

                const SizedBox(height: 6),

                // ZORLUK — "Kolay/Orta/Zor" yerine yildiz
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Icon(
                        Icons.star_rounded,
                        size: 17,
                        color: i < widget.yildiz ? widget.renk : sonukYildiz,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// PARILTI
// =============================================================

class _Sparkle extends StatelessWidget {
  final double size;
  final Color color;

  const _Sparkle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      size: size,
      color: color,
    );
  }
}