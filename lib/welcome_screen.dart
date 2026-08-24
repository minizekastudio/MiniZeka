import 'package:flutter/material.dart';

class RoleSelectionPage extends StatefulWidget {
  final VoidCallback onChildTap;
  final VoidCallback onParentTap;

  const RoleSelectionPage({
    super.key,
    required this.onChildTap,
    required this.onParentTap,
  });

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Genel giriş animasyonları
  late Animation<double> _mascotOpacity;
  late Animation<double> _mascotScale;
  late Animation<double> _titleOpacity;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _questionOpacity;

  // Çocuk kartı
  late Animation<double> _childOpacity;
  late Animation<Offset> _childSlide;

  // Ebeveyn kartı
  late Animation<double> _parentOpacity;
  late Animation<Offset> _parentSlide;

  // Alt bilgi
  late Animation<double> _bottomOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    // -----------------------------------------------------
    // BEYİN - OPACITY
    // -----------------------------------------------------

    _mascotOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.22,
        curve: Curves.easeOut,
      ),
    );

    // -----------------------------------------------------
    // BEYİN - SCALE
    // -----------------------------------------------------

    _mascotScale = Tween<double>(
      begin: 0.72,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.32,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    // -----------------------------------------------------
    // BAŞLIK
    // -----------------------------------------------------

    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.16,
        0.40,
        curve: Curves.easeOut,
      ),
    );

    // -----------------------------------------------------
    // SLOGAN
    // -----------------------------------------------------

    _subtitleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.25,
        0.48,
        curve: Curves.easeOut,
      ),
    );

    // -----------------------------------------------------
    // SORU
    // -----------------------------------------------------

    _questionOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.35,
        0.58,
        curve: Curves.easeOut,
      ),
    );

    // -----------------------------------------------------
    // ÇOCUK OPACITY
    // -----------------------------------------------------

    _childOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.45,
        0.73,
        curve: Curves.easeOut,
      ),
    );

    // -----------------------------------------------------
    // ÇOCUK SLIDE
    // -----------------------------------------------------

    _childSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.45,
          0.78,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // -----------------------------------------------------
    // EBEVEYN OPACITY
    // -----------------------------------------------------

    _parentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.56,
        0.84,
        curve: Curves.easeOut,
      ),
    );

    // -----------------------------------------------------
    // EBEVEYN SLIDE
    // -----------------------------------------------------

    _parentSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.56,
          0.88,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // -----------------------------------------------------
    // ALT BİLGİ
    // -----------------------------------------------------

    _bottomOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.72,
        1.0,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // =================================================
          // ARKA PLAN GRADIENT
          // =================================================

          Container(
            decoration: BoxDecoration(
              gradient: Theme.of(context).brightness == Brightness.dark
                  ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF211A2A),
                  Color(0xFF17131F),
                  Color(0xFF17131F),
                ],
              )
                  : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE5FF),
                  Color(0xFFFFF9F9),
                  Color(0xFFFFFBF5),
                ],
              ),
            ),
          ),

          // =================================================
          // ÜST SOL BÜYÜK DEKORASYON
          // =================================================

          Positioned(
            top: -85,
            left: -85,
            child: _decorativeCircle(
              size: 180,
              color: const Color(0xFFD9C2FF).withOpacity(0.55),
            ),
          ),

          // =================================================
          // ÜST SAĞ BÜYÜK DEKORASYON
          // =================================================

          Positioned(
            top: -65,
            right: -55,
            child: _decorativeCircle(
              size: 155,
              color: const Color(0xFFE8D8FF).withOpacity(0.75),
            ),
          ),

          // =================================================
          // SAĞ ÜST KÜÇÜK BALON
          // =================================================

          Positioned(
            top: 115,
            right: 24,
            child: _decorativeCircle(
              size: 34,
              color: const Color(0xFFD9B9FF).withOpacity(0.70),
            ),
          ),

          // =================================================
          // SOL ORTA KÜÇÜK BALON
          // =================================================

          Positioned(
            top: 235,
            left: -28,
            child: _decorativeCircle(
              size: 65,
              color: const Color(0xFFFFE4CB).withOpacity(0.60),
            ),
          ),

          // =================================================
          // ALT SOL DEKORASYON
          // =================================================

          Positioned(
            bottom: -75,
            left: -55,
            child: _decorativeCircle(
              size: 190,
              color: const Color(0xFFDDF3FF).withOpacity(0.85),
            ),
          ),

          // =================================================
          // ALT SAĞ DEKORASYON
          // =================================================

          Positioned(
            bottom: -90,
            right: -65,
            child: _decorativeCircle(
              size: 205,
              color: const Color(0xFFDCC6FF).withOpacity(0.70),
            ),
          ),

          // =================================================
          // YILDIZLAR
          // =================================================

          const Positioned(
            top: 105,
            left: 72,
            child: _Sparkle(
              size: 19,
              color: Color(0xFFFFFFFF),
            ),
          ),

          const Positioned(
            top: 165,
            right: 95,
            child: _Sparkle(
              size: 14,
              color: Color(0xFFFFFFFF),
            ),
          ),

          const Positioned(
            top: 315,
            left: 35,
            child: _Sparkle(
              size: 13,
              color: Color(0xFFE1C8FF),
            ),
          ),

          const Positioned(
            bottom: 145,
            right: 38,
            child: _Sparkle(
              size: 18,
              color: Color(0xFFD6B6FF),
            ),
          ),

          // =================================================
          // ANA İÇERİK
          // =================================================

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  22,
                  26,
                  22,
                  28,
                ),
                child: Column(
                  children: [
                    // =========================================
                    // BEYİN / MASKOT
                    // =========================================

                    FadeTransition(
                      opacity: _mascotOpacity,
                      child: ScaleTransition(
                        scale: _mascotScale,
                        child: _buildMascot(),
                      ),
                    ),

                    const SizedBox(height: 17),

                    // =========================================
                    // MINİZEKA
                    // =========================================

                    FadeTransition(
                      opacity: _titleOpacity,
                      child: const Text(
                        'MiniZeka',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                          color: Color(0xFF5B32A3),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // =========================================
                    // SLOGAN
                    // =========================================

                    FadeTransition(
                      opacity: _subtitleOpacity,
                      child: const Text(
                        'Oyna • Öğren • Keşfet! ✨',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: Color(0xFF78628E),
                        ),
                      ),
                    ),

                    const SizedBox(height: 37),

                    // =========================================
                    // SORU
                    // =========================================

                    FadeTransition(
                      opacity: _questionOpacity,
                      child: Column(
                        children: [
                          const Text(
                            'Kim olarak devam etmek istiyorsun?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4E3865),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Dekoratif çizgi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB178F5),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7B42D1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Container(
                                width: 28,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB178F5),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 23),

                    // =========================================
                    // ÇOCUK KARTI
                    // =========================================

                    FadeTransition(
                      opacity: _childOpacity,
                      child: SlideTransition(
                        position: _childSlide,
                        child: RoleCard(
                          icon: '👧',
                          title: 'Çocuk',
                          description:
                          'Eğlenceli oyunlarla öğrenmeye başla!',
                          backgroundColor: const Color(0xFFE9D7FF),
                          secondaryColor: const Color(0xFFDCC1FF),
                          textColor: const Color(0xFF5A2E9D),
                          arrowColor: const Color(0xFF6F35CF),
                          onTap: widget.onChildTap,
                          decorativeColor:
                          const Color(0xFFC9A5FF),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // =========================================
                    // EBEVEYN KARTI
                    // =========================================

                    FadeTransition(
                      opacity: _parentOpacity,
                      child: SlideTransition(
                        position: _parentSlide,
                        child: RoleCard(
                          icon: '👨‍👩‍👧',
                          title: 'Ebeveyn',
                          description:
                          'Çocuğunun gelişimini takip et ve yönet!',
                          backgroundColor: const Color(0xFFDDF2FF),
                          secondaryColor: const Color(0xFFC9E8FF),
                          textColor: const Color(0xFF28689B),
                          arrowColor: const Color(0xFF367CC0),
                          onTap: widget.onParentTap,
                          decorativeColor:
                          const Color(0xFFACD8F7),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================================
                    // ALT BİLGİ
                    // =========================================

                    FadeTransition(
                      opacity: _bottomOpacity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.75),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: Color(0xFF8B57D2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Güvenli • Eğitici • Keyifli',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF89739A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    FadeTransition(
                      opacity: _bottomOpacity,
                      child: const Text(
                        'Minik adımlarla büyük keşifler! ✨',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFA28FAE),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DEKORATİF DAİRE
  // =========================================================

  Widget _decorativeCircle({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  // =========================================================
  // MASKOT
  // =========================================================

  Widget _buildMascot() {
    return Container(
      width: 176,
      height: 176,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF1E5FF),
            Color(0xFFE1F4FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8754D4).withOpacity(0.13),
            blurRadius: 28,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // İç halka
          Container(
            width: 145,
            height: 145,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.55),
                width: 2,
              ),
            ),
          ),

          // Beyin
          const Text(
            '🧠',
            style: TextStyle(
              fontSize: 105,
            ),
          ),

          // Küçük yıldız
          const Positioned(
            top: 18,
            right: 21,
            child: _Sparkle(
              size: 15,
              color: Colors.white,
            ),
          ),

          // Küçük yıldız
          const Positioned(
            bottom: 28,
            left: 20,
            child: _Sparkle(
              size: 11,
              color: Color(0xFFD2B2FF),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ROL KARTI
// =============================================================

class RoleCard extends StatefulWidget {
  final String icon;
  final String title;
  final String description;

  final Color backgroundColor;
  final Color secondaryColor;
  final Color textColor;
  final Color arrowColor;
  final Color decorativeColor;

  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.secondaryColor,
    required this.textColor,
    required this.arrowColor,
    required this.decorativeColor,
    required this.onTap,
  });

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> {
  bool _pressed = false;

  Future<void> _handleTap() async {
    if (_pressed) return;

    setState(() {
      _pressed = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 120),
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
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(29),
          splashColor:
          widget.textColor.withOpacity(0.08),
          highlightColor:
          widget.textColor.withOpacity(0.04),
          child: Container(
            width: double.infinity,
            height: 142,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.backgroundColor,
                  widget.secondaryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(29),
              border: Border.all(
                color: Colors.white.withOpacity(0.85),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  widget.textColor.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // =========================================
                // DEKORATİF DAİRE
                // =========================================

                Positioned(
                  right: -25,
                  bottom: -35,
                  child: Container(
                    width: 120,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(70),
                    ),
                  ),
                ),

                // =========================================
                // DEKORATİF KÜÇÜK DAİRE
                // =========================================

                Positioned(
                  right: 65,
                  top: -20,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color:
                      widget.decorativeColor.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // =========================================
                // YILDIZ
                // =========================================

                Positioned(
                  right: 21,
                  top: 17,
                  child: Icon(
                    Icons.star_rounded,
                    size: 23,
                    color: widget.decorativeColor,
                  ),
                ),

                // =========================================
                // ANA İÇERİK
                // =========================================

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // ===================================
                      // AVATAR
                      // ===================================

                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.80),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.95),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.textColor
                                  .withOpacity(0.10),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.icon,
                            style: const TextStyle(
                              fontSize: 43,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 15),

                      // ===================================
                      // METİNLER
                      // ===================================

                      Expanded(
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: widget.textColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: widget.textColor
                                    .withOpacity(0.72),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // ===================================
                      // OK BUTONU
                      // ===================================

                      Container(
                        width: 51,
                        height: 51,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.arrowColor,
                              widget.arrowColor.withOpacity(0.82),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.arrowColor
                                  .withOpacity(0.22),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
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
// YILDIZ / PARILTI
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