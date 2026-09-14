import 'dart:math';

import 'package:flutter/material.dart';

import '../achievement_manager.dart';
import '../game_id.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage_keys.dart';
import '../app_theme.dart';
import '../difficulty.dart';
import '../game_kit.dart';
import '../sound_manager.dart';

// =====================================================
// 1 - HAFIZA OYUNU
// =====================================================

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> with GameSessionMixin {
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

  final List<String> symbols = [
    '🍎',
    '⭐',
    '🚀',
    '🐱',
    '🌈',
    '⚽',
    '🐶',
    '🍉',
    '🌸',
    '🦋',
    '🚗',
    '🐼',
    '🍓',
    '🌞',
    '🎈',
    '🐸',
  ];

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

  static const double _cardGap = 12;

  /// Kartlari ekrana tam sigdiran izgara.
  ///
  /// Once satiri tam dolduran sutun sayilari denenir (yarim sira kalmasin),
  /// aralarindan kartin en buyuk gorundugu secilir. Hicbiri tam bolmuyorsa
  /// en iyi gorunen kullanilir. En-boy orani kutuya birebir oturacak sekilde
  /// hesaplandigi icin kaydirmaya gerek kalmiyor.
  ({int columns, double aspectRatio}) _fitGrid(
    int count,
    Size box,
    double gap,
  ) {
    if (count <= 0 || box.width <= 0 || box.height <= 0) {
      return (columns: 2, aspectRatio: 1);
    }

    var bestColumns = 2;
    var bestSide = -1.0;
    var sawExact = false;

    for (var columns = 2; columns <= 5; columns++) {
      if (columns > count) break;

      final rows = (count / columns).ceil();
      final exact = count % columns == 0;

      // Tam bolen bir secenek bulunduysa artik yalnizca onlar yarisir.
      if (sawExact && !exact) continue;

      final cardWidth = (box.width - gap * (columns - 1)) / columns;
      final cardHeight = (box.height - gap * (rows - 1)) / rows;
      final side = cardWidth < cardHeight ? cardWidth : cardHeight;

      if (exact && !sawExact) {
        sawExact = true;
        bestSide = -1;
      }

      if (side > bestSide) {
        bestSide = side;
        bestColumns = columns;
      }
    }

    final rows = (count / bestColumns).ceil();
    final cardWidth = (box.width - gap * (bestColumns - 1)) / bestColumns;
    final cardHeight = (box.height - gap * (rows - 1)) / rows;

    final ratio = cardHeight > 0 ? cardWidth / cardHeight : 1.0;

    return (columns: bestColumns, aspectRatio: ratio.clamp(0.5, 2.0));
  }

  void startGame() {
    _boardGeneration++;

    // Kart sayisi merdivenden; tahta ortasinda degismesin diye yalnizca
    // yeni tur kurulurken okunuyor.
    final pairCount = level.cards ~/ 2;

    final selectedSymbols = List<String>.from(symbols)..shuffle(Random());

    final selectedPairs = selectedSymbols.take(pairCount).toList();

    cards = [...selectedPairs, ...selectedPairs];

    cards.shuffle(Random());

    revealed = List<bool>.filled(cards.length, false);

    matched = List<bool>.filled(cards.length, false);

    firstIndex = -1;
    secondIndex = -1;

    score = 0;
    moves = 0;

    checking = false;
    finishDialogShown = false;
    timeUpDialogShown = false;

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
      return;
    }

    // İkinci kart
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
      });

      // Bütün kartlar eşleşti
      if (matched.every((item) => item)) {
        final outcome = _roundCleared();
        AchievementManager.unlock('first_step');
        AchievementManager.markGamePlayed('memory');
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
      });
    }
  }

  // =====================================================
  // OYUN TAMAMLANDI
  // =====================================================

  /// Ayni bolumde kalindiysa bir sonraki basamaga ne kadar kaldigi.
  String _roundsLeftMessage() {
    final left = level.roundsToAdvance - roundsCleared;
    if (left <= 0) return 'Tüm kartların eşlerini buldun! 🧠✨';
    if (left == 1) return 'Yeni bölüme bir tur kaldı! 🧠✨';
    return 'Yeni bölüme $left tur kaldı! 🧠✨';
  }

  /// Merdivendeki yeri yazidan once gosteren gorsel.
  Widget _ladderVisual(RoundOutcome outcome) {
    if (outcome == RoundOutcome.levelUp) {
      // levelIndex zaten arttirildi: eski bolum = levelIndex.
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _levelChip('$levelIndex. Bölüm', passed: true),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 24,
              color: Color(0xFF21CA3A),
            ),
          ),
          _levelChip('${levelIndex + 1}. Bölüm', passed: false),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(level.roundsToAdvance, (i) {
        final done = i < roundsCleared;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            done ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 32,
            color: done ? Brand.sun : const Color(0xFFBFE6C6),
          ),
        );
      }),
    );
  }

  Widget _levelChip(String label, {required bool passed}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: passed ? const Color(0xFFEDF7EF) : const Color(0xFF23D83E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: passed ? const Color(0xFF8FBF9A) : Colors.white,
        ),
      ),
    );
  }

  void _showGameFinishedDialog(RoundOutcome outcome) {
    if (finishDialogShown || timeUpDialogShown) return;

    finishDialogShown = true;

    final usedTime = gameTimer.usedSeconds;

    // Cocuk okuyamiyor olabilir: durumu once emoji, renk ve yildizlar
    // anlatir, metin yalnizca destekler. Bolum atlandiginda "Tekrar Oyna"
    // yanlis olurdu, ayni tahta bir daha gelmiyor.
    final (
      String emoji,
      Color ring,
      String title,
      String message,
      String action,
      IconData actionIcon,
    ) shown = switch (outcome) {
      RoundOutcome.levelUp => (
          '🚀',
          const Color(0xFFFFF1CC),
          'Yeni Bölüm Açıldı!',
          'Artık ${level.cards} kartla oynuyorsun! ✨',
          'Sonraki Bölüm',
          Icons.arrow_forward_rounded,
        ),
      RoundOutcome.mastered => (
          '🏆',
          const Color(0xFFFFF1CC),
          'Tüm Bölümleri Bitirdin!',
          'Son bölümdesin, hafızan çok güçlü 🧠',
          'Yeni Tur',
          Icons.refresh_rounded,
        ),
      RoundOutcome.progress => (
          '🎉',
          const Color(0xFFD8FFDC),
          'Harika İş Çıkardın!',
          _roundsLeftMessage(),
          'Yeni Tur',
          Icons.play_arrow_rounded,
        ),
    };

    showDialog(
      context: context,
      barrierDismissible: false,
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
                // Emoji
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: shown.$2,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      shown.$1,
                      style: const TextStyle(fontSize: 46),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  shown.$3,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF20813A),
                  ),
                ),

                const SizedBox(height: 14),

                // Merdivendeki yer: atlandiysa eski -> yeni bolum,
                // atlanmadiysa dolan yildizlar.
                _ladderVisual(outcome),

                const SizedBox(height: 12),

                Text(
                  shown.$4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF21CA3A),
                  ),
                ),

                const SizedBox(height: 20),

                // Sonuçlar
                Row(
                  children: [
                    GameResultBox(
                      palette: GamePalette.memory,
                      emoji: '⭐',
                      title: 'Puan',
                      value: '$score',
                    ),
                    const SizedBox(width: 8),
                    GameResultBox(
                      palette: GamePalette.memory,
                      emoji: '🎯',
                      title: 'Hamle',
                      value: '$moves',
                    ),
                    const SizedBox(width: 8),
                    GameResultBox(
                      palette: GamePalette.memory,
                      emoji: '⏱️',
                      title: 'Süre',
                      value: formatSeconds(usedTime),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      // The clock resumes by itself once this dialog is
                      // gone. If the day is already used up, say so instead
                      // of dealing a board that cannot be played.
                      if (!ensurePlayTimeLeft()) return;

                      setState(startGame);
                    },
                    icon: Icon(shown.$6),
                    label: Text(
                      shown.$5,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF23D83E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Oyundan Çık',
                    style: TextStyle(color: Color(0xFF21CA3A)),
                  ),
                ),
              ],
            ),
          ),
        );
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: const Text(
                          '⏱️ Günlük oyun süresi',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF21CA3A),
                          ),
                        ),
                      ),
                      Text(
                        gameTimer.formattedRemaining,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2AA74B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: timeProgress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFD1FAD5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        timeProgress < 0.2
                            ? const Color(0xFFD47A7A)
                            : const Color(0xFF23D83E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // =========================================
            // KARTLAR
            // =========================================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Tahta her zaman ekrana tam sigar: sutun sayisi ve
                    // en-boy orani eldeki kutuya gore hesaplanir, kaydirma
                    // yok. Eskiden 3 sutun sabitti ve son sira tasiyordu.
                    final grid = _fitGrid(
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

                        return GestureDetector(
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
                                  duration: const Duration(milliseconds: 180),

                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    );
                                  },

                                  child: Text(
                                    show ? cards[index] : '?',

                                    key: ValueKey(show ? cards[index] : '?'),

                                    style: TextStyle(
                                      fontSize: show ? 38 : 32,
                                      fontWeight: FontWeight.bold,
                                      color: show ? Colors.black : Colors.white,
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

            // =========================================
            // YENİ OYUN
            // =========================================
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (!ensurePlayTimeLeft()) return;

                    setState(startGame);
                  },

                  icon: const Icon(Icons.refresh_rounded),

                  label: const Text(
                    'Yeni Oyun',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF23D83E),
                    side: const BorderSide(color: Color(0xFF23D83E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
