import 'dart:math';

import 'package:flutter/material.dart';

import '../achievement_manager.dart';
import '../difficulty.dart';
import '../game_id.dart';
import '../game_kit.dart';
import '../sound_manager.dart';

// =====================================================
// 2 - DİKKAT OYUNU
// =====================================================

class AttentionGame extends StatefulWidget {
  const AttentionGame({super.key});

  @override
  State<AttentionGame> createState() => _AttentionGameState();
}

class _AttentionGameState extends State<AttentionGame> with GameSessionMixin {
  // ---- GameSessionMixin sozlesmesi ----

  @override
  GameId get game => GameId.attention;

  @override
  String get timeUpMessage =>
      'Dikkat oyunu için belirlenen günlük süreyi kullandın. 🌙';

  @override
  int get currentScore => score;

  /// Oyun bittiyse sure uyarisi gosterme.
  @override
  bool get canShowTimeUpDialog => !finalDialogShown;

  @override
  void onChildAgeLoaded() {

    createQuestion();
  }

  int question = 1;
  int score = 0;
  int differentIndex = 0;

  bool answered = false;
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

  @override
  void initState() {
    super.initState();

    // Soruyu hemen kur: yas bilgisi asenkron geldigi icin ilk build
    // ondan once calisiyor ve 'items' atanmamis kaliyordu.
    createQuestion();

    startGameSession();
  }

  // =====================================================
  // SORU OLUŞTUR
  // =====================================================

  void createQuestion() {
    // Sembol sayisi yas bandindan baslar, seviye yukseldikce artar.
    final itemCount = difficulty.scaled(const [6, 9, 12, 16], max: 20);

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
      '${difficulty.level}-$normalSymbol-$differentSymbol-$newDifferentIndex';

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

    final earned = correct ? difficulty.level * 10 : 0;

    if (correct) {
      score += earned;
      difficulty.correct();
    } else {
      difficulty.wrong();
    }

    _showAnswerDialog(correct, earned);
  }

  // =====================================================
  // DOĞRU / YANLIŞ SONUÇ
  // =====================================================

  void _showAnswerDialog(bool correct, int earnedScore) {
    if (correct) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playWrong();
    }

    // Back continues like the button. Closing only the dialog left the
    // question answered and every option ignoring taps.
    void continueAfterAnswer(BuildContext dialogContext) {
      Navigator.pop(dialogContext);

      if (question == 3) {
        _showFinalResult();
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
                    color: Color(0xFF20813A),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  correct
                      ? 'Farklı olanı doğru buldun!'
                      : 'Bir sonraki soruda daha dikkatli ol!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
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
                      color: const Color(0xFFE7F9E9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '⭐ +$earnedScore Puan',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2AA74B),
                      ),
                    ),
                  ),

                if (correct)
                  const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => continueAfterAnswer(dialogContext),
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
  // OYUN TAMAMLANDI
  // =====================================================

  Future<void> _showFinalResult() async {
    if (finalDialogShown) return;

    finalDialogShown = true;
    await AchievementManager.unlock('attention_master');
    await AchievementManager.unlock('first_step');
    await AchievementManager.markGamePlayed(game);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final dialog = Dialog(
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
                    color: Color(0xFF20813A),
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Dikkat testini tamamladın! 👀✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF21CA3A),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    GameResultBox(
                      palette: GamePalette.attention,
                      emoji: '⭐',
                      title: 'Puan',
                      value: '$score',
                    ),
                    const SizedBox(width: 8),
                    GameResultBox(
                      palette: GamePalette.attention,
                      emoji: '🎯',
                      title: 'Soru',
                      value: '3 / 3',
                    ),
                    const SizedBox(width: 8),
                    GameResultBox(
                      palette: GamePalette.attention,
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
                        difficulty.reset();
                        question = 1;
                        score = 0;
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
                        fontSize: 18,
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
                      color: Color(0xFF21CA3A),
                    ),
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
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: GameAppBarTitle(game: game),
        centerTitle: true,
        actions: [
          GameHelpButton(game: game, levelLabel: levelTitle,),
        ],
        backgroundColor:
        Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),

      body: SafeArea(
        child: Column(
          children: [
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
                      value: timeProgress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFF0DED0),
                      valueColor:
                      AlwaysStoppedAnimation<Color>(
                        timeProgress < 0.2
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
                        difficulty.level == 1
                            ? 'İpucu: Farklı olan şekle dikkatlice bak!'
                            : difficulty.level == 2
                            ? 'Biraz daha dikkatli ol! 👀'
                            : 'Son seviye! Gözlerini dört aç! 🔍',
                        style: const TextStyle(
                          fontSize: 17,
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
}
