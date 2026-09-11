import 'package:flutter/material.dart';
import 'storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgeSelectionPage extends StatefulWidget {
  final VoidCallback onAgeSelected;

  const AgeSelectionPage({
    super.key,
    required this.onAgeSelected,
  });

  @override
  State<AgeSelectionPage> createState() => _AgeSelectionPageState();
}

class _AgeSelectionPageState extends State<AgeSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _titleOpacity;
  late Animation<double> _titleScale;
  late Animation<double> _descriptionOpacity;

  late Animation<double> _card1Opacity;
  late Animation<Offset> _card1Slide;

  late Animation<double> _card2Opacity;
  late Animation<Offset> _card2Slide;

  late Animation<double> _card3Opacity;
  late Animation<Offset> _card3Slide;

  late Animation<double> _card4Opacity;
  late Animation<Offset> _card4Slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // =====================================================
    // BAŞLIK
    // =====================================================

    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.25,
        curve: Curves.easeOut,
      ),
    );

    _titleScale = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.30,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    // =====================================================
    // AÇIKLAMA
    // =====================================================

    _descriptionOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.15,
        0.38,
        curve: Curves.easeOut,
      ),
    );

    // =====================================================
    // 4 - 5 YAŞ
    // =====================================================

    _card1Opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.28,
        0.52,
        curve: Curves.easeOut,
      ),
    );

    _card1Slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.28,
          0.58,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // =====================================================
    // 6 - 7 YAŞ
    // =====================================================

    _card2Opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.38,
        0.62,
        curve: Curves.easeOut,
      ),
    );

    _card2Slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.38,
          0.68,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // =====================================================
    // 8 - 9 YAŞ
    // =====================================================

    _card3Opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.48,
        0.72,
        curve: Curves.easeOut,
      ),
    );

    _card3Slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.48,
          0.78,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // =====================================================
    // 10 - 12 YAŞ
    // =====================================================

    _card4Opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.58,
        0.82,
        curve: Curves.easeOut,
      ),
    );

    _card4Slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.58,
          0.88,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // =====================================================
  // YAŞ SEÇİMİ
  // =====================================================

  Future<void> _selectAge(int age) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(StorageKeys.childAge, age);

    if (!mounted) return;

    widget.onAgeSelected();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // =================================================
          // ARKA PLAN
          // =================================================

          Container(
            decoration: BoxDecoration(
              gradient: Theme.of(context).brightness == Brightness.dark
                  ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF133120),
                  Color(0xFF0E2418),
                  Color(0xFF0E2418),
                ],
              )
                  : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE48F),
                  Color(0xFFFFFAF5),
                  Color(0xFFFFFBF7),
                ],
              ),
            ),
          ),

          // =================================================
          // ÜST SOL DAİRE
          // =================================================

          Positioned(
            top: -75,
            left: -65,
            child: Container(
              width: 165,
              height: 165,
              decoration: BoxDecoration(
                color: const Color(0xFFC7FFCD).withValues(alpha: 0.58),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // =================================================
          // ÜST SAĞ DAİRE
          // =================================================

          Positioned(
            top: -55,
            right: -45,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                color: const Color(0xFFD9FFDD).withValues(alpha: 0.75),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // =================================================
          // SOL ORTA BALON
          // =================================================

          Positioned(
            top: 245,
            left: -28,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE3CC).withValues(alpha: 0.58),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // =================================================
          // ALT SOL DAİRE
          // =================================================

          Positioned(
            bottom: -70,
            left: -55,
            child: Container(
              width: 185,
              height: 185,
              decoration: BoxDecoration(
                color: const Color(0xFFDDF3FF).withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // =================================================
          // ALT SAĞ DAİRE
          // =================================================

          Positioned(
            bottom: -75,
            right: -55,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFD0FFD5).withValues(alpha: 0.70),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // =================================================
          // PARILTILAR
          // =================================================

          const Positioned(
            top: 105,
            left: 68,
            child: _Sparkle(
              size: 17,
              color: Colors.white,
            ),
          ),

          const Positioned(
            top: 145,
            right: 70,
            child: _Sparkle(
              size: 13,
              color: Colors.white,
            ),
          ),

          const Positioned(
            top: 290,
            right: 35,
            child: _Sparkle(
              size: 15,
              color: Color(0xFFB9FFC0),
            ),
          ),

          // =================================================
          // İÇERİK
          // =================================================

          SafeArea(
            child: Column(
              children: [
                // =================================================
                // ÜST BAR
                // =================================================

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    0,
                  ),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.72),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 22,
                              color: Color(0xFF1F7D38),
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              '🧒',
                              style: TextStyle(
                                fontSize: 22,
                              ),
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Yaşını Seç',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F7E39),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Sağ tarafta denge için boş alan
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                // =================================================
                // ANA ALAN
                // =================================================

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      22,
                      28,
                      22,
                      30,
                    ),
                    child: Column(
                      children: [
                        // =========================================
                        // BAŞLIK
                        // =========================================

                        FadeTransition(
                          opacity: _titleOpacity,
                          child: ScaleTransition(
                            scale: _titleScale,
                            child: Column(
                              children: [
                                const Text(
                                  'Kaç yaşındasın? 🎈',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    color: Color(0xFF259242),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Dekoratif çizgi
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 25,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF78F584),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF35DE4E),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 25,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF78F584),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // =========================================
                        // AÇIKLAMA
                        // =========================================

                        FadeTransition(
                          opacity: _descriptionOpacity,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 18,
                            ),
                            child: Text(
                              'Sana uygun oyunları hazırlayabilmemiz için yaş grubunu seç.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF23D83E),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // =========================================
                        // 4 - 5
                        // =========================================

                        FadeTransition(
                          opacity: _card1Opacity,
                          child: SlideTransition(
                            position: _card1Slide,
                            child: AgeCard(
                              emoji: '🧸',
                              title: '4 – 5 Yaş',
                              subtitle: 'Keşfetmeye ilk adım',
                              backgroundColor: const Color(0xFFD5FFD9),
                              secondaryColor: const Color(0xFFC1FFC7),
                              iconColor: const Color(0xFF2BDC45),
                              onTap: () => _selectAge(5),
                            ),
                          ),
                        ),

                        const SizedBox(height: 13),

                        // =========================================
                        // 6 - 7
                        // =========================================

                        FadeTransition(
                          opacity: _card2Opacity,
                          child: SlideTransition(
                            position: _card2Slide,
                            child: AgeCard(
                              emoji: '🌈',
                              title: '6 – 7 Yaş',
                              subtitle: 'Öğren, oyna ve keşfet',
                              backgroundColor: const Color(0xFFDDF2FF),
                              secondaryColor: const Color(0xFFC9E8FF),
                              iconColor: const Color(0xFF327BB4),
                              onTap: () => _selectAge(7),
                            ),
                          ),
                        ),

                        const SizedBox(height: 13),

                        // =========================================
                        // 8 - 9
                        // =========================================

                        FadeTransition(
                          opacity: _card3Opacity,
                          child: SlideTransition(
                            position: _card3Slide,
                            child: AgeCard(
                              emoji: '🚀',
                              title: '8 – 9 Yaş',
                              subtitle: 'Zekanla yeni şeyler keşfet',
                              backgroundColor: const Color(0xFFD9F3E5),
                              secondaryColor: const Color(0xFFC8EBD8),
                              iconColor: const Color(0xFF3A8A63),
                              onTap: () => _selectAge(9),
                            ),
                          ),
                        ),

                        const SizedBox(height: 13),

                        // =========================================
                        // 10 - 12
                        // =========================================

                        FadeTransition(
                          opacity: _card4Opacity,
                          child: SlideTransition(
                            position: _card4Slide,
                            child: AgeCard(
                              emoji: '🧠',
                              title: '10 – 12 Yaş',
                              subtitle: 'Düşün, çöz ve kendini geliştir',
                              backgroundColor: const Color(0xFFFFE1C4),
                              secondaryColor: const Color(0xFFFFD6AE),
                              iconColor: const Color(0xFFC66D2C),
                              onTap: () => _selectAge(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // =========================================
                        // ALT BİLGİ
                        // =========================================

                        FadeTransition(
                          opacity: _descriptionOpacity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 15,
                                color: Color(0xFF58E46D),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Yaşına uygun oyunlar seni bekliyor!',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF41E059),
                                ),
                              ),
                            ],
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
// YAŞ KARTI
// =============================================================

class AgeCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color secondaryColor;
  final Color iconColor;
  final VoidCallback onTap;

  const AgeCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.secondaryColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<AgeCard> createState() => _AgeCardState();
}

class _AgeCardState extends State<AgeCard> {
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
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(25),
          splashColor: widget.iconColor.withValues(alpha: 0.08),
          highlightColor: widget.iconColor.withValues(alpha: 0.04),
          child: Container(
            width: double.infinity,
            height: 82,
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
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.iconColor.withValues(alpha: 0.10),
                  blurRadius: 15,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Dekoratif daire
                Positioned(
                  right: -18,
                  top: -25,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Dekoratif yıldız
                Positioned(
                  right: 18,
                  top: 10,
                  child: Icon(
                    Icons.star_rounded,
                    size: 19,
                    color: widget.iconColor.withValues(alpha: 0.32),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                  ),
                  child: Row(
                    children: [
                      // =========================================
                      // EMOJİ
                      // =========================================

                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.95),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.iconColor.withValues(alpha: 0.09),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.emoji,
                            style: const TextStyle(
                              fontSize: 30,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 13),

                      // =========================================
                      // METİN
                      // =========================================

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
                                fontSize: 17.5,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1F7D38),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF21CA3A)
                                    .withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // =========================================
                      // OK
                      // =========================================

                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.70),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 22,
                          color: widget.iconColor,
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