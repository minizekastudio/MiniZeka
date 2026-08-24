import 'achievements.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'parent_login.dart';
import 'game_timer.dart';
import 'achievement_manager.dart';
import 'sound_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';
import 'age_selection.dart';
import 'home_page.dart';
import 'app_theme.dart';
import 'theme_manager.dart';




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs =
  await SharedPreferences.getInstance();

  final isDark =
      prefs.getBool('dark_mode') ?? false;

  ThemeManager.themeNotifier.value = isDark
      ? ThemeMode.dark
      : ThemeMode.light;

  runApp(const MiniZekaApp());
}

// =====================================================
// UYGULAMA
// =====================================================

class MiniZekaApp extends StatelessWidget {
const MiniZekaApp({super.key});

@override
Widget build(BuildContext context) {
return ValueListenableBuilder<ThemeMode>(
valueListenable: ThemeManager.themeNotifier,
builder: (context, themeMode, child) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'MiniZeka',
  theme: MiniZekaTheme.lightTheme,

  darkTheme: MiniZekaTheme.darkTheme,

  themeMode: themeMode,
  home: Builder(
    builder: (context) {
      return RoleSelectionPage(
        onChildTap: () async {
          final prefs = await SharedPreferences.getInstance();

          final childAge = prefs.getInt('child_age');

          if (childAge == null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AgeSelectionPage(
                  onAgeSelected: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomePage(
                          onAchievementsTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AchievementsPage(),
                              ),
                            );
                          },

                          onMemoryTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MemoryGame(),
                              ),
                            );
                          },

                          onAttentionTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AttentionGame(),
                              ),
                            );
                          },

                          onMathTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MathGame(),
                              ),
                            );
                          },

                          onShapeTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ShapeGame(),
                              ),
                            );
                          },

                          onLogicTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LogicGame(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HomePage(
                  onAchievementsTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AchievementsPage(),
                      ),
                    );
                  },

                  onMemoryTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MemoryGame(),
                      ),
                    );
                  },

                  onAttentionTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AttentionGame(),
                      ),
                    );
                  },

                  onMathTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MathGame(),
                      ),
                    );
                  },

                  onShapeTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ShapeGame(),
                      ),
                    );
                  },

                  onLogicTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LogicGame(),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        },
        onParentTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ParentLoginPage(),
            ),
          );
        },
      );
    },
  ),
);
},
);
}
}

// =====================================================
// ANA SAYFA
// =====================================================



// =====================================================
// 1 - HAFIZA OYUNU
// =====================================================

// =====================================================
// 1 - HAFIZA OYUNU
// =====================================================

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  late GameTimerController gameTimer;

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

  late List<String> cards;
  List<bool> revealed = [];
  List<bool> matched = [];

  int firstIndex = -1;
  int secondIndex = -1;

  int score = 0;
  int moves = 0;
  int childAge = 0;

  bool checking = false;
  bool finishDialogShown = false;

  @override
  void initState() {
    super.initState();

    gameTimer = GameTimerController(
      gameName: 'Hafıza Oyunu',
      allowedMinutes: 10,
    );

    gameTimer.addListener(_timerChanged);

    _loadChildAge();
    _initializeTimer();
  }

  Future<void> _loadChildAge() async {
    final prefs = await SharedPreferences.getInstance();

    final savedAge = prefs.getInt('child_age') ?? 9;

    if (!mounted) return;

    setState(() {
      childAge = savedAge;

      startGame();
    });
  }

  void _timerChanged() {
    if (!mounted) return;

    setState(() {});

    if (gameTimer.timeIsOver &&
        !finishDialogShown &&
        cards.isNotEmpty &&
        !matched.every((item) => item)) {
      finishDialogShown = true;
      _showTimeFinishedDialog();
    }
  }

  Future<void> _initializeTimer() async {
    await gameTimer.load();

    if (!mounted) return;

    setState(() {});

    if (!gameTimer.timeIsOver) {
      gameTimer.start();
    } else {
      finishDialogShown = true;

      Future.delayed(
        const Duration(milliseconds: 300),
            () {
          if (mounted) {
            _showTimeFinishedDialog();
          }
        },
      );
    }
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
    if (finishDialogShown) return;

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
                    color: Color(0xFFE9D8FF),
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
                    color: Color(0xFF51376A),
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Tüm kartların eşlerini buldun! 🧠✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF776A7A),
                  ),
                ),

                const SizedBox(height: 20),

                // Sonuçlar
                Row(
                  children: [
                    _resultBox(
                      emoji: '⭐',
                      title: 'Puan',
                      value: '$score',
                    ),
                    const SizedBox(width: 8),
                    _resultBox(
                      emoji: '🎯',
                      title: 'Hamle',
                      value: '$moves',
                    ),
                    const SizedBox(width: 8),
                    _resultBox(
                      emoji: '⏱️',
                      title: 'Süre',
                      value: _formatSeconds(
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF7653A8),
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
                      color: Color(0xFF776A7A),
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
  // SÜRE BİTTİ
  // =====================================================

  void _showTimeFinishedDialog() {
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
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE8E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '⏰',
                      style: TextStyle(
                        fontSize: 43,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Bugünkü Süren Doldu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF51376A),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Hafıza oyunu için belirlenen günlük süreyi kullandın. 🌙',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF776A7A),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4ECFA),
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                  child: Text(
                    '⭐ Puanın: $score',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF63448D),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF7653A8),
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
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        fontSize: 16,
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

  // =====================================================
  // SONUÇ KUTUSU
  // =====================================================

  Widget _resultBox({
    required String emoji,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF4ECFA),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF776A7A),
              ),
            ),

            const SizedBox(height: 2),

            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF63448D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // SÜRE FORMAT
  // =====================================================

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    return '$minutes:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  // =====================================================
  // TIMER İLERLEME ORANI
  // =====================================================

  double get _timeProgress {
    if (gameTimer.allowedSeconds <= 0) {
      return 0;
    }

    return (
        gameTimer.remainingSeconds /
            gameTimer.allowedSeconds
    ).clamp(0.0, 1.0);
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          '🧠 Hafıza Oyunu',
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),

      body: SafeArea(
        child: Column(
          children: [
            // =========================================
            // OYUN BAŞLIK KARTI
            // =========================================

            Container(
              margin: const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                12,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient:
                const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE9D8FF),
                    Color(0xFFF2E8FF),
                  ],
                ),
                borderRadius:
                BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration:
                    const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '🧠',
                        style: TextStyle(
                          fontSize: 35,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 13),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kartların eşlerini bul! 🃏',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight:
                            FontWeight.w900,
                            color:
                            Color(0xFF51376A),
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          'Aynı iki kartı bulmaya çalış.',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                            Color(0xFF746778),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                          Color(0xFF776A7A),
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
                          Color(0xFF63448D),
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
                      value: _timeProgress,
                      minHeight: 7,
                      backgroundColor:
                      const Color(
                        0xFFE6DCEF,
                      ),
                      valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                        _timeProgress < 0.2
                            ? const Color(
                          0xFFD47A7A,
                        )
                            : const Color(
                          0xFF7653A8,
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
                                0xFF9A70C2,
                              ),
                              Color(
                                0xFF7653A8,
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
                      fontSize: 15,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor:
                    const Color(
                      0xFF7653A8,
                    ),
                    side:
                    const BorderSide(
                      color: Color(
                        0xFF7653A8,
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

  @override
  void dispose() {
    gameTimer.removeListener(
      _timerChanged,
    );

    gameTimer.dispose();

    super.dispose();
  }
}

// =====================================================
// 2 - DİKKAT OYUNU
// =====================================================

class AttentionGame extends StatefulWidget {
  const AttentionGame({super.key});

  @override
  State<AttentionGame> createState() => _AttentionGameState();
}

class _AttentionGameState extends State<AttentionGame> {
  late GameTimerController gameTimer;

  int level = 1;
  int question = 1;
  int score = 0;
  int differentIndex = 0;

  bool answered = false;
  bool timeDialogShown = false;
  bool finalDialogShown = false;

  final Random random = Random();

  final List<String> symbols = [
    '🍎',
    '🍏',
    '🔵',
    '🟢',
    '⭐',
    '🌟',
    '🐶',
    '🐱',
    '🚗',
    '🚕',
    '🌈',
    '☀️',
    '🍓',
    '🍉',
    '⚽',
    '🏀',
  ];

  final Set<String> usedQuestions = {};

  late List<String> items;
  int childAge = 0;

  @override
  void initState() {
    super.initState();

    gameTimer = GameTimerController(
      gameName: 'Dikkat Oyunu',
      allowedMinutes: 15,
    );

    gameTimer.addListener(_timerChanged);

    _loadChildAge();
    _initializeTimer();
  }

  Future<void> _loadChildAge() async {
    final prefs = await SharedPreferences.getInstance();

    final savedAge = prefs.getInt('child_age') ?? 9;

    if (!mounted) return;

    setState(() {
      childAge = savedAge;

      if (childAge <= 5) {
        level = 1;
      } else if (childAge <= 7) {
        level = 1;
      } else if (childAge <= 9) {
        level = 2;
      } else {
        level = 3;
      }

      createQuestion();
    });
  }

  // =====================================================
  // TIMER
  // =====================================================

  void _timerChanged() {
    if (!mounted) return;

    setState(() {});

    if (gameTimer.timeIsOver &&
        !timeDialogShown &&
        !finalDialogShown) {
      timeDialogShown = true;
      _showTimeFinishedDialog();
    }
  }

  Future<void> _initializeTimer() async {
    await gameTimer.load();

    if (!mounted) return;

    setState(() {});

    if (!gameTimer.timeIsOver) {
      gameTimer.start();
    } else {
      timeDialogShown = true;

      Future.delayed(
        const Duration(milliseconds: 300),
            () {
          if (mounted) {
            _showTimeFinishedDialog();
          }
        },
      );
    }
  }

  // =====================================================
  // SORU OLUŞTUR
  // =====================================================

  void createQuestion() {
    int itemCount;

    // Seviyeye göre kaç sembol gösterileceğini belirle
    if (level == 1) {
      itemCount = 9;
    } else if (level == 2) {
      itemCount = 12;
    } else {
      itemCount = 16;
    }

    String normalSymbol;
    String differentSymbol;
    int newDifferentIndex;
    String questionKey;

    // Aynı sorunun tekrar etmesini engelle
    do {
      // Normal sembolü rastgele seç
      normalSymbol =
      symbols[random.nextInt(symbols.length)];

      // Farklı sembolü rastgele seç
      do {
        differentSymbol =
        symbols[random.nextInt(symbols.length)];
      } while (differentSymbol == normalSymbol);

      // Farklı sembolün yerini rastgele belirle
      newDifferentIndex =
          random.nextInt(itemCount);

      // Sorunun benzersiz anahtarını oluştur
      questionKey =
      '$level-$normalSymbol-$differentSymbol-$newDifferentIndex';

    } while (usedQuestions.contains(questionKey));

    // Soruyu kaydet
    usedQuestions.add(questionKey);

    // Önce bütün kutuları normal sembolle doldur
    items = List<String>.filled(
      itemCount,
      normalSymbol,
    );

    // Rastgele seçilen konuma farklı sembolü koy
    items[newDifferentIndex] =
        differentSymbol;

    // Doğru cevabın indeksini kaydet
    differentIndex = newDifferentIndex;

    // Yeni soruda cevap verilmedi
    answered = false;
  }

  // =====================================================
  // CEVAP
  // =====================================================

  void selectItem(int index) {
    if (gameTimer.timeIsOver ||
        answered ||
        finalDialogShown) {
      return;
    }

    setState(() {
      answered = true;
    });

    final correct = index == differentIndex;

    if (correct) {
      score += level * 10;
    }

    _showAnswerDialog(correct);
  }

  // =====================================================
  // DOĞRU / YANLIŞ SONUÇ
  // =====================================================

  void _showAnswerDialog(bool correct) {
    final earnedScore = correct ? level * 10 : 0;
    if (correct) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playWrong();
    }

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
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: correct
                        ? const Color(0xFFE4F7E7)
                        : const Color(0xFFFFE7E7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      correct ? '🎉' : '💭',
                      style: const TextStyle(
                        fontSize: 42,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  correct
                      ? 'Harika! 🎯'
                      : 'Bu sefer olmadı!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF51376A),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  correct
                      ? 'Farklı olanı doğru buldun!'
                      : 'Bir sonraki soruda daha dikkatli ol!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF776A7A),
                  ),
                ),

                const SizedBox(height: 18),

                if (correct)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4ECFA),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '⭐ +$earnedScore Puan',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF63448D),
                      ),
                    ),
                  ),

                if (correct)
                  const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      if (question == 3) {
                        _showFinalResult();
                      } else {
                        setState(() {
                          question++;
                          level++;
                          createQuestion();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE88B42),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: Text(
                      question == 3
                          ? 'Sonucu Gör'
                          : 'Devam Et',
                      style: const TextStyle(
                        fontSize: 16,
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

  // =====================================================
  // OYUN TAMAMLANDI
  // =====================================================

  Future<void> _showFinalResult() async {
    if (finalDialogShown) return;

    finalDialogShown = true;
    await AchievementManager.unlock('attention_master');
    await AchievementManager.unlock('first_step');
    await AchievementManager.unlock('attention_master');
    AchievementManager.markGamePlayed('attention');

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
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE1C4),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '🎉',
                      style: TextStyle(
                        fontSize: 45,
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
                    color: Color(0xFF51376A),
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Dikkat testini tamamladın! 👀✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF776A7A),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    _resultBox(
                      emoji: '⭐',
                      title: 'Puan',
                      value: '$score',
                    ),
                    const SizedBox(width: 8),
                    _resultBox(
                      emoji: '🎯',
                      title: 'Soru',
                      value: '3 / 3',
                    ),
                    const SizedBox(width: 8),
                    _resultBox(
                      emoji: '⏱️',
                      title: 'Süre',
                      value: _formatSeconds(
                        gameTimer.usedSeconds,
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

                      if (gameTimer.timeIsOver) {
                        Navigator.pop(context);
                        return;
                      }

                      setState(() {
                        level = 1;
                        question = 1;
                        score = 0;
                        finalDialogShown = false;
                        timeDialogShown = false;
                        createQuestion();
                      });

                      },
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                    label: const Text(
                      'Tekrar Oyna',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE88B42),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Oyundan Çık',
                    style: TextStyle(
                      color: Color(0xFF776A7A),
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
  // SÜRE BİTTİ
  // =====================================================

  void _showTimeFinishedDialog() {
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
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE8E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '⏰',
                      style: TextStyle(
                        fontSize: 43,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Bugünkü Süren Doldu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF51376A),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Dikkat oyunu için belirlenen günlük süreyi kullandın. 🌙',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF776A7A),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E4),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '⭐ Puanın: $score',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB96B29),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE88B42),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        fontSize: 16,
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

  // =====================================================
  // SONUÇ KUTUSU
  // =====================================================

  Widget _resultBox({
    required String emoji,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1E5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF776A7A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFFB96B29),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // SÜRE FORMAT
  // =====================================================

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    return '$minutes:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  // =====================================================
  // SÜRE İLERLEME
  // =====================================================

  double get _timeProgress {
    if (gameTimer.allowedSeconds <= 0) {
      return 0;
    }

    return (
        gameTimer.remainingSeconds /
            gameTimer.allowedSeconds
    ).clamp(0.0, 1.0);
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final title = level == 1
        ? '🟢 Kolay Seviye'
        : level == 2
        ? '🟡 Orta Seviye'
        : '🔴 Zor Seviye';

    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          '👀 Dikkat Oyunu',
        ),
        centerTitle: true,
        backgroundColor:
        Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),

      body: SafeArea(
        child: Column(
          children: [
            // =========================================
            // BAŞLIK KARTI
            // =========================================

            Container(
              margin: const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                12,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFE1C4),
                    Color(0xFFFFF0E0),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '👀',
                        style: TextStyle(
                          fontSize: 35,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF754B2A),
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Diğerlerinden farklı olanı bul!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF806D60),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // =========================================
            // BİLGİ KUTULARI
            // =========================================

            Padding(
              padding: const EdgeInsets.symmetric(
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
                    title: 'Soru',
                    value: '$question / 3',
                  ),

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
            // SÜRE ÇUBUĞU
            // =========================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '⏱️ Günlük oyun süresi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF806D60),
                        ),
                      ),
                      Text(
                        gameTimer.formattedRemaining,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB96B29),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _timeProgress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFF0DED0),
                      valueColor:
                      AlwaysStoppedAnimation<Color>(
                        _timeProgress < 0.2
                            ? const Color(0xFFD47A7A)
                            : const Color(0xFFE88B42),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // =========================================
            // OYUN ALANI
            // =========================================

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  5,
                  18,
                  15,
                ),
                itemCount: items.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (_, index) {
                  final isCorrect =
                      answered && index == differentIndex;

                  return GestureDetector(
                    onTap: () => selectItem(index),

                    child: AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 220,
                      ),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? const Color(0xFFD8F3DC)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius:
                        BorderRadius.circular(19),
                        border: Border.all(
                          color: isCorrect
                              ? const Color(0xFF70B77A)
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedScale(
                          scale: isCorrect ? 1.15 : 1.0,
                          duration: const Duration(
                            milliseconds: 200,
                          ),
                          child: Text(
                            items[index],
                            style: const TextStyle(
                              fontSize: 31,
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
            // ALT BİLGİ
            // =========================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                0,
                18,
                15,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text(
                      '💡',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        level == 1
                            ? 'İpucu: Farklı olan şekle dikkatlice bak!'
                            : level == 2
                            ? 'Biraz daha dikkatli ol! 👀'
                            : 'Son seviye! Gözlerini dört aç! 🔍',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF806D60),
                          fontWeight: FontWeight.w600,
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
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    gameTimer.removeListener(_timerChanged);
    gameTimer.dispose();

    super.dispose();
  }
}

// =====================================================
// 3 - MATEMATİK OYUNU
// =====================================================

class MathGame extends StatefulWidget {
  const MathGame({super.key});

  @override
  State<MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<MathGame> {
  late GameTimerController gameTimer;

  final Random random = Random();

  int level = 1;
  int question = 1;
  int score = 0;
  int childAge = 0;

  int first = 0;
  int second = 0;
  int correctAnswer = 0;

  List<int> options = [];

  // Aynı oyun içinde sorulan soruları tutar.
  final Set<String> usedQuestions = {};

  bool timeDialogShown = false;
  bool finalDialogShown = false;
  bool answering = false;

  @override
  void initState() {
    super.initState();

    gameTimer = GameTimerController(
      gameName: 'Matematik Oyunu',
      allowedMinutes: 20,
    );

    gameTimer.addListener(_timerChanged);

    _loadChildAge();
    _initializeTimer();
  }
  Future<void> _loadChildAge() async {
    final prefs = await SharedPreferences.getInstance();

    final savedAge = prefs.getInt('child_age') ?? 9;

    if (!mounted) return;

    setState(() {
      childAge = savedAge;

      if (childAge <= 5) {
        level = 1;
      } else if (childAge <= 7) {
        level = 1;
      } else if (childAge <= 9) {
        level = 2;
      } else {
        level = 3;
      }

      createQuestion();
    });
  }

  // =====================================================
  // TIMER
  // =====================================================

  void _timerChanged() {
    if (!mounted) return;

    setState(() {});

    if (gameTimer.timeIsOver &&
        !timeDialogShown &&
        !finalDialogShown) {
      timeDialogShown = true;
      _showTimeFinishedDialog();
    }
  }

  Future<void> _initializeTimer() async {
    await gameTimer.load();

    if (!mounted) return;

    setState(() {});

    if (!gameTimer.timeIsOver) {
      gameTimer.start();
    } else {
      timeDialogShown = true;

      Future.delayed(
        const Duration(milliseconds: 300),
            () {
          if (mounted) {
            _showTimeFinishedDialog();
          }
        },
      );
    }
  }

  // =====================================================
  // SORU ANAHTARI
  // =====================================================

  String _questionKey(int first, int second) {
    // 3 + 5 ile 5 + 3 aynı soru kabul edilir.
    final smaller = first < second ? first : second;
    final larger = first < second ? second : first;

    return '$smaller+$larger';
  }

  // =====================================================
  // SORU OLUŞTUR
  // =====================================================

  void createQuestion() {
    int newFirst = 0;
    int newSecond = 0;
    String newQuestionKey = '';

    do {
      if (childAge <= 5) {
        // 4-5 yaş
        newFirst = random.nextInt(5) + 1;
        newSecond = random.nextInt(5) + 1;
      } else if (childAge <= 7) {
        // 6-7 yaş
        newFirst = random.nextInt(10) + 1;
        newSecond = random.nextInt(10) + 1;
      } else if (childAge <= 9) {
        // 8-9 yaş
        newFirst = random.nextInt(15) + 1;
        newSecond = random.nextInt(12) + 1;
      } else {
        // 10-12 yaş
        newFirst = random.nextInt(20) + 5;
        newSecond = random.nextInt(15) + 1;
      }

      newQuestionKey = _questionKey(
        newFirst,
        newSecond,
      );
    } while (usedQuestions.contains(newQuestionKey));

    first = newFirst;
    second = newSecond;

    usedQuestions.add(newQuestionKey);

    correctAnswer = first + second;

    options = [
      correctAnswer,
      correctAnswer + 1,
      correctAnswer - 1,
      correctAnswer + 2,
    ].toSet().toList();

    while (options.length < 4) {
      final value =
          correctAnswer + random.nextInt(7) - 3;

      if (value >= 0 && !options.contains(value)) {
        options.add(value);
      }
    }

    options.shuffle();

    answering = false;
  }

  // =====================================================
  // CEVAP
  // =====================================================

  void answer(int value) {
    if (gameTimer.timeIsOver ||
        answering ||
        finalDialogShown) {
      return;
    }

    answering = true;

    final correct = value == correctAnswer;

    if (correct) {
      score += level * 10;
    }

    _showAnswerDialog(
      correct,
      value,
    );
  }

  // =====================================================
  // DOĞRU / YANLIŞ EKRANI
  // =====================================================

  void _showAnswerDialog(
      bool correct,
      int selectedAnswer,
      ) {
    final earnedScore =
    correct ? level * 10 : 0;

    if (correct) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playWrong();
    }

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
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: correct
                        ? const Color(0xFFE2F2FF)
                        : const Color(0xFFFFE7E7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      correct ? '🎉' : '💭',
                      style: const TextStyle(
                        fontSize: 42,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  correct
                      ? 'Harika! 🔢'
                      : 'Tekrar Dene! 💪',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3F6383),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  correct
                      ? 'Matematik sorusunu doğru çözdün!'
                      : 'Doğru cevap: $correctAnswer',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF6F7C87),
                  ),
                ),

                const SizedBox(height: 18),

                if (correct)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5FF),
                      borderRadius:
                      BorderRadius.circular(15),
                    ),
                    child: Text(
                      '⭐ +$earnedScore Puan',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4D91D0),
                      ),
                    ),
                  ),

                if (correct)
                  const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);

                      if (question == 5) {
                        await _showFinalResult();
                      } else {
                        setState(() {
                          question++;
                          updateLevel();
                          createQuestion();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF4D91D0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(17),
                      ),
                    ),
                    child: Text(
                      question == 5
                          ? 'Sonucu Gör'
                          : 'Sonraki Soru',
                      style: const TextStyle(
                        fontSize: 16,
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

  // =====================================================
  // SEVİYE GÜNCELLE
  // =====================================================

  void updateLevel() {
    if (question <= 2) {
      level = 1;
    } else if (question <= 4) {
      level = 2;
    } else {
      level = 3;
    }
  }

  // =====================================================
  // OYUN TAMAMLANDI
  // =====================================================

  Future<void> _showFinalResult() async {
    if (finalDialogShown) return;

    finalDialogShown = true;
    await AchievementManager.unlock('math_master');
    AchievementManager.markGamePlayed('math');

    final String message;

    if (score >= 40) {
      message =
      'Muhteşem bir matematik performansı! 🌟';
    } else if (score >= 20) {
      message =
      'Çok güzel! Matematikte ilerliyorsun. 😊';
    } else {
      message =
      'Harika denedin! Biraz daha pratik yapabilirsin. 💪';
    }

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
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD8ECFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '🎉',
                      style: TextStyle(
                        fontSize: 45,
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
                    color: Color(0xFF3F6383),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6F7C87),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    _resultBox(
                      emoji: '⭐',
                      title: 'Puan',
                      value: '$score',
                    ),

                    const SizedBox(width: 8),

                    _resultBox(
                      emoji: '🎯',
                      title: 'Soru',
                      value: '5 / 5',
                    ),

                    const SizedBox(width: 8),

                    _resultBox(
                      emoji: '⏱️',
                      title: 'Süre',
                      value: _formatSeconds(
                        gameTimer.usedSeconds,
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

                      if (gameTimer.timeIsOver) {
                        Navigator.pop(context);
                        return;
                      }

                      setState(() {
                        level = 1;
                        question = 1;
                        score = 0;

                        // Yeni oyun başladığında
                        // eski soru kayıtlarını temizle.
                        usedQuestions.clear();

                        finalDialogShown = false;
                        timeDialogShown = false;

                        createQuestion();
                      });
                    },
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                    label: const Text(
                      'Tekrar Oyna',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF4D91D0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Oyundan Çık',
                    style: TextStyle(
                      color: Color(0xFF6F7C87),
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
  // SÜRE BİTTİ
  // =====================================================

  void _showTimeFinishedDialog() {
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
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE8E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '⏰',
                      style: TextStyle(
                        fontSize: 43,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Bugünkü Süren Doldu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3F6383),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Matematik oyunu için belirlenen günlük süreyi kullandın. 🌙',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF6F7C87),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5FF),
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                  child: Text(
                    '⭐ Puanın: $score',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4D91D0),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF4D91D0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(17),
                      ),
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        fontSize: 16,
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

  // =====================================================
  // SONUÇ KUTUSU
  // =====================================================

  Widget _resultBox({
    required String emoji,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5FF),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF6F7C87),
              ),
            ),

            const SizedBox(height: 2),

            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4D91D0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // SÜRE FORMAT
  // =====================================================

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    return '$minutes:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  // =====================================================
  // SÜRE İLERLEME
  // =====================================================

  double get _timeProgress {
    if (gameTimer.allowedSeconds <= 0) {
      return 0;
    }

    return (
        gameTimer.remainingSeconds /
            gameTimer.allowedSeconds
    ).clamp(0.0, 1.0);
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final levelTitle = level == 1
        ? '🟢 Kolay Seviye'
        : level == 2
        ? '🟡 Orta Seviye'
        : '🔴 Zor Seviye';

    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          '🔢 Matematik Oyunu',
        ),
        centerTitle: true,
        backgroundColor:
        Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),

      body: SafeArea(
        child: Column(
          children: [
            // =========================================
            // BAŞLIK KARTI
            // =========================================

            Container(
              margin: const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                12,
              ),
              padding:
              const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient:
                const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD8ECFF),
                    Color(0xFFEAF5FF),
                  ],
                ),
                borderRadius:
                BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration:
                    const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '🔢',
                        style: TextStyle(
                          fontSize: 35,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          levelTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w900,
                            color:
                            Color(0xFF3F6383),
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Doğru sonucu seç ve puanını artır!',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                            Color(0xFF6F7C87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                    title: 'Soru',
                    value: '$question / 5',
                  ),

                  const SizedBox(width: 8),

                  InfoBox(
                    emoji: '⏱️',
                    title: 'Kalan',
                    value: gameTimer
                        .formattedRemaining,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // =========================================
            // SÜRE ÇUBUĞU
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
                          Color(0xFF6F7C87),
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
                          Color(0xFF4D91D0),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(10),
                    child:
                    LinearProgressIndicator(
                      value: _timeProgress,
                      minHeight: 7,
                      backgroundColor:
                      const Color(0xFFDDEAF5),
                      valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                        _timeProgress < 0.2
                            ? const Color(
                          0xFFD47A7A,
                        )
                            : const Color(
                          0xFF4D91D0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // =========================================
            // MATEMATİK SORUSU
            // =========================================

            Container(
              margin:
              const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              padding:
              const EdgeInsets.symmetric(
                vertical: 30,
                horizontal: 20,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 6,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(0xFFEAF5FF),
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Soru $question / 5',
                      style:
                      const TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Color(0xFF4D91D0),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    '$first + $second = ?',
                    textAlign:
                    TextAlign.center,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight:
                      FontWeight.w900,
                      color:
                      Color(0xFF4D91D0),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Doğru cevabı seç! 🧠',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                      Color(0xFF7C8993),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // =========================================
            // CEVAPLAR
            // =========================================

            Expanded(
              child: ListView.builder(
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  0,
                  18,
                  15,
                ),
                itemCount: options.length,
                itemBuilder: (_, index) {
                  final option =
                  options[index];

                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: SizedBox(
                      height: 55,
                      child:
                      ElevatedButton(
                        onPressed:
                            () => answer(
                          option,
                        ),
                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          Colors.white,
                          foregroundColor:
                          const Color(
                            0xFF4D91D0,
                          ),
                          elevation: 2,
                          shadowColor:
                          Colors.black12,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              17,
                            ),
                            side:
                            const BorderSide(
                              color: Color(
                                0xFFD8ECFF,
                              ),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 31,
                              height: 31,
                              decoration:
                              const BoxDecoration(
                                color: Color(
                                  0xFFEAF5FF,
                                ),
                                shape:
                                BoxShape
                                    .circle,
                              ),
                              child: Center(
                                child: Text(
                                  String
                                      .fromCharCode(
                                    65 + index,
                                  ),
                                  style:
                                  const TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                    color: Color(
                                      0xFF4D91D0,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child: Text(
                                '$option',
                                textAlign:
                                TextAlign
                                    .center,
                                style:
                                const TextStyle(
                                  fontSize: 21,
                                  fontWeight:
                                  FontWeight
                                      .w900,
                                ),
                              ),
                            ),

                            const Icon(
                              Icons
                                  .arrow_forward_ios_rounded,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    gameTimer.removeListener(
      _timerChanged,
    );

    gameTimer.dispose();

    super.dispose();
  }
}
// =====================================================
// 4 - EŞLEŞTİRME OYUNU
// =====================================================

class ShapeGame extends StatefulWidget {
  const ShapeGame({super.key});

  @override
  State<ShapeGame> createState() => _ShapeGameState();
}

class _ShapeGameState extends State<ShapeGame> {
  late GameTimerController gameTimer;

  final Random random = Random();

  int question = 1;
  int score = 0;
  int level = 1;
  int childAge = 0;

  String targetName = '';
  String targetIcon = '';

  List<Map<String, String>> options = [];

  bool answering = false;
  bool timeDialogShown = false;
  bool finalDialogShown = false;

  final List<Map<String, String>> shapes = [
    {'name': 'Daire', 'icon': '🔵'},
    {'name': 'Kare', 'icon': '🟦'},
    {'name': 'Üçgen', 'icon': '🔺'},
    {'name': 'Yıldız', 'icon': '⭐'},
    {'name': 'Kalp', 'icon': '❤️'},
    {'name': 'Elmas', 'icon': '🔷'},
  ];

  @override
  void initState() {
    super.initState();

    gameTimer = GameTimerController(
      gameName: 'Eşleştirme Oyunu',
      allowedMinutes: 10,
    );

    gameTimer.addListener(_timerChanged);

    gameTimer.addListener(_timerChanged);

    _loadChildAge();
    _initializeTimer();
  }

  Future<void> _loadChildAge() async {
    final prefs =
    await SharedPreferences.getInstance();

    final savedAge =
        prefs.getInt('child_age') ?? 9;

    if (!mounted) return;

    setState(() {
      childAge = savedAge;

      if (childAge <= 5) {
        level = 1;
      } else if (childAge <= 7) {
        level = 1;
      } else if (childAge <= 9) {
        level = 2;
      } else {
        level = 3;
      }

      createQuestion();
    });
  }

  // =====================================================
  // TIMER
  // =====================================================

  void _timerChanged() {
    if (!mounted) return;

    setState(() {});

    if (gameTimer.timeIsOver &&
        !timeDialogShown &&
        !finalDialogShown) {
      timeDialogShown = true;
      _showTimeFinishedDialog();
    }
  }

  Future<void> _initializeTimer() async {
    await gameTimer.load();

    if (!mounted) return;

    setState(() {});

    if (!gameTimer.timeIsOver) {
      gameTimer.start();
    } else {
      timeDialogShown = true;

      Future.delayed(
        const Duration(milliseconds: 300),
            () {
          if (mounted) {
            _showTimeFinishedDialog();
          }
        },
      );
    }
  }

  // =====================================================
  // SORU OLUŞTUR
  // =====================================================

  void createQuestion() {
    int optionCount;

    if (childAge <= 5) {
      // 4–5 yaş
      optionCount = 3;
    } else if (childAge <= 7) {
      // 6–7 yaş
      optionCount = 4;
    } else if (childAge <= 9) {
      // 8–9 yaş
      optionCount = 5;
    } else {
      // 10–12 yaş
      optionCount = 6;
    }

    final available =
    List<Map<String, String>>.from(shapes);

    available.shuffle(random);

    options = List<Map<String, String>>.from(
      available.take(optionCount),
    );

    final target = options.first;

    targetName = target['name']!;
    targetIcon = target['icon']!;

    options.shuffle(random);

    answering = false;
  }

  // =====================================================
  // ŞEKİL SEÇ
  // =====================================================

  void selectShape(String name) {
    if (gameTimer.timeIsOver ||
        answering ||
        finalDialogShown) {
      return;
    }

    setState(() {
      answering = true;
    });

    final correct = name == targetName;

    if (correct) {
      score += level * 10;
    }

    _showAnswerDialog(correct);
  }

  // =====================================================
  // CEVAP SONUCU
  // =====================================================

  void _showAnswerDialog(bool correct) {
    final earnedScore = correct ? level * 10 : 0;
    if (correct) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playWrong();
    }

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
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: correct
                        ? const Color(0xFFE1F7F3)
                        : const Color(0xFFFFE7E7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      correct ? '🎉' : '💭',
                      style: const TextStyle(
                        fontSize: 42,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  correct
                      ? 'Harika! 🔷'
                      : 'Bu sefer olmadı!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF39766F),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  correct
                      ? 'Hedef şekli doğru eşleştirdin!'
                      : 'Doğru cevap: $targetName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF776A77),
                  ),
                ),

                const SizedBox(height: 18),

                if (correct)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F5),
                      borderRadius:
                      BorderRadius.circular(15),
                    ),
                    child: Text(
                      '⭐ +$earnedScore Puan',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3C8179),
                      ),
                    ),
                  ),

                if (correct)
                  const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      if (question == 5) {
                        _showFinalResult();
                      } else {
                        setState(() {
                          question++;
                          updateLevel();
                          createQuestion();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF3C8179),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(17),
                      ),
                    ),
                    child: Text(
                      question == 5
                          ? 'Sonucu Gör'
                          : 'Devam Et',
                      style: const TextStyle(
                        fontSize: 16,
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

  // =====================================================
  // SEVİYE
  // =====================================================

  void updateLevel() {
    if (question <= 2) {
      level = 1;
    } else if (question <= 4) {
      level = 2;
    } else {
      level = 3;
    }
  }

  // =====================================================
  // OYUN TAMAMLANDI
  // =====================================================

  void _showFinalResult() {
    if (finalDialogShown) return;
    AchievementManager.unlock('shape_master');
    AchievementManager.markGamePlayed('shape');


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
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD6F6F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '🎉',
                      style: TextStyle(
                        fontSize: 45,
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
                    color: Color(0xFF39766F),
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Eşleştirme oyununu tamamladın! 🔷✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF776A77),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    _resultBox(
                      emoji: '⭐',
                      title: 'Puan',
                      value: '$score',
                    ),

                    const SizedBox(width: 8),

                    _resultBox(
                      emoji: '🎯',
                      title: 'Soru',
                      value: '5 / 5',
                    ),

                    const SizedBox(width: 8),

                    _resultBox(
                      emoji: '⏱️',
                      title: 'Süre',
                      value: _formatSeconds(
                        gameTimer.usedSeconds,
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

                      if (gameTimer.timeIsOver) {
                        Navigator.pop(context);
                        return;
                      }

                      setState(() {
                        question = 1;
                        score = 0;
                        level = 1;
                        finalDialogShown = false;
                        timeDialogShown = false;
                        createQuestion();
                      });
                    },
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                    label: const Text(
                      'Tekrar Oyna',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF3C8179),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Oyundan Çık',
                    style: TextStyle(
                      color: Color(0xFF776A77),
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
  // SÜRE BİTTİ
  // =====================================================

  void _showTimeFinishedDialog() {
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
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE8E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '⏰',
                      style: TextStyle(
                        fontSize: 43,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Bugünkü Süren Doldu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF39766F),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Eşleştirme oyunu için belirlenen günlük süreyi kullandın. 🌙',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF776A77),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F5),
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                  child: Text(
                    '⭐ Puanın: $score',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3C8179),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF3C8179),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(17),
                      ),
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        fontSize: 16,
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

  // =====================================================
  // SONUÇ KUTUSU
  // =====================================================

  Widget _resultBox({
    required String emoji,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8F5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF776A77),
              ),
            ),

            const SizedBox(height: 2),

            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3C8179),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // SÜRE FORMAT
  // =====================================================

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    return '$minutes:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  // =====================================================
  // SÜRE İLERLEME
  // =====================================================

  double get _timeProgress {
    if (gameTimer.allowedSeconds <= 0) {
      return 0;
    }

    return (
        gameTimer.remainingSeconds /
            gameTimer.allowedSeconds
    ).clamp(0.0, 1.0);
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final levelTitle = level == 1
        ? '🟢 Kolay Seviye'
        : level == 2
        ? '🟡 Orta Seviye'
        : '🔴 Zor Seviye';

    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          '🔷 Eşleştirme Oyunu',
        ),
        centerTitle: true,
        backgroundColor:
        Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),

      body: SafeArea(
        child: Column(
          children: [
            // =========================================
            // BAŞLIK KARTI
            // =========================================

            Container(
              margin: const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                12,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD6F6F1),
                    Color(0xFFE8FAF7),
                  ],
                ),
                borderRadius:
                BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration:
                    const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '🔷',
                        style: TextStyle(
                          fontSize: 35,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          levelTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w900,
                            color:
                            Color(0xFF39766F),
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Hedef şeklin aynısını bul!',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                            Color(0xFF6F827F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                    title: 'Soru',
                    value: '$question / 5',
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
            // SÜRE ÇUBUĞU
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
                          Color(0xFF6F827F),
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
                          Color(0xFF3C8179),
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
                      value: _timeProgress,
                      minHeight: 7,
                      backgroundColor:
                      const Color(
                        0xFFDCEEEB,
                      ),
                      valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                        _timeProgress < 0.2
                            ? const Color(
                          0xFFD47A7A,
                        )
                            : const Color(
                          0xFF3C8179,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // =========================================
            // HEDEF ŞEKİL
            // =========================================

            Container(
              margin:
              const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              padding:
              const EdgeInsets.symmetric(
                vertical: 17,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(27),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFFE8F8F5),
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: const Text(
                      '🎯 Hedef şekli bul',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Color(0xFF3C8179),
                      ),
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    targetIcon,
                    style: const TextStyle(
                      fontSize: 55,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    targetName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Color(0xFF6F827F),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // =========================================
            // SEÇENEKLER
            // =========================================

            Expanded(
              child: GridView.builder(
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  0,
                  18,
                  15,
                ),
                itemCount: options.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.28,
                ),
                itemBuilder: (_, index) {
                  final option =
                  options[index];

                  return ElevatedButton(
                    onPressed: () {
                      selectShape(
                        option['name']!,
                      );
                    },
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.white,
                      foregroundColor:
                      const Color(
                        0xFF3C8179,
                      ),
                      elevation: 2,
                      shadowColor:
                      Colors.black12,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          22,
                        ),
                        side:
                        const BorderSide(
                          color: Color(
                            0xFFD6F0EC,
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                      children: [
                        Text(
                          option['icon']!,
                          style:
                          const TextStyle(
                            fontSize: 40,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          option['name']!,
                          style:
                          const TextStyle(
                            fontSize: 14,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        const Icon(
                          Icons
                              .touch_app_rounded,
                          size: 15,
                          color:
                          Color(0xFF91BDB8),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    gameTimer.removeListener(_timerChanged);
    gameTimer.dispose();

    super.dispose();
  }
}

// =====================================================
// 5 - MANTIK OYUNU
// =====================================================

class LogicGame extends StatefulWidget {
  const LogicGame({super.key});

  @override
  State<LogicGame> createState() => _LogicGameState();
}

class _LogicGameState extends State<LogicGame> {
  late GameTimerController gameTimer;

  int question = 1;
  int score = 0;
  int childAge = 0;

  bool answering = false;
  bool timeDialogShown = false;
  bool finalDialogShown = false;

  late List<Map<String, dynamic>> questions;
  final List<List<Map<String, dynamic>>> ageQuestionPools = [
    // =====================================================
    // 4-5 YAŞ
    // =====================================================
    [
      {
        'question': 'Hangisi diğerlerinden farklıdır?',
        'options': ['🍎', '🍎', '🍎', '🚗'],
        'answer': '🚗',
      },
      {
        'question': 'Hangisi bir hayvandır?',
        'options': ['🐶', '🍎', '🚗', '🌳'],
        'answer': '🐶',
      },
      {
        'question': '1, 2, 3, 4, ?',
        'options': ['5', '6', '7', '8'],
        'answer': '5',
      },
      {
        'question': 'Hangisi diğerlerinden farklıdır?',
        'options': ['⭐', '⭐', '🌈', '⭐'],
        'answer': '🌈',
      },
      {
        'question': 'Hangisi bir yiyecektir?',
        'options': ['🍎', '🚗', '🐶', '🌳'],
        'answer': '🍎',
      },
    ],

    // =====================================================
    // 6-7 YAŞ
    // =====================================================
    [
      {
        'question': '2, 4, 6, 8, ?',
        'options': ['9', '10', '11', '12'],
        'answer': '10',
      },
      {
        'question': '3, 6, 9, 12, ?',
        'options': ['13', '14', '15', '16'],
        'answer': '15',
      },
      {
        'question': 'Hangisi diğerlerinden farklıdır?',
        'options': ['🔵', '🔵', '🔺', '🔵'],
        'answer': '🔺',
      },
      {
        'question': '5, 10, 15, 20, ?',
        'options': ['21', '22', '25', '30'],
        'answer': '25',
      },
      {
        'question': 'Hangisi bir hayvan değildir?',
        'options': ['🐶', '🐱', '🐟', '🌳'],
        'answer': '🌳',
      },
    ],

    // =====================================================
    // 8-9 YAŞ
    // =====================================================
    [
      {
        'question': '5, 10, 15, 20, ?',
        'options': ['22', '24', '25', '30'],
        'answer': '25',
      },
      {
        'question': '2, 5, 8, 11, ?',
        'options': ['12', '13', '14', '15'],
        'answer': '14',
      },
      {
        'question': 'Hangisi diğerlerinden farklıdır?',
        'options': ['🟦', '🟦', '🟩', '🟦'],
        'answer': '🟩',
      },
      {
        'question': '10, 20, 30, 40, ?',
        'options': ['45', '50', '55', '60'],
        'answer': '50',
      },
      {
        'question': '3, 6, 12, 24, ?',
        'options': ['36', '42', '48', '50'],
        'answer': '48',
      },
    ],

    // =====================================================
    // 10-12 YAŞ
    // =====================================================
    [
      {
        'question': '3, 6, 12, 24, ?',
        'options': ['36', '42', '48', '54'],
        'answer': '48',
      },
      {
        'question': '2, 6, 12, 20, ?',
        'options': ['28', '30', '32', '36'],
        'answer': '30',
      },
      {
        'question': '81, 27, 9, 3, ?',
        'options': ['1', '2', '0', '6'],
        'answer': '1',
      },
      {
        'question': '7, 14, 21, 28, ?',
        'options': ['32', '35', '36', '42'],
        'answer': '35',
      },
      {
        'question': '4, 8, 16, 32, ?',
        'options': ['48', '56', '64', '72'],
        'answer': '64',
      },
    ],
  ];

  String get currentQuestion =>
      questions[question - 1]['question'];

  List<String> get currentOptions =>
      List<String>.from(
        questions[question - 1]['options'],
      );

  String get correctAnswer =>
      questions[question - 1]['answer'];

  @override
  void initState() {
    super.initState();

    gameTimer = GameTimerController(
      gameName: 'Mantık Oyunu',
      allowedMinutes: 15,
    );

    gameTimer.addListener(_timerChanged);

    _loadChildAge();
    _initializeTimer();
  }

  Future<void> _loadChildAge() async {
    final prefs =
    await SharedPreferences.getInstance();

    final savedAge =
        prefs.getInt('child_age') ?? 9;

    if (!mounted) return;

    setState(() {
      childAge = savedAge;

      int poolIndex;

      if (childAge <= 5) {
        poolIndex = 0;
      } else if (childAge <= 7) {
        poolIndex = 1;
      } else if (childAge <= 9) {
        poolIndex = 2;
      } else {
        poolIndex = 3;
      }

      questions =
      List<Map<String, dynamic>>.from(
        ageQuestionPools[poolIndex],
      );

      questions.shuffle();

      question = 1;
      score = 0;
      answering = false;
    });
  }

  // =====================================================
  // TIMER
  // =====================================================

  void _timerChanged() {
    if (!mounted) return;

    setState(() {});

    if (gameTimer.timeIsOver &&
        !timeDialogShown &&
        !finalDialogShown) {
      timeDialogShown = true;
      _showTimeFinishedDialog();
    }
  }

  Future<void> _initializeTimer() async {
    await gameTimer.load();

    if (!mounted) return;

    setState(() {});

    if (!gameTimer.timeIsOver) {
      gameTimer.start();
    } else {
      timeDialogShown = true;

      Future.delayed(
        const Duration(milliseconds: 300),
            () {
          if (mounted) {
            _showTimeFinishedDialog();
          }
        },
      );
    }
  }

  // =====================================================
  // CEVAP
  // =====================================================

  void answer(String selectedAnswer) {
    if (gameTimer.timeIsOver ||
        answering ||
        finalDialogShown) {
      return;
    }

    setState(() {
      answering = true;
    });

    final correct =
        selectedAnswer == correctAnswer;

    if (correct) {
      score += 10;
    }

    _showAnswerDialog(correct);
  }

  // =====================================================
  // CEVAP SONUCU
  // =====================================================

  void _showAnswerDialog(bool correct) {
    if (correct) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playWrong();
    }
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
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: correct
                        ? const Color(0xFFE1F4D4)
                        : const Color(0xFFFFE7E7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      correct ? '🎉' : '💭',
                      style: const TextStyle(
                        fontSize: 42,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  correct
                      ? 'Harika! 🧩'
                      : 'Tekrar Düşün! 💭',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF506245),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  correct
                      ? 'Mantık sorusunu doğru çözdün!'
                      : 'Doğru cevap: $correctAnswer',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF71806A),
                  ),
                ),

                const SizedBox(height: 18),

                if (correct)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F8EA),
                      borderRadius:
                      BorderRadius.circular(15),
                    ),
                    child: const Text(
                      '⭐ +10 Puan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF587047),
                      ),
                    ),
                  ),

                if (correct)
                  const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      if (question == 5) {
                        _showFinalResult();
                      } else {
                        setState(() {
                          question++;
                          answering = false;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF587047),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(17),
                      ),
                    ),
                    child: Text(
                      question == 5
                          ? 'Sonucu Gör'
                          : 'Devam Et',
                      style: const TextStyle(
                        fontSize: 16,
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

  // =====================================================
  // OYUN TAMAMLANDI
  // =====================================================

  void _showFinalResult() {
    SoundManager.playGameOver();
    if (finalDialogShown) return;
    AchievementManager.unlock('logic_master');
    AchievementManager.markGamePlayed('logic');

    finalDialogShown = true;

    final message = score >= 40
        ? 'Muhteşem bir mantık yürüttün! 🌟'
        : 'Biraz daha pratik yaparsan daha da iyi olacaksın! 💪';

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
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE1F4D4),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '🏆',
                      style: TextStyle(
                        fontSize: 45,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Mantık Ustası!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF506245),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF71806A),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    _resultBox(
                      emoji: '⭐',
                      title: 'Puan',
                      value: '$score',
                    ),

                    const SizedBox(width: 8),

                    _resultBox(
                      emoji: '🎯',
                      title: 'Soru',
                      value: '5 / 5',
                    ),

                    const SizedBox(width: 8),

                    _resultBox(
                      emoji: '⏱️',
                      title: 'Süre',
                      value: _formatSeconds(
                        gameTimer.usedSeconds,
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

                      if (gameTimer.timeIsOver) {
                        Navigator.pop(context);
                        return;
                      }

                      setState(() {
                        question = 1;
                        score = 0;
                        answering = false;
                        finalDialogShown = false;
                        timeDialogShown = false;

                        int poolIndex;

                        if (childAge <= 5) {
                          poolIndex = 0;
                        } else if (childAge <= 7) {
                          poolIndex = 1;
                        } else if (childAge <= 9) {
                          poolIndex = 2;
                        } else {
                          poolIndex = 3;
                        }

                        questions =
                        List<Map<String, dynamic>>.from(
                          ageQuestionPools[poolIndex],
                        );

                        questions.shuffle();
                      });
                    },
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                    label: const Text(
                      'Tekrar Oyna',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF587047),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Oyundan Çık',
                    style: TextStyle(
                      color: Color(0xFF71806A),
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
  // SÜRE BİTTİ
  // =====================================================

  void _showTimeFinishedDialog() {
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
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE8E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '⏰',
                      style: TextStyle(
                        fontSize: 43,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Bugünkü Süren Doldu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF506245),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Mantık oyunu için belirlenen günlük süreyi kullandın. 🌙',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF71806A),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8EA),
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                  child: Text(
                    '⭐ Puanın: $score',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF587047),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF587047),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(17),
                      ),
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        fontSize: 16,
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

  // =====================================================
  // SONUÇ KUTUSU
  // =====================================================

  Widget _resultBox({
    required String emoji,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F8EA),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF71806A),
              ),
            ),

            const SizedBox(height: 2),

            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF587047),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // SÜRE FORMAT
  // =====================================================

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    return '$minutes:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  // =====================================================
  // SÜRE İLERLEME
  // =====================================================

  double get _timeProgress {
    if (gameTimer.allowedSeconds <= 0) {
      return 0;
    }

    return (
        gameTimer.remainingSeconds /
            gameTimer.allowedSeconds
    ).clamp(0.0, 1.0);
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final options = currentOptions;

    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          '🧩 Mantık Oyunu',
        ),
        centerTitle: true,
        backgroundColor:
        Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),

      body: SafeArea(
        child: Column(
          children: [
            // =========================================
            // BAŞLIK KARTI
            // =========================================

            Container(
              margin: const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                12,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE1F4D4),
                    Color(0xFFF0F8EA),
                  ],
                ),
                borderRadius:
                BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration:
                    const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '🧩',
                        style: TextStyle(
                          fontSize: 35,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 13),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mantığını kullan! 🧠',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight:
                            FontWeight.w900,
                            color:
                            Color(0xFF506245),
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          'Soruyu dikkatlice düşün ve doğru cevabı bul.',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                            Color(0xFF71806A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                    title: 'Soru',
                    value: '$question / 5',
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
            // SÜRE ÇUBUĞU
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
                          Color(0xFF71806A),
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
                          Color(0xFF587047),
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
                      value: _timeProgress,
                      minHeight: 7,
                      backgroundColor:
                      const Color(
                        0xFFDCEAD5,
                      ),
                      valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                        _timeProgress < 0.2
                            ? const Color(
                          0xFFD47A7A,
                        )
                            : const Color(
                          0xFF587047,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // =========================================
            // SORU KARTI
            // =========================================

            Container(
              margin:
              const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              padding: const EdgeInsets.all(25),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(27),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFFF0F8EA),
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Text(
                      '🧠 Soru $question / 5',
                      style:
                      const TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Color(0xFF587047),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    currentQuestion,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.35,
                      fontWeight:
                      FontWeight.w900,
                      color:
                      Color(0xFF506245),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Düşün ve doğru cevabı seç! 💭',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                      Color(0xFF71806A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // =========================================
            // CEVAPLAR
            // =========================================

            Expanded(
              child: ListView.builder(
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  0,
                  18,
                  15,
                ),
                itemCount: options.length,
                itemBuilder: (_, index) {
                  final option =
                  options[index];

                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: SizedBox(
                      height: 58,
                      child:
                      ElevatedButton(
                        onPressed: () {
                          answer(option);
                        },
                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          Colors.white,
                          foregroundColor:
                          const Color(
                            0xFF587047,
                          ),
                          elevation: 2,
                          shadowColor:
                          Colors.black12,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              18,
                            ),
                            side:
                            const BorderSide(
                              color: Color(
                                0xFFDCEAD5,
                              ),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration:
                              const BoxDecoration(
                                color: Color(
                                  0xFFF0F8EA,
                                ),
                                shape:
                                BoxShape
                                    .circle,
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(
                                    65 + index,
                                  ),
                                  style:
                                  const TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                    color:
                                    Color(
                                      0xFF587047,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child: Text(
                                option,
                                textAlign:
                                TextAlign.center,
                                style:
                                const TextStyle(
                                  fontSize: 22,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                            ),

                            const Icon(
                              Icons
                                  .arrow_forward_ios_rounded,
                              size: 15,
                              color:
                              Color(
                                0xFF9BAE91,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    gameTimer.removeListener(_timerChanged);
    gameTimer.dispose();

    super.dispose();
  }
}

// =====================================================
// SONUÇ DİYALOĞU
// =====================================================

class ResultDialog extends StatelessWidget {
final String title;
final String message;
final int score;
final bool showScore;
final VoidCallback onAgain;
final String buttonText;

const ResultDialog({
super.key,
required this.title,
required this.message,
required this.score,
required this.onAgain,
this.showScore = true,
this.buttonText = 'Tekrar Oyna',
});

@override
Widget build(BuildContext context) {
return AlertDialog(
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(25),
),
title: Text(
title,
textAlign: TextAlign.center,
),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
Text(
message,
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 15,
height: 1.4,
),
),
if (showScore) ...[
const SizedBox(height: 15),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 20,
vertical: 10,
),
decoration: BoxDecoration(
color: const Color(0xFFF4EAF7),
borderRadius: BorderRadius.circular(15),
),
child: Text(
'⭐ +$score puan',
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: Color(0xFF63448D),
),
),
),
],
],
),
actions: [
Center(
child: ElevatedButton(
onPressed: onAgain,
child: Text(buttonText),
),
),
],
);
}
}

// =====================================================
// BİLGİ KUTUSU
// =====================================================

class InfoBox extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;

  const InfoBox({
    super.key,
    required this.emoji,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$emoji $title',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7A6E7E),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF63448D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
