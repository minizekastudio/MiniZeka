import 'package:flutter/material.dart';

import '../achievement_manager.dart';
import '../app_theme.dart';
import '../game_id.dart';
import '../game_kit.dart';
import '../sound_manager.dart';

// =====================================================
// 5 - MANTIK OYUNU
// =====================================================

class LogicGame extends StatefulWidget {
  const LogicGame({super.key});

  @override
  State<LogicGame> createState() => _LogicGameState();
}

class _LogicGameState extends State<LogicGame> with GameSessionMixin {
  // ---- GameSessionMixin sozlesmesi ----

  @override
  GameId get game => GameId.logic;

  @override
  String get timeUpMessage =>
      'Mantık oyunu için belirlenen günlük süreyi kullandın. 🌙';

  @override
  int get currentScore => score;

  /// Oyun bittiyse sure uyarisi gosterme.
  @override
  bool get canShowTimeUpDialog => !finalDialogShown;

  @override
  void onChildAgeLoaded() => _applyAgeQuestions();

  /// Yasa uygun soru havuzunu secip karistirir.
  /// Su an hangi havuzdan soru geldigi. Yas bandi tabanidir, cocuk
  /// seviye atladikca bir ust havuza kayar.
  int _poolInUse = 0;

  int get _wantedPool => difficulty.scaled(
        const [0, 1, 2, 3],
        max: ageQuestionPools.length - 1,
      );

  void _applyAgeQuestions() {
    _poolInUse = _wantedPool;

    questions = List<Map<String, dynamic>>.from(
      ageQuestionPools[_poolInUse],
    );

    questions.shuffle();

    question = 1;
    score = 0;
    answering = false;
  }

  /// Seviye yukseldiyse kalan sorulari bir ust havuzdan doldurur.
  /// Soru sayaci korunur; yalnizca bundan sonraki sorular degisir.
  void _refreshPoolIfLevelChanged() {
    if (_wantedPool == _poolInUse) return;

    _poolInUse = _wantedPool;

    final fresh = List<Map<String, dynamic>>.from(
      ageQuestionPools[_poolInUse],
    )..shuffle();

    // Cevaplanmis sorular yerinde kalsin, gerisi yeni havuzdan.
    questions = [
      ...questions.take(question),
      ...fresh.where((q) => !questions.take(question).contains(q)),
    ];
  }

  int question = 1;
  int score = 0;

  bool answering = false;
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

    // Sorulari hemen kur: yas bilgisi asenkron geldigi icin ilk build
    // ondan once calisiyor ve 'questions' atanmamis kaliyordu.
    _applyAgeQuestions();

    startGameSession();
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

    final earned = correct ? difficulty.level * 10 : 0;

    if (correct) {
      score += earned;
      difficulty.correct();
    } else {
      difficulty.wrong();
    }

    // Seviye yukseldiyse kalan sorular daha zor havuzdan gelsin.
    _refreshPoolIfLevelChanged();

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
    // Back continues like the button. Closing only the dialog left the
    // question answered and every option ignoring taps.
    void continueAfterAnswer(BuildContext dialogContext) {
      Navigator.pop(dialogContext);

      if (question == 5) {
        _showFinalResult();
      } else {
        setState(() {
          question++;
          answering = false;
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
                    fontSize: 17,
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
                  height: Brand.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () => continueAfterAnswer(dialogContext),
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

  void _showFinalResult() {
    if (finalDialogShown) return;

    finalDialogShown = true;

    SoundManager.playGameOver();

    AchievementManager.unlock('logic_master');
    AchievementManager.unlock('first_step');
    AchievementManager.markGamePlayed(game);

    final message = score >= 40
        ? 'Muhteşem bir mantık yürüttün! 🌟'
        : 'Biraz daha pratik yaparsan daha da iyi olacaksın! 💪';

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
                    fontSize: 17,
                    height: 1.4,
                    color: Color(0xFF71806A),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    GameResultBox(
                      palette: GamePalette.logic,
                      emoji: '⭐',
                      title: 'Puan',
                      value: '$score',
                    ),

                    const SizedBox(width: 8),

                    GameResultBox(
                      palette: GamePalette.logic,
                      emoji: '🎯',
                      title: 'Soru',
                      value: '5 / 5',
                    ),

                    const SizedBox(width: 8),

                    GameResultBox(
                      palette: GamePalette.logic,
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
                  height: Brand.buttonHeight,
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
                        timeUpDialogShown = false;

                        // Soru havuzu yas bandindan; band tanimi difficulty.dart'ta tek yerde.
                        final poolIndex = ageBand.step;

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
                        fontSize: 18,
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
    final options = currentOptions;

    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: GameAppBarTitle(game: game),
        centerTitle: true,
        actions: [
          GameHelpButton(game: game),
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

            GameTimeBar(
              palette: palette,
              progress: timeProgress,
              remaining: gameTimer.formattedRemaining,
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
                      fontSize: 17,
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
}
