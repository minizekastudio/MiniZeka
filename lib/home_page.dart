import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'game_id.dart';
import 'main.dart';
import 'game_kit.dart';
import 'storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    with TickerProviderStateMixin, RouteAware {
  late AnimationController _controller;

  /// Slow shared ticker: every card icon breathes off this one.
  late AnimationController _idle;

  /// Today's usage and limit per game, read once and after each game.
  Map<GameId, int> _usedSeconds = {};
  Map<GameId, int> _limitMinutes = {};
  Set<String> _playedGames = {};

  /// Games the parent has left switched on. Everything ships on.
  List<GameId> _visibleGames = GameId.values;

  late Animation<double> _titleAnimation;

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

    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    _controller.forward();

    _loadAvatar();
    _loadGameState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  /// Bir oyundan geri donuldu: kalan sure ve oynanmislik degismis olabilir.
  @override
  void didPopNext() => _loadGameState();

  Future<void> _loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = StorageKeys.isoDate(DateTime.now());

    final used = <GameId, int>{};
    final limit = <GameId, int>{};

    for (final game in GameId.values) {
      used[game] =
          prefs.getInt(StorageKeys.gamePlayedSeconds(game, today)) ?? 0;
      limit[game] = prefs.getInt(StorageKeys.gameLimitMinutes(game)) ??
          game.defaultLimitMinutes;
    }

    final played =
        (prefs.getStringList(StorageKeys.playedGames) ?? <String>[]).toSet();

    final visible = GameId.values
        .where((g) => prefs.getBool(StorageKeys.gameEnabled(g)) ?? true)
        .toList();

    if (!mounted) return;

    setState(() {
      _usedSeconds = used;
      _limitMinutes = limit;
      _playedGames = played;
      _visibleGames = visible;
    });
  }

  /// Bugun bu oyundan geriye kalan oran, 0..1.
  double _remainingFor(GameId game) {
    final allowed = (_limitMinutes[game] ?? game.defaultLimitMinutes) * 60;
    if (allowed <= 0) return 0;

    final left = allowed - (_usedSeconds[game] ?? 0);
    return (left / allowed).clamp(0.0, 1.0);
  }

  /// Oyun ekranlarini acan geri cagirmalar; sira GameId ile ayni.
  VoidCallback _openFor(GameId game) {
    switch (game) {
      case GameId.memory:
        return widget.onMemoryTap;
      case GameId.attention:
        return widget.onAttentionTap;
      case GameId.math:
        return widget.onMathTap;
      case GameId.shape:
        return widget.onShapeTap;
      case GameId.logic:
        return widget.onLogicTap;
      case GameId.word:
        return () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WordGame()),
            );
      case GameId.letter:
        return () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LetterGame()),
            );
    }
  }

  /// Iki sutunlu izgara; son satir tek kalirsa sag hucre bos birakilir.
  List<Widget> _gameRows() {
    final entrance = <Animation<double>>[
      _game1Animation,
      _game2Animation,
      _game3Animation,
      _game4Animation,
      _game5Animation,
      _game6Animation,
      _game7Animation,
    ];

    final games = _visibleGames;

    // Ebeveyn hepsini kapattiysa cocuk bos ekranla karsilasmasin.
    if (games.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 14),
              Text(
                'Şimdilik oyun yok',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Brand.leafDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Annen ya da baban oyunları açabilir.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.black54),
              ),
            ],
          ),
        ),
      ];
    }

    final rows = <Widget>[];

    for (var i = 0; i < games.length; i += 2) {
      final pair = games.skip(i).take(2).toList();

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var slot = 0; slot < 2; slot++) ...[
                if (slot > 0) const SizedBox(width: 13),
                Expanded(
                  child: slot < pair.length
                      ? _animatedSection(
                          animation: entrance[i + slot],
                          child: _cardFor(pair[slot], i + slot),
                        )
                      : const SizedBox(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return rows;
  }

  Widget _cardFor(GameId game, int index) {
    final remaining = _remainingFor(game);
    final exhausted = remaining <= 0;

    return GameCard(
      game: game,
      color: game.brandColor,
      remaining: remaining,
      exhausted: exhausted,
      played: _playedGames.contains(game.storageId),
      idle: _idle,
      phase: index * 0.17,
      // Suresi dolan oyuna girilmiyor: eskiden cocuk oyuna girip 300 ms
      // sonra disari atiliyordu ve nedenini anlamiyordu.
      onTap: exhausted ? () => _showAsleep(game) : _openFor(game),
    );
  }

  /// "Bu oyun bugunluk uyudu" — oyuna hic girmeden.
  void _showAsleep(GameId game) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Color.lerp(game.brandColor, Colors.white, 0.86),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('😴', style: TextStyle(fontSize: 44)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${game.shortTitle} bugünlük uyudu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color.lerp(game.brandColor, Colors.black, 0.35),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Yarın yeniden oynayabilirsin.\nŞimdi başka bir oyun seç! 🌙',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: Brand.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: game.brandColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Future<void> _loadAvatar() async {
    await AvatarManager.loadAvatar();

    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _idle.dispose();
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
                                fontSize: 17,
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
                // OYUN IZGARASI
                // =================================================
                //
                // Kartlar GameId.values'tan uretiliyor: sira, isim, emoji ve
                // varsayilan sure hep oradan geliyor. Yeni oyun eklemek icin
                // burada hicbir sey degismiyor.

                ..._gameRows(),

              ],
            ),
          ),
        ],
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

// =============================================================
// GAME CARD
// =============================================================
//
// One square tile per game. A child who cannot read yet has to understand
// three things at a glance: which game this is, whether they have played it,
// and whether there is still time left today. Nothing here is written in
// words except the game's own name.

class GameCard extends StatefulWidget {
  final GameId game;

  /// The game's fixed colour, e.g. Brand.gameMemory.
  final Color color;

  /// Fraction of today's allowance still unused, 0..1.
  final double remaining;

  /// True once today's limit is spent; the tile goes quiet.
  final bool exhausted;

  /// True when the child has finished this game at least once.
  final bool played;

  /// Shared idle animation so every icon breathes off the same ticker.
  final Animation<double> idle;

  /// Per-card offset so the icons do not bob in lockstep.
  final double phase;

  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.game,
    required this.color,
    required this.remaining,
    required this.exhausted,
    required this.played,
    required this.idle,
    required this.phase,
    required this.onTap,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _pressed = false;

  Future<void> _handleTap() async {
    if (_pressed) return;

    setState(() => _pressed = true);

    await Future.delayed(const Duration(milliseconds: 110));

    if (!mounted) return;

    setState(() => _pressed = false);

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final quiet = widget.exhausted;

    // Sure dolunca kart susar: renk cekilir, ikon solar.
    final background = quiet
        ? Color.lerp(color, Colors.white, 0.94)!
        : Color.lerp(color, Colors.white, 0.86)!;
    final labelColor = quiet
        ? Color.lerp(color, Colors.black, 0.10)!.withValues(alpha: 0.45)
        : Color.lerp(color, Colors.black, 0.35)!;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AspectRatio(
          aspectRatio: 1.12,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  background,
                  Color.lerp(background, Colors.white, 0.45)!,
                ],
              ),
              borderRadius: BorderRadius.circular(Brand.cardRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: quiet ? 0.06 : 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: _icon(color, quiet)),
                const SizedBox(height: 6),
                Text(
                  widget.game.shortTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 7),
                _timeBar(color, quiet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Breathing icon plus the "already played" star.
  Widget _icon(Color color, bool quiet) {
    final tile = Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: quiet ? 0.55 : 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          widget.game.icon,
          size: 44,
          color: quiet ? color.withValues(alpha: 0.40) : color,
        ),
      ),
    );

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Suresi dolan oyun hareket etmiyor: "su an uyuyor" hissi.
          if (quiet)
            tile
          else
            AnimatedBuilder(
              animation: widget.idle,
              builder: (context, child) {
                final t = (widget.idle.value + widget.phase) * 2 * math.pi;

                return Transform.translate(
                  offset: Offset(0, math.sin(t) * 3.5),
                  child: Transform.rotate(
                    angle: math.sin(t) * 0.045,
                    child: child,
                  ),
                );
              },
              child: tile,
            ),

          if (quiet)
            const Positioned(
              right: -4,
              bottom: -2,
              child: Text('😴', style: TextStyle(fontSize: 22)),
            )
          else if (widget.played)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_rounded,
                  size: 20,
                  color: Brand.sun,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// How much of today's playtime is left. No numbers, just a bar.
  Widget _timeBar(Color color, bool quiet) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: quiet ? 1 : widget.remaining.clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: Colors.white.withValues(alpha: 0.75),
        valueColor: AlwaysStoppedAnimation<Color>(
          quiet ? Colors.white.withValues(alpha: 0.75) : color,
        ),
      ),
    );
  }
}
