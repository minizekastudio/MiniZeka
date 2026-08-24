import 'package:flutter/material.dart';
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
  late Animation<double> _welcomeAnimation;
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

    _welcomeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.12,
        0.38,
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
                color: const Color(0xFFE4D3FF).withOpacity(0.55),
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
                color: const Color(0xFFEBDFFF).withOpacity(0.72),
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
                color: const Color(0xFFDDF3FF).withOpacity(0.8),
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
                color: const Color(0xFFE3D0FF).withOpacity(0.72),
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
              color: Color(0xFFD3B5FF),
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
                            color: Colors.white.withOpacity(0.72),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 17,
                            color: Color(0xFF55465D),
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
                                color: Colors.white.withOpacity(0.90),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 9,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.settings_rounded,
                                color: Color(0xFF7653A8),
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
                                color: Colors.white.withOpacity(0.90),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
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
                              Color(0xFFE9D8FF),
                              Color(0xFFDDF5FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(19),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9B70D4).withOpacity(0.12),
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
                              'MiniZeka',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: Color(0xFF5D3D7A),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Oyna • Öğren • Keşfet! ✨',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8A7598),
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
                                Color(0xFFE9D8FF),
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
                                color: const Color(0xFF7653A8).withOpacity(0.14),
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
                // HAZIR MISIN KARTI
                // =================================================

                _animatedSection(
                  animation: _welcomeAnimation,
                  slideBegin: 0.25,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE9D8FF),
                          Color(0xFFDDF5FF),
                        ],
                      ),
                      borderRadius:
                      BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.9),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B62B5)
                              .withOpacity(0.13),
                          blurRadius: 17,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hazır mısın? 🚀',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF51376A),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Bugün biraz eğlenmeye ve zekanı geliştirmeye ne dersin?',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF66556F),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color:
                            Colors.white.withOpacity(0.70),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '🌈',
                              style:
                              TextStyle(fontSize: 41),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // =================================================
                // BİLGİ KARTLARI
                // =================================================

                _animatedSection(
                  animation: _infoAnimation,
                  slideBegin: 0.18,
                  child: Row(
                    children: [
                      const Expanded(
                        child: _InfoCard(
                          emoji: '🎮',
                          title: '5 Oyun',
                          subtitle: 'Keşfet',
                        ),
                      ),

                      const SizedBox(width: 10),

                      const Expanded(
                        child: _InfoCard(
                          emoji: '🧠',
                          title: 'Zekan Gelişsin',
                          subtitle: 'Oyna & öğren',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

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
                              color: Color(0xFF503B5C),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Her oyun farklı bir becerini geliştirir.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF8A7B8E),
                        ),
                      ),

                      SizedBox(height: 15),
                    ],
                  ),
                ),

                // =================================================
                // HAFIZA
                // =================================================

                _animatedSection(
                  animation: _game1Animation,
                  child: GameCard(
                    emoji: '🧠',
                    title: 'Hafıza Oyunu',
                    description:
                    'Kartların eşlerini bul!',
                    difficulty: 'Kolay',
                    color: const Color(0xFFE9D8FF),
                    buttonColor:
                    const Color(0xFF8B62B5),
                    onTap: widget.onMemoryTap,
                  ),
                ),

                // =================================================
                // DİKKAT
                // =================================================

                _animatedSection(
                  animation: _game2Animation,
                  child: GameCard(
                    emoji: '👀',
                    title: 'Dikkat Oyunu',
                    description:
                    'Farklı olanı bul!',
                    difficulty: 'Orta',
                    color: const Color(0xFFFFE1C4),
                    buttonColor:
                    const Color(0xFFE88B42),
                    onTap: widget.onAttentionTap,
                  ),
                ),

                // =================================================
                // MATEMATİK
                // =================================================

                _animatedSection(
                  animation: _game3Animation,
                  child: GameCard(
                    emoji: '🔢',
                    title: 'Matematik Oyunu',
                    description:
                    'Doğru sonucu bul!',
                    difficulty: 'Orta',
                    color: const Color(0xFFD8ECFF),
                    buttonColor:
                    const Color(0xFF4D91D0),
                    onTap: widget.onMathTap,
                  ),
                ),

                // =================================================
                // EŞLEŞTİRME
                // =================================================

                _animatedSection(
                  animation: _game4Animation,
                  child: GameCard(
                    emoji: '🔷',
                    title: 'Eşleştirme Oyunu',
                    description:
                    'Doğru şekli eşleştir!',
                    difficulty: 'Kolay',
                    color: const Color(0xFFD6F6F1),
                    buttonColor:
                    const Color(0xFF3FA99C),
                    onTap: widget.onShapeTap,
                  ),
                ),

                // =================================================
                // MANTIK
                // =================================================

                _animatedSection(
                  animation: _game5Animation,
                  child: GameCard(
                    emoji: '🧩',
                    title: 'Mantık Oyunu',
                    description:
                    'Mantığını kullan ve çöz!',
                    difficulty: 'Zor',
                    color: const Color(0xFFE1F4D4),
                    buttonColor:
                    const Color(0xFF6FA84A),
                    onTap: widget.onLogicTap,
                  ),
                ),

                const SizedBox(height: 8),

                // =================================================
// KELİME AVI
// =================================================

                _animatedSection(
                  animation: _game6Animation,
                  slideBegin: 0.10,
                  child: GameCard(
                    emoji: '🔎',
                    title: 'Kelime Avı',
                    description: 'Harfleri birleştir, kelimeyi bul!',
                    difficulty: 'Orta',
                    color: const Color(0xFFF3E2FF),
                    buttonColor: const Color(0xFF9B70D4),
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

                const SizedBox(height: 8),

                // =================================================
// HARFLERİ YERLEŞTİR
// =================================================

                _animatedSection(
                  animation: _game7Animation,
                  slideBegin: 0.10,
                  child: GameCard(
                    emoji: '🔤',
                    title: 'Harfleri Yerleştir',
                    description: 'Harfleri doğru sıraya koy!',
                    difficulty: 'Kolay',
                    color: const Color(0xFFE4F3FF),
                    buttonColor: const Color(0xFF6B9ED1),
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

                const SizedBox(height: 8),

                // =================================================
                // BUGÜNÜN HEDEFİ
                // =================================================

                _animatedSection(
                  animation: _game5Animation,
                  slideBegin: 0.08,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(0.88),
                      borderRadius:
                      BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                          Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Text(
                          '🌟',
                          style:
                          TextStyle(fontSize: 29),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bugünün hedefi',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                  FontWeight.w900,
                                  color:
                                  Color(0xFF51425A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Bir oyun seç ve bugün yeni bir şey öğren! 💜',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color:
                                  Color(0xFF776A7A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // =================================================
                // ALT MOTİVASYON
                // =================================================

                _animatedSection(
                  animation: _game5Animation,
                  slideBegin: 0.08,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF3E9FF),
                          Color(0xFFE9F8FF),
                        ],
                      ),
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          '💡',
                          style:
                          TextStyle(fontSize: 25),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Her doğru cevap seni biraz daha ileri götürür! 🌟',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                              FontWeight.w700,
                              color:
                              Color(0xFF654B76),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
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
// BİLGİ KARTI
// =============================================================

class _InfoCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF51425A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF8A7B8E),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// OYUN KARTI
// =============================================================

class GameCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String description;
  final String difficulty;
  final Color color;
  final Color buttonColor;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.color,
    required this.buttonColor,
    required this.onTap,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _pressed = false;

  Future<void> _handleTap() async {
    if (_pressed) return;

    setState(() {
      _pressed = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 110),
    );

    if (!mounted) return;

    setState(() {
      _pressed = false;
    });

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.965 : 1.0,
      duration:
      const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Container(
        margin:
        const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.color,
              Color.lerp(
                widget.color,
                Colors.white,
                0.08,
              )!,
            ],
          ),
          borderRadius:
          BorderRadius.circular(25),
          border: Border.all(
            color:
            Colors.white.withOpacity(0.85),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.buttonColor
                  .withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // OYUN İKONU
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color:
                Colors.white.withOpacity(0.78),
                borderRadius:
                BorderRadius.circular(20),
                border: Border.all(
                  color:
                  Colors.white.withOpacity(0.9),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  widget.emoji,
                  style:
                  const TextStyle(fontSize: 32),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // METİNLER
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w900,
                      color:
                      Color(0xFF4F4353),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    widget.description,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color:
                      Color(0xFF716574),
                    ),
                  ),

                  const SizedBox(height: 7),

                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withOpacity(0.72),
                      borderRadius:
                      BorderRadius.circular(9),
                    ),
                    child: Text(
                      '⭐ ${widget.difficulty}',
                      style:
                      const TextStyle(
                        fontSize: 9.5,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Color(0xFF67576D),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // OYNA BUTONU
            GestureDetector(
              onTap: _handleTap,
              child: AnimatedContainer(
                duration:
                const Duration(
                  milliseconds: 110,
                ),
                width:
                _pressed ? 47 : 51,
                height:
                _pressed ? 47 : 51,
                decoration:
                BoxDecoration(
                  color:
                  widget.buttonColor,
                  borderRadius:
                  BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: widget.buttonColor
                          .withOpacity(0.25),
                      blurRadius: 9,
                      offset:
                      const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
            ),
          ],
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