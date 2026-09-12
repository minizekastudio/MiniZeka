import 'dart:math';

import 'package:flutter/material.dart';

import '../achievement_manager.dart';
import '../game_id.dart';
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
      cards.isNotEmpty &&
      !matched.every((item) => item) &&
      !finishDialogShown;

  @override
  void onChildAgeLoaded() => startGame();

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

  void startGame() {
    int pairCount;

    if (childAge <= 5) {
      // 4–5 yaş → 4 çift
      pairCount = 4;
    } else if (childAge <= 7) {
      // 6–7 yaş → 5 çift
      pairCount = 5;
    } else if (childAge <= 9) {
      // 8–9 yaş → 6 çift
      pairCount = 6;
    } else {
      // 10–12 yaş → 8 çift
      pairCount = 8;
    }

    final selectedSymbols =
    List<String>.from(symbols)..shuffle(Random());

    final selectedPairs =
    selectedSymbols.take(pairCount).toList();

    cards = [
      ...selectedPairs,
      ...selectedPairs,
    ];

    cards.shuffle(Random());

    revealed = List<bool>.filled(
      cards.length,
      false,
    );

    matched = List<bool>.filled(
      cards.length,
      false,
    );

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
    if (gameTimer.timeIsOver ||
        checking ||
        revealed[index] ||
        matched[index]) {
      return;
    }

    setState(() {
      revealed[index] = true;
    });

    // İlk kart
    if (firstIndex == -1) {
      firstIndex = index;
      return;
    }

    // İkinci kart
    secondIndex = index;
    moves++;
    checking = true;

    await Future.delayed(
      const Duration(milliseconds: 550),
    );

    if (!mounted) return;

    // Eşleşti
    if (cards[firstIndex] == cards[secondIndex]) {
      SoundManager.playCorrect();
      setState(() {
        matched[firstIndex] = true;
        matched[secondIndex] = true;

        score += 10;
        if (score >= 50) {
          AchievementManager.unlock('mind_master');
        }

        firstIndex = -1;
        secondIndex = -1;

        checking = false;
      });

      // Bütün kartlar eşleşti
      if (matched.every((item) => item)) {
        AchievementManager.unlock('first_step');
        AchievementManager.markGamePlayed('memory');
        _showGameFinishedDialog();
      }
    }

    // Eşleşmedi
    else {
      SoundManager.playWrong();
      setState(() {
        revealed[firstIndex] = false;
        revealed[secondIndex] = false;

        firstIndex = -1;
        secondIndex = -1;

        checking = false;
      });
    }
  }

  // =====================================================
  // OYUN TAMAMLANDI
  // =====================================================

  void _showGameFinishedDialog() {
    if (finishDialogShown || timeUpDialogShown) return;

    finishDialogShown = true;

    final usedTime = gameTimer.usedSeconds;

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
                  decoration: const BoxDecoration(
                    color: Color(0xFFD8FFDC),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '🎉',
                      style: TextStyle(
                        fontSize: 46,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Harika İş Çıkardın!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF20813A),
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Tüm kartların eşlerini buldun! 🧠✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                      value: formatSeconds(
                        usedTime,
                      ),
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

                      setState(() {
                        startGame();
                      });

                      if (!gameTimer.timeIsOver) {
                        gameTimer.start();
                      }
                    },
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                    label: const Text(
                      'Tekrar Oyna',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF23D83E),
                      foregroundColor:
                      Colors.white,
                      elevation: 0,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          17,
                        ),
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
                    style: TextStyle(
                      color: Color(0xFF21CA3A),
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
        actions: [
          GameHelpButton(game: game),
        ],
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
              padding:
              const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: Row(
                children: [
                  InfoBox(
                    emoji: '⭐',
                    title: 'Puan',
                    value: '$score',
                  ),

                  const SizedBox(width: 8),

                  InfoBox(
                    emoji: '🎯',
                    title: 'Hamle',
                    value: '$moves',
                  ),

                  const SizedBox(width: 8),

                  InfoBox(
                    emoji: '⏱️',
                    title: 'Kalan',
                    value:
                    gameTimer
                        .formattedRemaining,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // =========================================
            // SÜRE İLERLEME ÇUBUĞU
            // =========================================

            Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                    children: [
                      const Text(
                        '⏱️ Günlük oyun süresi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          Color(0xFF21CA3A),
                        ),
                      ),
                      Text(
                        gameTimer
                            .formattedRemaining,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          Color(0xFF2AA74B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                    child:
                    LinearProgressIndicator(
                      value: timeProgress,
                      minHeight: 7,
                      backgroundColor:
                      const Color(
                        0xFFD1FAD5,
                      ),
                      valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                        timeProgress < 0.2
                            ? const Color(
                          0xFFD47A7A,
                        )
                            : const Color(
                          0xFF23D83E,
                        ),
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
              child: GridView.builder(
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  4,
                  18,
                  12,
                ),

                itemCount: cards.length,

                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),

                itemBuilder: (_, index) {
                  final show =
                      revealed[index] ||
                          matched[index];

                  return GestureDetector(
                    onTap: () =>
                        selectCard(index),

                    child:
                    AnimatedScale(
                      scale:
                      matched[index]
                          ? 0.94
                          : 1.0,

                      duration:
                      const Duration(
                        milliseconds: 180,
                      ),

                      child:
                      AnimatedContainer(
                        duration:
                        const Duration(
                          milliseconds: 220,
                        ),

                        decoration:
                        BoxDecoration(
                          gradient:
                          matched[index]
                              ? const LinearGradient(
                            colors: [
                              Color(
                                0xFFD8F3DC,
                              ),
                              Color(
                                0xFFEAF9ED,
                              ),
                            ],
                          )
                              : show
                              ? const LinearGradient(
                            colors: [
                              Colors.white,
                              Color(
                                0xFFF9F5FF,
                              ),
                            ],
                          )
                              : const LinearGradient(
                            begin:
                            Alignment.topLeft,
                            end:
                            Alignment.bottomRight,
                            colors: [
                              Color(
                                0xFF50E263,
                              ),
                              Color(
                                0xFF23D83E,
                              ),
                            ],
                          ),

                          borderRadius:
                          BorderRadius.circular(
                            20,
                          ),

                          border:
                          Border.all(
                            color: matched[index]
                                ? const Color(
                              0xFF9ED2A6,
                            )
                                : Colors.transparent,
                            width: 2,
                          ),

                          boxShadow:
                          const [
                            BoxShadow(
                              color:
                              Colors.black12,
                              blurRadius: 6,
                              offset:
                              Offset(0, 3),
                            ),
                          ],
                        ),

                        child: Center(
                          child:
                          AnimatedSwitcher(
                            duration:
                            const Duration(
                              milliseconds: 180,
                            ),

                            transitionBuilder:
                                (
                                child,
                                animation,
                                ) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },

                            child: Text(
                              show
                                  ? cards[index]
                                  : '?',

                              key: ValueKey(
                                show
                                    ? cards[index]
                                    : '?',
                              ),

                              style:
                              TextStyle(
                                fontSize:
                                show
                                    ? 38
                                    : 32,
                                fontWeight:
                                FontWeight
                                    .bold,
                                color: show
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // =========================================
            // YENİ OYUN
            // =========================================

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                18,
                0,
                18,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child:
                OutlinedButton.icon(
                  onPressed: () {
                    if (gameTimer
                        .timeIsOver) {
                      return;
                    }

                    setState(() {
                      startGame();
                    });
                  },

                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),

                  label: const Text(
                    'Yeni Oyun',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor:
                    const Color(
                      0xFF23D83E,
                    ),
                    side:
                    const BorderSide(
                      color: Color(
                        0xFF23D83E,
                      ),
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        17,
                      ),
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
