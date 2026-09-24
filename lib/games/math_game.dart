import 'dart:math';

import 'package:flutter/material.dart';

import '../achievement_manager.dart';
import '../app_theme.dart';
import '../difficulty.dart';
import '../game_id.dart';
import '../game_kit.dart';
import '../sound_manager.dart';

// =====================================================
// 3 - MATEMATİK OYUNU
// =====================================================

class MathGame extends StatefulWidget {
  const MathGame({super.key});

  @override
  State<MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<MathGame> with GameSessionMixin {
  // ---- GameSessionMixin sozlesmesi ----

  @override
  GameId get game => GameId.math;

  @override
  String get timeUpMessage =>
      'Matematik oyunu için belirlenen günlük süreyi kullandın. 🌙';

  @override
  int get currentScore => score;

  /// Oyun bittiyse sure uyarisi gosterme.
  @override
  bool get canShowTimeUpDialog => !finalDialogShown;

  @override
  void onChildAgeLoaded() {

    createQuestion();
  }

  final Random random = Random();

  int question = 1;
  int score = 0;

  int first = 0;
  int second = 0;
  int correctAnswer = 0;

  List<int> options = [];

  // Aynı oyun içinde sorulan soruları tutar.
  final Set<String> usedQuestions = {};

  bool finalDialogShown = false;
  bool answering = false;

  @override
  void initState() {
    super.initState();

    startGameSession();
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
      // Sayi buyuklugu yas bandindan; seviye yukseldikce aralik da genisler.
      // Eskiden seviye soru numarasindan hesaplaniyor ve sorulara hic
      // dokunmuyordu, yalnizca puani carpiyordu.
      final span = difficulty.scaled(const [5, 10, 15, 20], max: 30);

      newFirst = random.nextInt(span) + 1;
      newSecond = random.nextInt(span) + 1;

      newQuestionKey = _questionKey(newFirst, newSecond);
    } while (usedQuestions.contains(newQuestionKey));

    first = newFirst;
    second = newSecond;

    usedQuestions.add(newQuestionKey);

    correctAnswer = first + second;

    options = {
      correctAnswer,
      correctAnswer + 1,
      correctAnswer - 1,
      correctAnswer + 2,
    }.toList();

    while (options.length < 4) {
      final value = correctAnswer + random.nextInt(7) - 3;

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
    if (gameTimer.timeIsOver || answering || finalDialogShown) {
      return;
    }

    answering = true;

    final correct = value == correctAnswer;

    // Puan mevcut seviyeden; seviye SONRA guncelleniyor. Kazanilan puan
    // diyaloga parametre olarak gidiyor, yoksa seviye atlandiginda diyalog
    // eklenen puandan baska bir sayi gosterirdi.
    final earned = correct ? difficulty.level * 10 : 0;

    if (correct) {
      score += earned;
      difficulty.correct();
    } else {
      difficulty.wrong();
    }

    _showAnswerDialog(correct, value, earned);
  }

  // =====================================================
  // DOĞRU / YANLIŞ EKRANI
  // =====================================================

  void _showAnswerDialog(bool correct, int selectedAnswer, int earnedScore) {

    if (correct) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playWrong();
    }

    // Back continues like the button. Closing only the dialog left the
    // question answered and every option ignoring taps.
    Future<void> continueAfterAnswer(BuildContext dialogContext) async {
      Navigator.pop(dialogContext);

      if (question == 5) {
        await _showFinalResult();
      } else {
        setState(() {
          question++;
          createQuestion();
        });
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final dialog = Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          // Scrolls only when the screen is too short for it: at 320x568 the
          // result dialog was ~100 px taller than the space, so its buttons
          // sat off-screen.
          child: SingleChildScrollView(
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
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  correct ? 'Harika! 🔢' : 'Tekrar Dene! 💪',
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
                    fontSize: 17,
                    height: 1.4,
                    color: Color(0xFF6F7C87),
                  ),
                ),

                const SizedBox(height: 18),

                if (correct)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5FF),
                      borderRadius: BorderRadius.circular(15),
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

                if (correct) const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: Brand.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () => continueAfterAnswer(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4D91D0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: Text(
                      question == 5 ? 'Sonucu Gör' : 'Sonraki Soru',
                      style: const TextStyle(
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

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) continueAfterAnswer(dialogContext);
          },
          child: dialog,
        );
      },
    );
  }

  // =====================================================
  // SEVİYE GÜNCELLE
  // =====================================================


  // =====================================================
  // OYUN TAMAMLANDI
  // =====================================================

  Future<void> _showFinalResult() async {
    if (finalDialogShown) return;

    finalDialogShown = true;
    await AchievementManager.unlock('math_master');
    await AchievementManager.unlock('first_step');
    await AchievementManager.markGamePlayed(game);

    if (!mounted) return;

    final String message;

    if (score >= 40) {
      message = 'Muhteşem bir matematik performansı! 🌟';
    } else if (score >= 20) {
      message = 'Çok güzel! Matematikte ilerliyorsun. 😊';
    } else {
      message = 'Harika denedin! Biraz daha pratik yapabilirsin. 💪';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final dialog = Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          // Scrolls only when the screen is too short for it: at 320x568 the
          // result dialog was ~100 px taller than the space, so its buttons
          // sat off-screen.
          child: SingleChildScrollView(
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
                    child: Text('🎉', style: TextStyle(fontSize: 45)),
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
                    fontSize: 17,
                    color: Color(0xFF6F7C87),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    GameResultBox(
                      palette: GamePalette.math,
                      emoji: '⭐',
                      title: 'Puan',
                      value: '$score',
                    ),

                    const SizedBox(width: 8),

                    GameResultBox(
                      palette: GamePalette.math,
                      emoji: '🎯',
                      title: 'Soru',
                      value: '5 / 5',
                    ),

                    const SizedBox(width: 8),

                    GameResultBox(
                      palette: GamePalette.math,
                      emoji: '⏱️',
                      title: 'Süre',
                      value: formatSeconds(gameTimer.usedSeconds),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: Brand.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      if (gameTimer.timeIsOver) {
                        Navigator.pop(context);
                        return;
                      }

                      setState(() {
                        difficulty.reset();
                        question = 1;
                        score = 0;

                        // Yeni oyun başladığında
                        // eski soru kayıtlarını temizle.
                        usedQuestions.clear();

                        finalDialogShown = false;
                        timeUpDialogShown = false;

                        createQuestion();
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'Tekrar Oyna',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4D91D0),
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
                    style: TextStyle(color: Color(0xFF6F7C87)),
                  ),
                ),
              ],
            ),
          ),
        );

        // Back leaves the game, like "Oyundan Çık". Closing only the
        // dialog left a finished game that ignored every tap.
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            Navigator.pop(dialogContext);
            Navigator.pop(context);
          },
          child: dialog,
        );
      },
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final levelTitle = levelLabel(difficulty.level);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: GameAppBarTitle(game: game),
        centerTitle: true,
        actions: [
          GameHelpButton(game: game, levelLabel: levelTitle,),
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
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  InfoBox(emoji: '⭐', title: 'Puan', value: '$score'),

                  const SizedBox(width: 8),

                  InfoBox(emoji: '🎯', title: 'Soru', value: '$question / 5'),

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
            GameTimeBar(
              palette: palette,
              progress: timeProgress,
              remaining: gameTimer.formattedRemaining,
            ),
            const SizedBox(height: 14),

            // =========================================
            // MATEMATİK SORUSU
            // =========================================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Soru $question / 5',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4D91D0),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    '$first + $second = ?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4D91D0),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Doğru cevabı seç! 🧠',
                    style: TextStyle(fontSize: 17, color: Color(0xFF7C8993)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // =========================================
            // CEVAPLAR
            // =========================================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 15),
                // Izgara kaydirilamiyor, o yuzden dort secenek eldeki
                // yuksekliğe her ekranda tam sigmali: oran olculerden
                // hesaplaniyor, sabit verilmiyor.
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 12.0;

                    // options ilk build'de bos olabilir: yas bilgisi asenkron
                    // geliyor. rowCount 0 olursa sifira bolme orani 0 yapiyor
                    // ve GridView'in childAspectRatio > 0 kontrolu patliyor.
                    final rowCount = (options.length / 2).ceil().clamp(1, 4);
                    final cellWidth = (constraints.maxWidth - spacing) / 2;
                    final cellHeight =
                        (constraints.maxHeight - spacing * (rowCount - 1)) /
                        rowCount;

                    final fits =
                        cellWidth.isFinite &&
                        cellHeight.isFinite &&
                        cellWidth > 0 &&
                        cellHeight > 0;

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: fits
                          ? (cellWidth / cellHeight).clamp(0.6, 4.0)
                          : 1.6,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(options.length, (index) {
                        final option = options[index];

                        // Dogru/yanlis cagrisimi olmasin diye kirmizi ve yesil
                        // kullanilmiyor; renkler yalnizca secenekleri ayirt
                        // etmeye yariyor.
                        const colors = [
                          Brand.gameAttention,
                          Brand.gameMemory,
                          Brand.gameWord,
                          Brand.gameLetter,
                        ];
                        final color = colors[index % colors.length];

                        return Material(
                          color: color,
                          borderRadius: BorderRadius.circular(Brand.cardRadius),
                          elevation: 3,
                          shadowColor: color.withValues(alpha: 0.45),
                          child: InkWell(
                            onTap: () => answer(option),
                            borderRadius: BorderRadius.circular(
                              Brand.cardRadius,
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    '$option',
                                    style: const TextStyle(
                                      fontSize: 46,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
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
