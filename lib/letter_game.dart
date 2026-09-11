import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'achievement_manager.dart';
import 'game_id.dart';
import 'game_kit.dart';
import 'sound_manager.dart';

// =============================================================
// HARF YERLEŞTİRME OYUNU
// =============================================================

class LetterGame extends StatefulWidget {
  const LetterGame({super.key});

  @override
  State<LetterGame> createState() => _LetterGameState();
}

// =============================================================
// KELİME MODELİ
// =============================================================

class LetterWord {
  final String word;
  final String emoji;
  final String hint;
  final int difficulty;

  const LetterWord({
    required this.word,
    required this.emoji,
    required this.hint,
    required this.difficulty,
  });
}

// =============================================================
// SÜRÜKLENEN HARF MODELİ
// =============================================================

class LetterTile {
  final String letter;
  final int id;

  const LetterTile({
    required this.letter,
    required this.id,
  });
}

// =============================================================
// OYUN STATE
// =============================================================

class _LetterGameState extends State<LetterGame>
    with TickerProviderStateMixin, GameSessionMixin {
  final Random _random = Random();

  // -------------------------------------------------------------
  // OYUN AYARLARI
  // -------------------------------------------------------------

  static const int _totalQuestions = 10;
  static const int _maxLives = 3;
  static const int _gameSeconds = 150;

  // -------------------------------------------------------------
  // KELİME HAVUZU
  // -------------------------------------------------------------

  final List<LetterWord> _wordPool = const [
    // ===========================================================
    // KOLAY
    // ===========================================================

    LetterWord(
      word: 'EV',
      emoji: '🏠',
      hint: 'İçinde yaşadığımız yer.',
      difficulty: 1,
    ),
    LetterWord(
      word: 'AYI',
      emoji: '🐻',
      hint: 'Ormanda yaşayan büyük bir hayvan.',
      difficulty: 1,
    ),
    LetterWord(
      word: 'ARI',
      emoji: '🐝',
      hint: 'Bal yapan küçük bir canlı.',
      difficulty: 1,
    ),
    LetterWord(
      word: 'ELMA',
      emoji: '🍎',
      hint: 'Tatlı ve sulu bir meyve.',
      difficulty: 1,
    ),
    LetterWord(
      word: 'KEDI',
      emoji: '🐱',
      hint: 'Miyavlayan sevimli bir hayvan.',
      difficulty: 1,
    ),
    LetterWord(
      word: 'KUŞ',
      emoji: '🐦',
      hint: 'Kanatlarıyla uçabilen bir hayvan.',
      difficulty: 1,
    ),

    // ===========================================================
    // ORTA
    // ===========================================================

    LetterWord(
      word: 'FIL',
      emoji: '🐘',
      hint: 'Çok büyük, hortumlu bir hayvan.',
      difficulty: 2,
    ),
    LetterWord(
      word: 'BALIK',
      emoji: '🐟',
      hint: 'Suda yaşayan bir hayvan.',
      difficulty: 2,
    ),
    LetterWord(
      word: 'KALEM',
      emoji: '✏️',
      hint: 'Yazı yazmak için kullanılır.',
      difficulty: 2,
    ),
    LetterWord(
      word: 'KITAP',
      emoji: '📚',
      hint: 'Okumak için kullanılır.',
      difficulty: 2,
    ),
    LetterWord(
      word: 'ARABA',
      emoji: '🚗',
      hint: 'Yollarda kullanılan bir taşıt.',
      difficulty: 2,
    ),
    LetterWord(
      word: 'ÇİÇEK',
      emoji: '🌸',
      hint: 'Bahçelerde ve doğada yetişir.',
      difficulty: 2,
    ),

    // ===========================================================
    // ZOR
    // ===========================================================

    LetterWord(
      word: 'KELEBEK',
      emoji: '🦋',
      hint: 'Renkli kanatları olan bir canlı.',
      difficulty: 3,
    ),
    LetterWord(
      word: 'DONDURMA',
      emoji: '🍦',
      hint: 'Soğuk ve tatlı bir yiyecek.',
      difficulty: 3,
    ),
    LetterWord(
      word: 'YILDIZ',
      emoji: '⭐',
      hint: 'Gece gökyüzünde parlar.',
      difficulty: 3,
    ),
    LetterWord(
      word: 'KAPLUMBAĞA',
      emoji: '🐢',
      hint: 'Sırtında sert bir kabuk taşır.',
      difficulty: 3,
    ),
    LetterWord(
      word: 'GOKKUSAGI',
      emoji: '🌈',
      hint: 'Yağmurdan sonra gökyüzünde görülebilir.',
      difficulty: 3,
    ),
  ];

  // -------------------------------------------------------------
  // OYUN DEĞİŞKENLERİ
  // -------------------------------------------------------------

  int _questionIndex = 0;
  int _score = 0;
  int _lives = _maxLives;
  int _secondsLeft = _gameSeconds;

  int _correctAnswers = 0;
  int _wrongAnswers = 0;

  LetterWord? _currentWord;

  List<LetterTile> _availableLetters = [];
  List<String?> _placedLetters = [];

  final Set<String> _usedWords = {};

  Timer? _timer;

  bool _isChecking = false;
  bool _showCorrect = false;
  bool _showWrong = false;
  bool _gameFinished = false;

  // -------------------------------------------------------------
  // GÜNLÜK SÜRE OTURUMU
  // -------------------------------------------------------------

  @override
  GameId get game => GameId.letter;

  @override
  String get timeUpMessage =>
      'Harf oyunu için belirlenen günlük süreyi kullandın. 🌙';

  @override
  int get currentScore => _score;

  @override
  bool get canShowTimeUpDialog => !_gameFinished;

  // -------------------------------------------------------------
  // ANİMASYONLAR
  // -------------------------------------------------------------

  late AnimationController _pageController;
  late Animation<double> _pageAnimation;

  late AnimationController _correctController;
  late Animation<double> _correctScale;

  late AnimationController _wrongController;
  late Animation<double> _wrongShake;

  // -------------------------------------------------------------
  // INIT
  // -------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _pageAnimation = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOutCubic,
    );

    _correctController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _correctScale = CurvedAnimation(
      parent: _correctController,
      curve: Curves.elasticOut,
    );

    _wrongController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _wrongShake = CurvedAnimation(
      parent: _wrongController,
      curve: Curves.easeInOut,
    );

    startGameSession();

    _startGame();
  }

  // =============================================================
  // OYUNU BAŞLAT
  // =============================================================

  void _startGame() {
    _timer?.cancel();

    _usedWords.clear();

    _questionIndex = 0;
    _score = 0;
    _lives = _maxLives;
    _secondsLeft = _gameSeconds;
    _correctAnswers = 0;
    _wrongAnswers = 0;

    _gameFinished = false;
    _isChecking = false;
    _showCorrect = false;
    _showWrong = false;

    _loadQuestion();

    _startTimer();

    _pageController.forward(from: 0);
  }

  // =============================================================
  // SORU YÜKLE
  // =============================================================

  void _loadQuestion() {
    if (_questionIndex >= _totalQuestions) {
      _finishGame();
      return;
    }

    List<LetterWord> available = _wordPool
        .where(
          (item) => !_usedWords.contains(item.word),
    )
        .toList();

    if (available.isEmpty) {
      _usedWords.clear();
      available = List<LetterWord>.from(_wordPool);
    }

    // Soru ilerledikçe zorluk artıyor.
    int wantedDifficulty;

    if (_questionIndex < 3) {
      wantedDifficulty = 1;
    } else if (_questionIndex < 7) {
      wantedDifficulty = 2;
    } else {
      wantedDifficulty = 3;
    }

    List<LetterWord> difficultyPool = available
        .where(
          (item) => item.difficulty == wantedDifficulty,
    )
        .toList();

    if (difficultyPool.isEmpty) {
      difficultyPool = available;
    }

    final word =
    difficultyPool[_random.nextInt(difficultyPool.length)];

    _usedWords.add(word.word);

    final normalizedWord = _normalizeWord(word.word);

    final tiles = <LetterTile>[];

    for (int i = 0; i < normalizedWord.length; i++) {
      tiles.add(
        LetterTile(
          letter: normalizedWord[i],
          id: i,
        ),
      );
    }

    // Orta ve zor seviyede ekstra yanlış harfler.
    if (word.difficulty >= 2) {
      final extraLetters = [
        'A',
        'E',
        'I',
        'K',
        'L',
        'M',
        'N',
        'R',
        'S',
        'T',
      ];

      final extraCount =
      word.difficulty == 2 ? 1 : 2;

      for (int i = 0; i < extraCount; i++) {
        tiles.add(
          LetterTile(
            letter: extraLetters[
            _random.nextInt(extraLetters.length)],
            id: normalizedWord.length + i,
          ),
        );
      }
    }

    tiles.shuffle(_random);

    setState(() {
      _currentWord = word;
      _availableLetters = tiles;
      _placedLetters = List<String?>.filled(
        normalizedWord.length,
        null,
      );

      _isChecking = false;
      _showCorrect = false;
      _showWrong = false;
    });

    _pageController.forward(from: 0);
  }

  // =============================================================
  // TÜRKÇE KARAKTERLERİ NORMALİZE ET
  // =============================================================

  String _normalizeWord(String word) {
    return word
        .toUpperCase()
        .replaceAll('İ', 'İ')
        .replaceAll('I', 'I')
        .replaceAll('Ğ', 'Ğ')
        .replaceAll('Ü', 'Ü')
        .replaceAll('Ş', 'Ş')
        .replaceAll('Ö', 'Ö')
        .replaceAll('Ç', 'Ç');
  }

  // =============================================================
  // ZAMANLAYICI
  // =============================================================

  void _startTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (!mounted || _gameFinished) {
          timer.cancel();
          return;
        }

        if (_secondsLeft <= 0) {
          timer.cancel();
          _finishGame();
          return;
        }

        setState(() {
          _secondsLeft--;
        });
      },
    );
  }

  // =============================================================
  // HARFİ YUVAYA BIRAK
  // =============================================================

  void _placeLetter(
      LetterTile tile,
      int targetIndex,
      ) {
    if (_isChecking || _gameFinished) {
      return;
    }

    if (_placedLetters[targetIndex] != null) {
      return;
    }

    setState(() {
      _placedLetters[targetIndex] = tile.letter;

      _availableLetters.removeWhere(
            (item) => item.id == tile.id,
      );
    });

    // Bütün kutular dolduysa kontrol et.
    if (!_placedLetters.contains(null)) {
      Future.delayed(
        const Duration(milliseconds: 250),
        _checkAnswer,
      );
    }
  }

  // =============================================================
  // YUVADAN HARFİ GERİ AL
  // =============================================================

  void _removePlacedLetter(
      int index,
      ) {
    if (_isChecking ||
        _gameFinished ||
        _placedLetters[index] == null) {
      return;
    }

    final letter =
    _placedLetters[index]!;

    final newId = DateTime.now()
        .microsecondsSinceEpoch;

    setState(() {
      _placedLetters[index] = null;

      _availableLetters.add(
        LetterTile(
          letter: letter,
          id: newId,
        ),
      );
    });
  }

  // =============================================================
  // CEVABI KONTROL ET
  // =============================================================

  Future<void> _checkAnswer() async {
    if (_currentWord == null ||
        _isChecking ||
        _placedLetters.contains(null)) {
      return;
    }

    _isChecking = true;

    final answer = _placedLetters
        .whereType<String>()
        .join();

    final correct =
        answer.toUpperCase() ==
            _normalizeWord(
              _currentWord!.word,
            );

    if (correct) {
      await _correctAnswer();
    } else {
      await _wrongAnswer();
    }
  }

  // =============================================================
  // DOĞRU
  // =============================================================

  Future<void> _correctAnswer() async {
    if (!mounted) return;

    setState(() {
      _correctAnswers++;
      _score += _calculateScore();
      _showCorrect = true;
    });

    _correctController.forward(from: 0);

    await SoundManager.playCorrect();

    await Future.delayed(
      const Duration(milliseconds: 950),
    );

    if (!mounted) return;

    _questionIndex++;

    _loadQuestion();
  }

  // =============================================================
  // YANLIŞ
  // =============================================================

  Future<void> _wrongAnswer() async {
    if (!mounted) return;

    setState(() {
      _wrongAnswers++;
      _lives--;
      _showWrong = true;
    });

    _wrongController.forward(from: 0);

    await SoundManager.playWrong();

    await Future.delayed(
      const Duration(milliseconds: 800),
    );

    if (!mounted) return;

    if (_lives <= 0) {
      _finishGame();
      return;
    }

    // Yanlış cevapta harfleri geri bırak.
    final currentWord = _currentWord;

    if (currentWord == null) return;

    final normalized =
    _normalizeWord(currentWord.word);

    final newTiles = <LetterTile>[];

    for (int i = 0; i < normalized.length; i++) {
      newTiles.add(
        LetterTile(
          letter: normalized[i],
          id: DateTime.now()
              .microsecondsSinceEpoch +
              i,
        ),
      );
    }

    if (currentWord.difficulty >= 2) {
      final extraLetters = [
        'A',
        'E',
        'I',
        'K',
        'L',
        'M',
        'N',
        'R',
        'S',
        'T',
      ];

      final extraCount =
      currentWord.difficulty == 2 ? 1 : 2;

      for (int i = 0; i < extraCount; i++) {
        newTiles.add(
          LetterTile(
            letter: extraLetters[
            _random.nextInt(extraLetters.length)],
            id: DateTime.now()
                .microsecondsSinceEpoch +
                normalized.length +
                i +
                100,
          ),
        );
      }
    }

    newTiles.shuffle(_random);

    setState(() {
      _placedLetters = List<String?>.filled(
        normalized.length,
        null,
      );
      _availableLetters = newTiles;
      _showWrong = false;
      _isChecking = false;
    });
  }

  // =============================================================
  // PUAN
  // =============================================================

  int _calculateScore() {
    int base;

    switch (_currentWord?.difficulty) {
      case 3:
        base = 30;
        break;
      case 2:
        base = 20;
        break;
      default:
        base = 10;
    }

    final timeBonus =
    min(_secondsLeft ~/ 5, 15);

    return base + timeBonus;
  }

  // =============================================================
  // OYUNU BİTİR
  // =============================================================

  Future<void> _finishGame() async {
    if (_gameFinished) return;

    _gameFinished = true;
    _timer?.cancel();

    await AchievementManager.unlock('first_step');
    await AchievementManager.unlock('letter_master');
    await AchievementManager.markGamePlayed('letter');

    await SoundManager.playGameOver();

    if (!mounted) return;

    setState(() {});

    await Future.delayed(
      const Duration(milliseconds: 350),
    );

    if (!mounted) return;

    _showResultDialog();
  }

  // =============================================================
  // SONUÇ DİYALOĞU
  // =============================================================

  void _showResultDialog() {
    final attempted =
        _correctAnswers + _wrongAnswers;

    final accuracy = attempted == 0
        ? 0
        : ((_correctAnswers / attempted) * 100)
        .round();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Oyun Sonucu',
      barrierColor:
      Colors.black.withValues(alpha: 0.55),
      transitionDuration:
      const Duration(milliseconds: 400),
      pageBuilder:
          (
          context,
          animation,
          secondaryAnimation,
          ) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: Container(
                margin:
                const EdgeInsets.all(22),
                padding:
                const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFE0FFE3),
                  borderRadius:
                  BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color:
                      Colors.black.withValues(
                        alpha: 0.16,
                      ),
                      blurRadius: 30,
                      offset:
                      const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    const Text(
                      '🏆',
                      style: TextStyle(
                        fontSize: 52,
                      ),
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    const Text(
                      'Harf Ustası!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight:
                        FontWeight.w900,
                        color:
                        Color(0xFF259242),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const Text(
                      'Harika bir çalışma yaptın!',
                      style: TextStyle(
                        fontSize: 12.5,
                        color:
                        Color(0xFF23D63E),
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    Row(
                      children: [
                        _resultCard(
                          '⭐',
                          'Skor',
                          '$_score',
                        ),
                        const SizedBox(
                          width: 9,
                        ),
                        _resultCard(
                          '🎯',
                          'Doğru',
                          '$_correctAnswers',
                        ),
                        const SizedBox(
                          width: 9,
                        ),
                        _resultCard(
                          '💯',
                          'Başarı',
                          '%$accuracy',
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      width:
                      double.infinity,
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 15,
                      ),
                      decoration:
                      BoxDecoration(
                        gradient:
                        const LinearGradient(
                          colors: [
                            Color(0xFFE0FFE3),
                            Color(0xFFE9F8FF),
                          ],
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          17,
                        ),
                      ),
                      child: Text(
                        _resultMessage(
                          accuracy,
                        ),
                        textAlign:
                        TextAlign.center,
                        style:
                        const TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Color(0xFF279A45),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width:
                      double.infinity,
                      height: 52,
                      child:
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );
                          _startGame();
                        },
                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          const Color(
                            0xFF23D83E,
                          ),
                          foregroundColor:
                          Colors.white,
                          elevation: 4,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              17,
                            ),
                          ),
                        ),
                        child:
                        const Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                          children: [
                            Text(
                              'Tekrar Oyna',
                              style:
                              TextStyle(
                                fontSize: 14,
                                fontWeight:
                                FontWeight.w900,
                              ),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              '🔄',
                              style:
                              TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 9,
                    ),
                    SizedBox(
                      width:
                      double.infinity,
                      height: 48,
                      child:
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );
                          Navigator.pop(
                            context,
                          );
                        },
                        style:
                        OutlinedButton
                            .styleFrom(
                          foregroundColor:
                          const Color(
                            0xFF23D83E,
                          ),
                          side:
                          const BorderSide(
                            color: Color(
                              0xFFC9F9CE,
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
                        child:
                        const Text(
                          'Ana Sayfaya Dön',
                          style:
                          TextStyle(
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // SONUÇ MESAJI
  // =============================================================

  String _resultMessage(
      int accuracy,
      ) {
    if (accuracy >= 90) {
      return '🌟 Muhteşem! Harfleri çok iyi tanıyorsun!';
    }

    if (accuracy >= 70) {
      return '👏 Çok güzel! Kelimeleri oluşturmada harikasın!';
    }

    if (accuracy >= 50) {
      return '💪 Güzel deneme! Biraz daha pratik yapabilirsin!';
    }

    return '🌱 Pes etme! Tekrar dene ve harfleri keşfet!';
  }

  // =============================================================
  // HARF KARTI
  // =============================================================

  Widget _letterTile(
      LetterTile tile,
      ) {
    return LongPressDraggable<LetterTile>(
      data: tile,

      delay: const Duration(
        milliseconds: 120,
      ),

      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.08,
          child: _tileContainer(
            tile.letter,
            dragging: true,
          ),
        ),
      ),

      childWhenDragging:
      Opacity(
        opacity: 0.25,
        child: _tileContainer(
          tile.letter,
        ),
      ),

      onDragStarted: () {
        if (_isChecking ||
            _gameFinished) {
          return;
        }
      },

      child: _tileContainer(
        tile.letter,
      ),
    );
  }

  // =============================================================
  // HARF KARTI TASARIMI
  // =============================================================

  Widget _tileContainer(
      String letter, {
        bool dragging = false,
      }) {
    return AnimatedContainer(
      duration:
      const Duration(milliseconds: 180),
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFE6FAE8),
          ],
        ),
        borderRadius:
        BorderRadius.circular(19),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color:
            const Color(0xFF23D83E)
                .withValues(
              alpha: dragging ? 0.18 : 0.08,
            ),
            blurRadius:
            dragging ? 18 : 9,
            offset:
            const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 23,
            fontWeight:
            FontWeight.w900,
            color:
            Color(0xFF259242),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // HEDEF KUTUSU
  // =============================================================

  Widget _dropTarget(
      int index,
      ) {
    final letter =
    _placedLetters[index];

    return DragTarget<LetterTile>(
      onWillAcceptWithDetails:
          (details) {
        if (_isChecking ||
            _gameFinished) {
          return false;
        }

        return letter == null;
      },
      onAcceptWithDetails:
          (details) {
        _placeLetter(
          details.data,
          index,
        );
      },
      builder:
          (
          context,
          candidateData,
          rejectedData,
          ) {
        final isHovering =
            candidateData.isNotEmpty;

        return GestureDetector(
          onTap: letter == null
              ? null
              : () {
            _removePlacedLetter(
              index,
            );
          },
          child: AnimatedContainer(
            duration:
            const Duration(
              milliseconds: 180,
            ),
            width: 58,
            height: 64,
            decoration:
            BoxDecoration(
              color: letter == null
                  ? isHovering
                  ? const Color(
                0xFFD8FFDC,
              )
                  : Colors.white
                  .withValues(
                alpha: 0.68,
              )
                  : const Color(
                0xFFD8FFDC,
              ),
              borderRadius:
              BorderRadius.circular(
                17,
              ),
              border: Border.all(
                color: isHovering
                    ? const Color(
                  0xFF5FE573,
                )
                    : letter == null
                    ? Colors.white
                    : const Color(
                  0xFFB8F7BE,
                ),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  const Color(
                    0xFF23D83E,
                  ).withValues(
                    alpha: isHovering
                        ? 0.15
                        : 0.04,
                  ),
                  blurRadius:
                  isHovering ? 14 : 7,
                  offset:
                  const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: letter == null
                  ? Icon(
                Icons.add_rounded,
                color:
                const Color(
                  0xFF90ED9C,
                ),
                size: 22,
              )
                  : Text(
                letter,
                style:
                const TextStyle(
                  fontSize: 21,
                  fontWeight:
                  FontWeight.w900,
                  color:
                  Color(
                    0xFF2AA84C,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // SONUÇ KARTI
  // =============================================================

  Widget _resultCard(
      String emoji,
      String title,
      String value,
      ) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color:
          const Color(0xFFE7F8E9),
          borderRadius:
          BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style:
              const TextStyle(
                fontSize: 21,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              value,
              style:
              const TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight.w900,
                color:
                Color(0xFF259242),
              ),
            ),
            const SizedBox(
              height: 2,
            ),
            Text(
              title,
              style:
              const TextStyle(
                fontSize: 9,
                color:
                Color(0xFF2CDD47),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // İSTATİSTİK KARTI
  // =============================================================

  Widget _statChip(
      String emoji,
      String value,
      ) {
    return Container(
      height: 42,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
      ),
      decoration: BoxDecoration(
        color:
        Colors.white.withValues(
          alpha: 0.82,
        ),
        borderRadius:
        BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style:
            const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            value,
            style:
            const TextStyle(
              fontSize: 11,
              fontWeight:
              FontWeight.w900,
              color:
              Color(0xFF23D83E),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // SÜRE
  // =============================================================

  String _formatTime(
      int seconds,
      ) {
    final minutes =
        seconds ~/ 60;

    final remaining =
        seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final word = _currentWord;

    if (word == null) {
      return const Scaffold(
        backgroundColor:
        Color(0xFFFFFAF5),
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // =====================================================
            // YUMUŞAK ARKA PLAN
            // =====================================================

            Positioned(
              top: -70,
              left: -55,
              child: Container(
                width: 175,
                height: 175,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFD5FFD9,
                  ).withValues(
                    alpha: 0.62,
                  ),
                  shape:
                  BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              top: -50,
              right: -45,
              child: Container(
                width: 145,
                height: 145,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFDDF1FF,
                  ).withValues(
                    alpha: 0.70,
                  ),
                  shape:
                  BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              bottom: -70,
              right: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFDFFFE2,
                  ).withValues(
                    alpha: 0.60,
                  ),
                  shape:
                  BoxShape.circle,
                ),
              ),
            ),

            // =====================================================
            // ANA İÇERİK
            // =====================================================

            FadeTransition(
              opacity:
              _pageAnimation,
              child: Column(
                children: [
                  // =================================================
                  // ÜST BAR
                  // =================================================

                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(
                      18,
                      12,
                      18,
                      0,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _timer?.cancel();

                            Navigator.pop(
                              context,
                            );
                          },
                          child:
                          Container(
                            width: 42,
                            height: 42,
                            decoration:
                            BoxDecoration(
                              color: Colors
                                  .white
                                  .withValues(
                                alpha: 0.90,
                              ),
                              shape:
                              BoxShape.circle,
                            ),
                            child:
                            const Icon(
                              Icons
                                  .arrow_back_ios_new_rounded,
                              size: 17,
                              color: Color(
                                0xFF21823B,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 13,
                        ),

                        const Expanded(
                          child:
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                'Harfleri Yerleştir',
                                style:
                                TextStyle(
                                  fontSize:
                                  20,
                                  fontWeight:
                                  FontWeight
                                      .w900,
                                  color:
                                  Color(
                                    0xFF259242,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 2,
                              ),
                              Text(
                                'Harfleri doğru sıraya koy! 🔤',
                                style:
                                TextStyle(
                                  fontSize:
                                  10.5,
                                  fontWeight:
                                  FontWeight
                                      .w600,
                                  color:
                                  Color(
                                    0xFF30DD4A,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Row(
                          children:
                          List.generate(
                            _maxLives,
                                (index) {
                              return Padding(
                                padding:
                                const EdgeInsets
                                    .only(
                                  left: 3,
                                ),
                                child:
                                AnimatedOpacity(
                                  duration:
                                  const Duration(
                                    milliseconds:
                                    200,
                                  ),
                                  opacity:
                                  index <
                                      _lives
                                      ? 1
                                      : 0.20,
                                  child:
                                  const Text(
                                    '❤️',
                                    style:
                                    TextStyle(
                                      fontSize:
                                      18,
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

                  const SizedBox(
                    height: 14,
                  ),

                  // =================================================
                  // SKOR + SÜRE + İLERLEME
                  // =================================================

                  Padding(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 18,
                    ),
                    child: Row(
                      children: [
                        _statChip(
                          '⭐',
                          '$_score',
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        _statChip(
                          '⏱️',
                          _formatTime(
                            _secondsLeft,
                          ),
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        Expanded(
                          child:
                          Container(
                            height: 42,
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 12,
                            ),
                            decoration:
                            BoxDecoration(
                              color: Colors
                                  .white
                                  .withValues(
                                alpha: 0.82,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                15,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🎯',
                                  style:
                                  TextStyle(
                                    fontSize:
                                    16,
                                  ),
                                ),
                                const SizedBox(
                                  width: 6,
                                ),
                                Expanded(
                                  child:
                                  ClipRRect(
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      10,
                                    ),
                                    child:
                                    LinearProgressIndicator(
                                      value:
                                      (_questionIndex /
                                          _totalQuestions)
                                          .clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      minHeight:
                                      8,
                                      backgroundColor:
                                      const Color(
                                        0xFFDDFBE0,
                                      ),
                                      valueColor:
                                      const AlwaysStoppedAnimation<
                                          Color>(
                                        Color(
                                          0xFF53E366,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 7,
                                ),
                                Text(
                                  '${_questionIndex + 1}/$_totalQuestions',
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    10,
                                    fontWeight:
                                    FontWeight
                                        .w900,
                                    color:
                                    Color(
                                      0xFF23D83E,
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

                  const SizedBox(
                    height: 14,
                  ),

                  // =================================================
                  // OYUN ALANI
                  // =================================================

                  Expanded(
                    child:
                    SingleChildScrollView(
                      physics:
                      const BouncingScrollPhysics(),
                      padding:
                      const EdgeInsets
                          .fromLTRB(
                        18,
                        0,
                        18,
                        18,
                      ),
                      child: Column(
                        children: [
                          // =========================================
                          // GÖRSEL + İPUCU
                          // =========================================

                          Container(
                            width:
                            double.infinity,
                            padding:
                            const EdgeInsets
                                .fromLTRB(
                              20,
                              20,
                              20,
                              18,
                            ),
                            decoration:
                            BoxDecoration(
                              gradient:
                              const LinearGradient(
                                begin:
                                Alignment
                                    .topLeft,
                                end:
                                Alignment
                                    .bottomRight,
                                colors: [
                                  Color(
                                    0xFFD8FFDC,
                                  ),
                                  Color(
                                    0xFFDDF5FF,
                                  ),
                                ],
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                28,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  const Color(
                                    0xFF3EE053,
                                  ).withValues(
                                    alpha: 0.10,
                                  ),
                                  blurRadius:
                                  16,
                                  offset:
                                  const Offset(
                                    0,
                                    7,
                                  ),
                                ),
                              ],
                            ),
                            child:
                            Column(
                              children: [
                                Container(
                                  width: 112,
                                  height: 112,
                                  decoration:
                                  BoxDecoration(
                                    color: Colors
                                        .white
                                        .withValues(
                                      alpha: 0.76,
                                    ),
                                    shape:
                                    BoxShape
                                        .circle,
                                  ),
                                  child:
                                  Center(
                                    child:
                                    Text(
                                      word
                                          .emoji,
                                      style:
                                      const TextStyle(
                                        fontSize:
                                        65,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 12,
                                ),

                                const Text(
                                  'Bu nedir?',
                                  style:
                                  TextStyle(
                                    fontSize:
                                    19,
                                    fontWeight:
                                    FontWeight
                                        .w900,
                                    color:
                                    Color(
                                      0xFF20813A,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Text(
                                  word.hint,
                                  textAlign:
                                  TextAlign
                                      .center,
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    11.5,
                                    height:
                                    1.35,
                                    color:
                                    Color(
                                      0xFF716277,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          // =========================================
                          // HEDEF KUTULARI
                          // =========================================

                          Container(
                            width:
                            double.infinity,
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration:
                            BoxDecoration(
                              color: Colors
                                  .white
                                  .withValues(
                                alpha: 0.70,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                24,
                              ),
                              border:
                              Border.all(
                                color:
                                Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child:
                            Column(
                              children: [
                                const Text(
                                  'Kelimeyi oluştur',
                                  style:
                                  TextStyle(
                                    fontSize:
                                    12,
                                    fontWeight:
                                    FontWeight
                                        .w800,
                                    color:
                                    Color(
                                      0xFF75687A,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 11,
                                ),

                                SingleChildScrollView(
                                  scrollDirection:
                                  Axis.horizontal,
                                  child:
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                    children:
                                    List.generate(
                                      _placedLetters
                                          .length,
                                          (index) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                            horizontal:
                                            4,
                                          ),
                                          child:
                                          _dropTarget(
                                            index,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                const Text(
                                  '💡 Yerleştirdiğin harfe dokunarak geri alabilirsin.',
                                  textAlign:
                                  TextAlign
                                      .center,
                                  style:
                                  TextStyle(
                                    fontSize:
                                    9.5,
                                    fontWeight:
                                    FontWeight
                                        .w600,
                                    color:
                                    Color(
                                      0xFF9A8D9F,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          // =========================================
                          // HARFLER
                          // =========================================

                          Container(
                            width:
                            double.infinity,
                            padding:
                            const EdgeInsets
                                .all(
                              15,
                            ),
                            decoration:
                            BoxDecoration(
                              color: Colors
                                  .white
                                  .withValues(
                                alpha: 0.68,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                25,
                              ),
                              border:
                              Border.all(
                                color:
                                Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child:
                            Wrap(
                              alignment:
                              WrapAlignment
                                  .center,
                              spacing: 9,
                              runSpacing: 10,
                              children:
                              _availableLetters
                                  .map(
                                    (tile) =>
                                    _letterTile(
                                      tile,
                                    ),
                              )
                                  .toList(),
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          // =========================================
                          // ALT BİLGİ
                          // =========================================

                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                            decoration:
                            BoxDecoration(
                              color: Colors
                                  .white
                                  .withValues(
                                alpha: 0.55,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                17,
                              ),
                            ),
                            child:
                            const Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                              children: [
                                Text(
                                  '👆',
                                  style:
                                  TextStyle(
                                    fontSize:
                                    17,
                                  ),
                                ),
                                SizedBox(
                                  width: 7,
                                ),
                                Flexible(
                                  child:
                                  Text(
                                    'Harfi basılı tut, doğru kutuya sürükle ve bırak!',
                                    textAlign:
                                    TextAlign
                                        .center,
                                    style:
                                    TextStyle(
                                      fontSize:
                                      10.5,
                                      fontWeight:
                                      FontWeight
                                          .w600,
                                      color:
                                      Color(
                                        0xFF807486,
                                      ),
                                    ),
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

            // =====================================================
            // DOĞRU CEVAP
            // =====================================================

            if (_showCorrect)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.white
                        .withValues(alpha: 0.22),
                    child: Center(
                      child:
                      ScaleTransition(
                        scale:
                        _correctScale,
                        child:
                        Container(
                          width: 155,
                          height: 155,
                          decoration:
                          BoxDecoration(
                            color:
                            Colors.white,
                            shape:
                            BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                const Color(
                                  0xFF8CCF9A,
                                ).withValues(
                                  alpha: 0.30,
                                ),
                                blurRadius:
                                30,
                                spreadRadius:
                                5,
                              ),
                            ],
                          ),
                          child:
                          const Column(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                            children: [
                              Text(
                                '🎉',
                                style:
                                TextStyle(
                                  fontSize:
                                  48,
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text(
                                'Harika!',
                                style:
                                TextStyle(
                                  fontSize:
                                  19,
                                  fontWeight:
                                  FontWeight
                                      .w900,
                                  color:
                                  Color(
                                    0xFF4B8B5B,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // =====================================================
            // YANLIŞ CEVAP
            // =====================================================

            if (_showWrong)
              Positioned.fill(
                child: IgnorePointer(
                  child:
                  AnimatedBuilder(
                    animation:
                    _wrongShake,
                    builder:
                        (
                        context,
                        child,
                        ) {
                      final offset =
                          sin(
                            _wrongShake
                                .value *
                                pi *
                                6,
                          ) *
                              7;

                      return Container(
                        color:
                        const Color(
                          0xFFFFDADA,
                        ).withValues(
                          alpha: 0.16,
                        ),
                        child:
                        Center(
                          child:
                          Transform
                              .translate(
                            offset:
                            Offset(
                              offset,
                              0,
                            ),
                            child:
                            Container(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal:
                                27,
                                vertical:
                                18,
                              ),
                              decoration:
                              BoxDecoration(
                                color:
                                Colors
                                    .white,
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  22,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    const Color(
                                      0xFFE38C8C,
                                    ).withValues(
                                      alpha: 0.20,
                                    ),
                                    blurRadius:
                                    20,
                                    offset:
                                    const Offset(
                                      0,
                                      7,
                                    ),
                                  ),
                                ],
                              ),
                              child:
                              const Column(
                                mainAxisSize:
                                MainAxisSize
                                    .min,
                                children: [
                                  Text(
                                    '💪',
                                    style:
                                    TextStyle(
                                      fontSize:
                                      38,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    'Tekrar dene!',
                                    style:
                                    TextStyle(
                                      fontSize:
                                      16,
                                      fontWeight:
                                      FontWeight
                                          .w900,
                                      color:
                                      Color(
                                        0xFF9B5555,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _timer?.cancel();

    _pageController.dispose();
    _correctController.dispose();
    _wrongController.dispose();

    // gameTimer'i GameSessionMixin kapatir.
    super.dispose();
  }
}