import 'dart:math';

import 'package:flutter/material.dart';

import '../achievement_manager.dart';
import '../game_id.dart';
import '../game_kit.dart';
import '../sound_manager.dart';

// =====================================================
// 4 - EŞLEŞTİRME OYUNU
// =====================================================

class ShapeGame extends StatefulWidget {
  const ShapeGame({super.key});

  @override
  State<ShapeGame> createState() => _ShapeGameState();
}

class _ShapeGameState extends State<ShapeGame> with GameSessionMixin {
  // ---- GameSessionMixin sozlesmesi ----

  @override
  GameId get game => GameId.shape;

  @override
  String get timeUpMessage =>
      'Eşleştirme oyunu için belirlenen günlük süreyi kullandın. 🌙';

  @override
  int get currentScore => score;

  /// Oyun bittiyse sure uyarisi gosterme.
  @override
  bool get canShowTimeUpDialog => !finalDialogShown;

  @override
  void onChildAgeLoaded() {
    level = levelForAge(childAge);

    createQuestion();
  }

  final Random random = Random();

  int question = 1;
  int score = 0;
  int level = 1;

  String targetName = '';
  String targetIcon = '';

  List<Map<String, String>> options = [];

  bool answering = false;
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

    startGameSession();
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
                    color: Color(0xFF21CA3A),
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

    finalDialogShown = true;

    AchievementManager.unlock('shape_master');
    AchievementManager.unlock('first_step');
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
                    color: Color(0xFF21CA3A),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    GameResultBox(
                      palette: GamePalette.shape,
                      emoji: '⭐',
                      title: 'Puan',
                      value: '$score',
                    ),

                    const SizedBox(width: 8),

                    GameResultBox(
                      palette: GamePalette.shape,
                      emoji: '🎯',
                      title: 'Soru',
                      value: '5 / 5',
                    ),

                    const SizedBox(width: 8),

                    GameResultBox(
                      palette: GamePalette.shape,
                      emoji: '⏱️',
                      title: 'Süre',
                      value: formatSeconds(
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
                        timeUpDialogShown = false;
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
                      value: timeProgress,
                      minHeight: 7,
                      backgroundColor:
                      const Color(
                        0xFFDCEEEB,
                      ),
                      valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                        timeProgress < 0.2
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
}
