import 'dart:math';

import 'package:flutter/material.dart';

import '../achievement_manager.dart';
import '../game_id.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage_keys.dart';
import '../app_theme.dart';
import '../difficulty.dart';
import '../game_kit.dart';
import 'memory_symbols.dart';
import '../sound_manager.dart';

// =====================================================
// 1 - HAFIZA OYUNU
// =====================================================

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key, this.random});

  /// Injected by tests so a board can be reproduced.
  final Random? random;

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame>
    with TickerProviderStateMixin, GameSessionMixin {
  late final Random _random = widget.random ?? Random();

  /// After this many mismatched pairs in a row, the partner of the card the
  /// child turns over is pointed out. Losing three in a row is where a small
  /// child starts tapping at random instead of remembering.
  static const int _hintAfterMisses = 3;

  int _consecutiveMisses = 0;

  /// Card being pointed out, or -1. Public so a test can read it.
  int hintIndex = -1;

  late final AnimationController _hintPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  // ---- GameSessionMixin sozlesmesi ----

  @override
  GameId get game => GameId.memory;

  @override
  String get timeUpMessage =>
      'Hafıza oyunu için belirlenen günlük süreyi kullandın. 🌙';

  @override
  int get currentScore => score;

  /// Oyun zaten bittiyse sure uyarisi gosterme.
  @override
  bool get canShowTimeUpDialog =>
      cards.isNotEmpty && !matched.every((item) => item) && !finishDialogShown;

  /// Ladder position. Kept across sessions so the climb means something.
  int levelIndex = 0;
  int roundsCleared = 0;

  GameLevel get level => memoryLadder[levelIndex];

  @override
  void onChildAgeLoaded() {
    // Yas yalnizca NEREDEN basladigini belirler; kayitli ilerleme varsa o
    // kazanir ve seviye asla geri gitmez.
    levelIndex = startingLevelFor(ageBand);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final resumed = resumeLadder(
      ladder: memoryLadder,
      startingLevel: levelIndex,
      savedLevel: prefs.getInt(StorageKeys.gameLevel(game)),
      savedRounds: prefs.getInt(StorageKeys.gameRoundsCleared(game)) ?? 0,
    );

    if (!mounted) return;

    setState(() {
      levelIndex = resumed.levelIndex;
      roundsCleared = resumed.roundsCleared;
      startGame();
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.gameLevel(game), levelIndex);
    await prefs.setInt(StorageKeys.gameRoundsCleared(game), roundsCleared);
  }

  /// Tur temiz bitti: bolum ilerler, dolduysa bir ust basamak acilir.
  ///
  /// Donen deger bitis ekraninin ne soyleyecegini belirler; cocuk ayni
  /// tahtayi tekrar oynamadigini gorsun diye.
  RoundOutcome _roundCleared() {
    final next = advanceLadder(
      ladder: memoryLadder,
      levelIndex: levelIndex,
      roundsCleared: roundsCleared,
    );

    levelIndex = next.levelIndex;
    roundsCleared = next.roundsCleared;

    _saveProgress();

    return next.outcome;
  }

  List<String> cards = [];
  List<bool> revealed = [];
  List<bool> matched = [];

  int firstIndex = -1;
  int secondIndex = -1;

  int score = 0;
  int moves = 0;

  bool checking = false;
  bool finishDialogShown = false;

  /// Bumped every time a board is dealt, so a pair still waiting to turn
  /// over can tell that the board it belongs to has been replaced.
  int _boardGeneration = 0;

  @override
  void initState() {
    super.initState();

    // Kartlari hemen kur: yas bilgisi asenkron geldigi icin
    // ilk build ondan once calisiyor ve 'cards' bos kaliyordu.
    startGame();

    startGameSession();
  }

  // =====================================================
  // YENİ OYUN
  // =====================================================

  /// Tight enough that a 20-card board still gives 64 px cards on the
  /// narrowest phone.
  static const double _cardGap = 8;

  static const EdgeInsets _boardPadding = EdgeInsets.fromLTRB(12, 4, 12, 12);

  void startGame() {
    _boardGeneration++;

    // Kart sayisi merdivenden; tahta ortasinda degismesin diye yalnizca
    // yeni tur kurulurken okunuyor.
    final pairCount = level.cards ~/ 2;

    // One face per look-alike group, so no board holds 🍎 next to 🍓.
    final selectedPairs = dealPairSymbols(
      pairCount: pairCount,
      random: _random,
    );

    cards = [...selectedPairs, ...selectedPairs];

    cards.shuffle(_random);

    revealed = List<bool>.filled(cards.length, false);

    matched = List<bool>.filled(cards.length, false);

    firstIndex = -1;
    secondIndex = -1;

    score = 0;
    moves = 0;

    checking = false;
    finishDialogShown = false;
    timeUpDialogShown = false;

    _consecutiveMisses = 0;
    _clearHint();

    if (mounted) {
      setState(() {});
    }
  }

  // =====================================================
  // KART SEÇ
  // =====================================================

  Future<void> selectCard(int index) async {
    if (!ensurePlayTimeLeft()) return;

    if (checking || revealed[index] || matched[index]) return;

    setState(() {
      revealed[index] = true;
    });

    // İlk kart
    if (firstIndex == -1) {
      firstIndex = index;
      _offerHintFor(index);
      return;
    }

    // İkinci kart
    _clearHint();
    //
    // Everything the wait below needs is captured first. "Yeni Oyun" stays
    // tappable during the wait and resets firstIndex to -1, so reading the
    // fields afterwards used to crash on cards[-1].
    final first = firstIndex;
    final second = index;
    final board = _boardGeneration;
    final isMatch = cards[first] == cards[second];

    secondIndex = second;
    moves++;
    checking = true;

    await Future.delayed(isMatch ? matchHold : mismatchHoldFor(ageBand));

    // The board was rebuilt while this pair was on show: these indices
    // belong to a board that no longer exists.
    if (!mounted || board != _boardGeneration) return;

    // Eşleşti
    if (isMatch) {
      SoundManager.playCorrect();
      setState(() {
        matched[first] = true;
        matched[second] = true;

        score += (levelIndex + 1) * 10;
        if (score >= 50) {
          AchievementManager.unlock('mind_master');
        }

        firstIndex = -1;
        secondIndex = -1;

        checking = false;
        _consecutiveMisses = 0;
      });

      // Bütün kartlar eşleşti
      if (matched.every((item) => item)) {
        final outcome = _roundCleared();
        AchievementManager.unlock('first_step');
        AchievementManager.markGamePlayed(game);
        _showGameFinishedDialog(outcome);
      }
    }
    // Eşleşmedi
    else {
      SoundManager.playWrong();
      setState(() {
        revealed[first] = false;
        revealed[second] = false;

        firstIndex = -1;
        secondIndex = -1;

        checking = false;
        _consecutiveMisses++;
      });
    }
  }

  @override
  void dispose() {
    _hintPulse.dispose();
    super.dispose();
  }

  /// Points out the partner of the card just turned over, once the child has
  /// lost several pairs in a row.
  ///
  /// The partner pulses until the next tap; nothing is turned over for the
  /// child and the move still counts. Without it the only way out of a run
  /// of misses was to keep guessing.
  void _offerHintFor(int index) {
    if (_consecutiveMisses < _hintAfterMisses) return;

    final after = cards.indexWhere(
      (symbol) => symbol == cards[index],
      index + 1,
    );

    final partner = after != -1
        ? after
        : cards.indexWhere((s) => s == cards[index]);

    if (partner == -1 || partner == index || matched[partner]) return;

    setState(() => hintIndex = partner);
    _hintPulse.repeat(reverse: true);
  }

  void _clearHint() {
    _hintPulse
      ..stop()
      ..value = 0;

    if (hintIndex != -1) setState(() => hintIndex = -1);
  }

  // =====================================================
  // OYUN TAMAMLANDI
  // =====================================================

  void _showGameFinishedDialog(RoundOutcome outcome) {
    if (finishDialogShown || timeUpDialogShown) return;

    finishDialogShown = true;

    final usedTime = gameTimer.usedSeconds;

    showLadderRoundDialog(
      context: context,
      palette: palette,
      outcome: outcome,
      ladder: memoryLadder,
      levelIndex: levelIndex,
      roundsCleared: roundsCleared,
      levelUpMessage: 'Artık ${level.cards} kartla oynuyorsun! ✨',
      masteredMessage: 'Son bölümdesin, hafızan çok güçlü 🧠',
      flair: '🧠✨',
      results: [
        GameResultBox(
          palette: palette,
          emoji: '⭐',
          title: 'Puan',
          value: '$score',
        ),
        GameResultBox(
          palette: palette,
          emoji: '🎯',
          title: 'Hamle',
          value: '$moves',
        ),
        GameResultBox(
          palette: palette,
          emoji: '⏱️',
          title: 'Süre',
          value: formatSeconds(usedTime),
        ),
      ],
      onNextRound: () {
        // The clock resumes by itself once the dialog is gone. If the day
        // is already used up, say so instead of dealing a board that
        // cannot be played.
        if (!ensurePlayTimeLeft()) return;

        setState(startGame);
      },
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: GameAppBarTitle(game: game),
        centerTitle: true,
        actions: [GameHelpButton(game: game)],
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),

      body: SafeArea(
        child: Column(
          children: [
            // =========================================
            // BİLGİ KUTULARI
            // =========================================

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  InfoBox(emoji: '⭐', title: 'Puan', value: '$score'),

                  const SizedBox(width: 8),

                  InfoBox(emoji: '🎯', title: 'Hamle', value: '$moves'),

                  const SizedBox(width: 8),

                  InfoBox(
                    emoji: '⏱️',
                    title: 'Kalan',
                    value: gameTimer.formattedRemaining,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // =========================================
            // BÖLÜM İLERLEMESİ
            // =========================================
            //
            // Cocuk nerede oldugunu ve bir sonraki basamaga ne kadar
            // kaldigini yaziyi okumadan gorsun diye: bolum numarasi ve
            // her temiz tur icin bir nokta.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      '${levelIndex + 1}. Bölüm',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: game.palette.value,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ...List.generate(level.roundsToAdvance, (i) {
                      final done = i < roundsCleared;

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          done
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 22,
                          color: done
                              ? Brand.sun
                              : game.palette.value.withValues(alpha: 0.35),
                        ),
                      );
                    }),
                    const SizedBox(width: 14),
                    Text(
                      '${cards.length} kart',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: game.palette.label,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // =========================================
            // SÜRE İLERLEME ÇUBUĞU
            // =========================================
            GameTimeBar(
              palette: palette,
              progress: timeProgress,
              remaining: gameTimer.formattedRemaining,
            ),
            const SizedBox(height: 12),

            // =========================================
            // KARTLAR
            // =========================================
            Expanded(
              child: Padding(
                padding: _boardPadding,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Tahta her zaman ekrana tam sigar: sutun sayisi ve
                    // en-boy orani eldeki kutuya gore hesaplanir, kaydirma
                    // yok. Eskiden 3 sutun sabitti ve son sira tasiyordu.
                    final grid = fitGrid(
                      cards.length,
                      constraints.biggest,
                      _cardGap,
                    );

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),

                      itemCount: cards.length,

                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: grid.columns,
                        crossAxisSpacing: _cardGap,
                        mainAxisSpacing: _cardGap,
                        childAspectRatio: grid.aspectRatio,
                      ),

                      itemBuilder: (_, index) {
                        final show = revealed[index] || matched[index];

                        return Semantics(
                          button: true,
                          enabled: !matched[index],
                          // The card's face, or that it is still face down.
                          // Without this a screen reader found nothing here.
                          label: show ? cards[index] : 'Kapalı kart',
                          excludeSemantics: true,
                          onTap: matched[index]
                              ? null
                              : () => selectCard(index),
                          child: AnimatedBuilder(
                            animation: _hintPulse,
                            builder: (context, child) => Transform.scale(
                              // The pointed-out partner breathes until the
                              // next tap.
                              scale: index == hintIndex
                                  ? 1 + 0.07 * _hintPulse.value
                                  : 1,
                              child: child,
                            ),
                            child: GestureDetector(
                              onTap: () => selectCard(index),

                              child: AnimatedScale(
                                scale: matched[index] ? 0.94 : 1.0,

                                duration: const Duration(milliseconds: 180),

                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),

                                  decoration: BoxDecoration(
                                    gradient: matched[index]
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFFD8F3DC),
                                              Color(0xFFEAF9ED),
                                            ],
                                          )
                                        : show
                                        ? const LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Color(0xFFF9F5FF),
                                            ],
                                          )
                                        : const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF50E263),
                                              Color(0xFF23D83E),
                                            ],
                                          ),

                                    borderRadius: BorderRadius.circular(20),

                                    border: Border.all(
                                      color: matched[index]
                                          ? const Color(0xFF9ED2A6)
                                          : Colors.transparent,
                                      width: 2,
                                    ),

                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),

                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),

                                      transitionBuilder: (child, animation) {
                                        return ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        );
                                      },

                                      child: Text(
                                        show ? cards[index] : '?',

                                        key: ValueKey(
                                          show ? cards[index] : '?',
                                        ),

                                        style: TextStyle(
                                          fontSize: show ? 38 : 32,
                                          fontWeight: FontWeight.bold,
                                          color: show
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
