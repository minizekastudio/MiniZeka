import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'achievement_manager.dart';
import 'game_id.dart';
import 'game_kit.dart';
import 'sound_manager.dart';

class WordGame extends StatefulWidget {
  const WordGame({
    super.key,
  });

  @override
  State<WordGame> createState() => _WordGameState();
}

// =============================================================
// KELİME MODELİ
// =============================================================

class WordItem {
  final String word;
  final String emoji;
  final String hint;
  final int difficulty;

  const WordItem({
    required this.word,
    required this.emoji,
    required this.hint,
    required this.difficulty,
  });
}

// =============================================================
// OYUN
// =============================================================

class _WordGameState extends State<WordGame>
    with SingleTickerProviderStateMixin, GameSessionMixin {
  final Random _random = Random();

  // -------------------------------------------------------------
  // KELİME HAVUZU
  // -------------------------------------------------------------

  final List<WordItem> _wordPool = const [
    // KOLAY
    WordItem(
      word: 'KEDI',
      emoji: '🐱',
      hint: 'Evde yaşayan sevimli bir hayvan.',
      difficulty: 1,
    ),
    WordItem(
      word: 'ELMA',
      emoji: '🍎',
      hint: 'Kırmızı veya yeşil bir meyve.',
      difficulty: 1,
    ),
    WordItem(
      word: 'MASA',
      emoji: '🪑',
      hint: 'Üzerinde yemek veya ders çalışılır.',
      difficulty: 1,
    ),
    WordItem(
      word: 'KUS',
      emoji: '🐦',
      hint: 'Uçabilen küçük bir hayvan.',
      difficulty: 1,
    ),
    WordItem(
      word: 'EV',
      emoji: '🏠',
      hint: 'İçinde yaşadığımız yer.',
      difficulty: 1,
    ),
    WordItem(
      word: 'AYI',
      emoji: '🐻',
      hint: 'Ormanda yaşayan büyük bir hayvan.',
      difficulty: 1,
    ),

    // ORTA
    WordItem(
      word: 'KALEM',
      emoji: '✏️',
      hint: 'Yazı yazmak için kullanılır.',
      difficulty: 2,
    ),
    WordItem(
      word: 'KITAP',
      emoji: '📚',
      hint: 'Okumak için kullanılan bir şey.',
      difficulty: 2,
    ),
    WordItem(
      word: 'BALIK',
      emoji: '🐟',
      hint: 'Suda yaşayan bir hayvan.',
      difficulty: 2,
    ),
    WordItem(
      word: 'CICEK',
      emoji: '🌸',
      hint: 'Bahçelerde ve doğada yetişir.',
      difficulty: 2,
    ),
    WordItem(
      word: 'ARABA',
      emoji: '🚗',
      hint: 'Yollarda kullanılan bir taşıt.',
      difficulty: 2,
    ),
    WordItem(
      word: 'GUNES',
      emoji: '☀️',
      hint: 'Dünyamıza ışık ve sıcaklık verir.',
      difficulty: 2,
    ),

    // ZOR
    WordItem(
      word: 'KELEBEK',
      emoji: '🦋',
      hint: 'Kanatları olan renkli bir canlı.',
      difficulty: 3,
    ),
    WordItem(
      word: 'FIL',
      emoji: '🐘',
      hint: 'Çok büyük ve hortumlu bir hayvan.',
      difficulty: 3,
    ),
    WordItem(
      word: 'KAPLUMBAĞA',
      emoji: '🐢',
      hint: 'Sırtında sert bir kabuk taşır.',
      difficulty: 3,
    ),
    WordItem(
      word: 'GOKKUSAGI',
      emoji: '🌈',
      hint: 'Yağmurdan sonra gökyüzünde görülebilir.',
      difficulty: 3,
    ),
    WordItem(
      word: 'DONDURMA',
      emoji: '🍦',
      hint: 'Soğuk ve tatlı bir yiyecek.',
      difficulty: 3,
    ),
    WordItem(
      word: 'YILDIZ',
      emoji: '⭐',
      hint: 'Gece gökyüzünde parlar.',
      difficulty: 3,
    ),
  ];

  // -------------------------------------------------------------
  // OYUN DEĞİŞKENLERİ
  // -------------------------------------------------------------

  static const int _totalQuestions = 10;
  static const int _maxLives = 3;

  int _questionIndex = 0;
  int _score = 0;
  int _lives = _maxLives;
  int _secondsLeft = 120;

  int _correctAnswers = 0;

  WordItem? _currentWord;

  List<String> _letters = [];
  final List<int> _selectedIndexes = [];

  Timer? _timer;

  bool _isAnswering = false;
  bool _showCorrectAnimation = false;
  bool _showWrongAnimation = false;
  bool _gameFinished = false;

  // -------------------------------------------------------------
  // GÜNLÜK SÜRE OTURUMU
  // -------------------------------------------------------------

  @override
  GameId get game => GameId.word;

  @override
  String get timeUpMessage =>
      'Kelime avı için belirlenen günlük süreyi kullandın. 🌙';

  @override
  int get currentScore => _score;

  @override
  bool get canShowTimeUpDialog => !_gameFinished;

  // -------------------------------------------------------------
  // ANİMASYON
  // -------------------------------------------------------------

  late AnimationController _animationController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // -------------------------------------------------------------
  // INIT
  // -------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    startGameSession();

    _startGame();
  }

  // -------------------------------------------------------------
  // OYUNU BAŞLAT
  // -------------------------------------------------------------

  void _startGame() {
    _timer?.cancel();

    _questionIndex = 0;
    _score = 0;
    _lives = _maxLives;
    _secondsLeft = 120;
    _correctAnswers = 0;
    _gameFinished = false;

    _loadQuestion();

    _startTimer();
  }

  // -------------------------------------------------------------
  // SORU YÜKLE
  // -------------------------------------------------------------

  void _loadQuestion() {
    if (_questionIndex >= _totalQuestions) {
      _finishGame();
      return;
    }

    // Zorluk yas bandindan baslar, oyun icinde kazanildikca acilir.
    // Bu iki oyun daha once childAge'i hic kullanmiyordu: 4 yasindaki cocuk
    // 12 yasindakiyle birebir ayni kelimeleri aliyordu.
    final allowed = difficulty.scaled(const [1, 1, 2, 3], max: 3);

    final byLevel =
        _wordPool.where((item) => item.difficulty <= allowed).toList();

    final availableWords = byLevel
        .where((item) => !_usedWords.contains(item.word))
        .toList();

    if (availableWords.isEmpty) {
      _usedWords.clear();
    }

    final pool = availableWords.isEmpty ? byLevel : availableWords;

    final word = pool[
    _random.nextInt(pool.length)];

    _usedWords.add(word.word);

    final letters = word.word
        .split('')
        .map((e) => e.toUpperCase())
        .toList();

    // Harfleri karıştır.
    do {
      letters.shuffle(_random);
    } while (
    letters.join() == word.word &&
        letters.length > 1);

    // Uzun kelimelerde birkaç ekstra harf ekle.
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

      final extra =
      extraLetters[_random.nextInt(
        extraLetters.length,
      )];

      letters.add(extra);
      letters.shuffle(_random);
    }

    setState(() {
      _currentWord = word;
      _letters = letters;
      _selectedIndexes.clear();
      _isAnswering = false;
      _showCorrectAnimation = false;
      _showWrongAnimation = false;
    });

    _animationController.forward(
      from: 0,
    );
  }

  final Set<String> _usedWords = {};

  // -------------------------------------------------------------
  // ZAMANLAYICI
  // -------------------------------------------------------------

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

  // -------------------------------------------------------------
  // HARFE BAS
  // -------------------------------------------------------------

  void _selectLetter(int index) {
    if (_isAnswering ||
        _gameFinished ||
        _selectedIndexes.contains(index)) {
      return;
    }

    final targetLength =
        _currentWord?.word.length ?? 0;

    if (_selectedIndexes.length >= targetLength) {
      return;
    }

    setState(() {
      _selectedIndexes.add(index);
    });
  }

  // -------------------------------------------------------------
  // SEÇİLİ HARFİ GERİ AL
  // -------------------------------------------------------------

  void _removeSelectedLetter(int position) {
    if (_isAnswering ||
        _selectedIndexes.isEmpty) {
      return;
    }

    setState(() {
      _selectedIndexes.removeAt(position);
    });
  }

  // -------------------------------------------------------------
  // CEVABI KONTROL ET
  // -------------------------------------------------------------

  Future<void> _checkAnswer() async {
    if (_currentWord == null ||
        _isAnswering) {
      return;
    }

    _isAnswering = true;

    final answer = _selectedIndexes
        .map(
          (index) => _letters[index],
    )
        .join();

    final correct =
        answer.toUpperCase() ==
            _currentWord!.word
                .toUpperCase();

    if (correct) {
      await _correctAnswer();
    } else {
      await _wrongAnswer();
    }
  }

  // -------------------------------------------------------------
  // DOĞRU CEVAP
  // -------------------------------------------------------------

  Future<void> _correctAnswer() async {
    if (!mounted) return;

    difficulty.correct();

    setState(() {
      _correctAnswers++;
      _score += _calculateQuestionScore();
      _showCorrectAnimation = true;
    });

    await SoundManager.playCorrect();

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) return;

    _questionIndex++;

    _loadQuestion();
  }

  // -------------------------------------------------------------
  // YANLIŞ CEVAP
  // -------------------------------------------------------------

  Future<void> _wrongAnswer() async {
    if (!mounted) return;

    difficulty.wrong();

    setState(() {
      _lives--;
      _showWrongAnimation = true;
    });

    await SoundManager.playWrong();

    await Future.delayed(
      const Duration(milliseconds: 750),
    );

    if (!mounted) return;

    if (_lives <= 0) {
      _finishGame();
      return;
    }

    setState(() {
      _selectedIndexes.clear();
      _showWrongAnimation = false;
      _isAnswering = false;
    });
  }

  // -------------------------------------------------------------
  // PUAN
  // -------------------------------------------------------------

  int _calculateQuestionScore() {
    int baseScore = 10;

    if (_currentWord?.difficulty == 2) {
      baseScore = 15;
    }

    if (_currentWord?.difficulty == 3) {
      baseScore = 20;
    }

    final timeBonus =
    min(_secondsLeft, 20);

    return baseScore + timeBonus;
  }

  // -------------------------------------------------------------
  // OYUNU BİTİR
  // -------------------------------------------------------------

  Future<void> _finishGame() async {
    if (_gameFinished) return;

    _timer?.cancel();

    _gameFinished = true;

    await AchievementManager.unlock('first_step');
    await AchievementManager.unlock('word_master');
    await AchievementManager.markGamePlayed('word');

    await SoundManager.playGameOver();

    if (!mounted) return;

    setState(() {});

    await Future.delayed(
      const Duration(milliseconds: 350),
    );

    if (!mounted) return;

    _showResultDialog();
  }

  // -------------------------------------------------------------
  // SONUÇ EKRANI
  // -------------------------------------------------------------

  void _showResultDialog() {
    final accuracy =
    _questionIndex == 0
        ? 0
        : ((_correctAnswers /
        _questionIndex) *
        100)
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
                      '🎉',
                      style: TextStyle(
                        fontSize: 54,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'Harika Oynadın!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight:
                        FontWeight.w900,
                        color:
                        Color(0xFF259242),
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    const Text(
                      'Kelime Avı tamamlandı!',
                      style: TextStyle(
                        fontSize: 17,
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
                      height: 22,
                    ),

                    Container(
                      width:
                      double.infinity,
                      padding:
                      const EdgeInsets
                          .symmetric(
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
                        BorderRadius
                            .circular(
                          17,
                        ),
                      ),
                      child: Text(
                        _getResultMessage(
                          accuracy,
                        ),
                        textAlign:
                        TextAlign.center,
                        style:
                        const TextStyle(
                          fontSize: 17,
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
                            BorderRadius
                                .circular(
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
                                fontSize:
                                14,
                                fontWeight:
                                FontWeight
                                    .w900,
                              ),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              '🔄',
                              style:
                              TextStyle(
                                fontSize:
                                18,
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
                            BorderRadius
                                .circular(
                              17,
                            ),
                          ),
                        ),
                        child:
                        const Text(
                          'Ana Sayfaya Dön',
                          style:
                          TextStyle(
                            fontSize: 17,
                            fontWeight:
                            FontWeight
                                .w800,
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

  // -------------------------------------------------------------
  // SONUÇ MESAJI
  // -------------------------------------------------------------

  String _getResultMessage(
      int accuracy,
      ) {
    if (accuracy >= 90) {
      return '🌟 Muhteşem! Kelimeler konusunda harikasın!';
    }

    if (accuracy >= 70) {
      return '👏 Çok güzel! Biraz daha çalışırsan daha da iyi olacaksın!';
    }

    if (accuracy >= 50) {
      return '💪 Güzel deneme! Birkaç oyun daha oynayarak gelişebilirsin!';
    }

    return '🌱 Pes etme! Tekrar dene ve kelimeleri keşfet!';
  }

  // -------------------------------------------------------------
  // SONUÇ KARTI
  // -------------------------------------------------------------

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
          color: const Color(0xFFE7F8E9),
          borderRadius:
          BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 21,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF259242),
                ),
              ),
            ),
            const SizedBox(
              height: 2,
            ),
            Text(
              title,
              style: const TextStyle(
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

  // -------------------------------------------------------------
  // OYUN KARTI
  // -------------------------------------------------------------

  Widget _letterButton(
      String letter,
      int index,
      ) {
    final selected =
    _selectedIndexes.contains(index);

    final disabled =
        _isAnswering ||
            selected ||
            _gameFinished;

    return GestureDetector(
      onTap: disabled
          ? null
          : () {
        _selectLetter(index);
      },
      child: AnimatedScale(
        scale: selected ? 0.92 : 1.0,
        duration:
        const Duration(milliseconds: 160),
        child: AnimatedContainer(
          duration:
          const Duration(milliseconds: 180),
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
              colors: [
                Color(0xFFD4F3D7),
                Color(0xFFE2F7E4),
              ],
            )
                : const LinearGradient(
              begin:
              Alignment.topLeft,
              end:
              Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFE6F9E8),
              ],
            ),
            borderRadius:
            BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFFB8EEBD)
                  : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                Colors.black.withValues(
                  alpha: selected ? 0.02 : 0.07,
                ),
                blurRadius:
                selected ? 4 : 10,
                offset:
                const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                FontWeight.w900,
                color: selected
                    ? const Color(
                  0xFF64E675,
                )
                    : const Color(
                  0xFF259242,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // SEÇİLEN HARFLER
  // -------------------------------------------------------------

  Widget _selectedLetters() {
    final selectedLetters = _selectedIndexes
        .map(
          (index) => _letters[index],
    )
        .toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 74,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surface
                .withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
          ),
          child: selectedLetters.isEmpty
              ? const Center(
            child: Text(
              'Harfleri seçerek kelimeyi oluştur',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4AE261),
              ),
            ),
          )
              : Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: List.generate(
              selectedLetters.length,
                  (position) {
                return GestureDetector(
                  onTap: () => _removeSelectedLetter(position),
                  child: Container(
                    width: 42,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8FFDC),
                      borderRadius:
                      BorderRadius.circular(13),
                      border: Border.all(
                        color: const Color(0xFFC6F2CB),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        selectedLetters[position],
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2AA84C),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            // GERİ AL
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                _selectedIndexes.isEmpty || _isAnswering
                    ? null
                    : () {
                  setState(() {
                    _selectedIndexes.removeLast();
                  });
                },
                icon: const Icon(
                  Icons.backspace_outlined,
                  size: 17,
                ),
                label: const Text(
                  'Geri Al',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                  const Color(0xFF23D83E),
                  disabledForegroundColor:
                  const Color(0xFF91E599),
                  side: const BorderSide(
                    color: Color(0xFFC4F1C8),
                  ),
                  minimumSize:
                  const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 9),

            // KONTROL ET
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                _selectedIndexes.isEmpty ||
                    _isAnswering
                    ? null
                    : _checkAnswer,
                icon: const Icon(
                  Icons.check_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Kontrol Et',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF23D83E),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                  const Color(0xFFD3F2D6),
                  disabledForegroundColor:
                  const Color(0xFF69E77C),
                  elevation: 3,
                  minimumSize:
                  const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final word = _currentWord;

    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // -----------------------------------------------------
            // ARKA PLAN
            // -----------------------------------------------------

            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFD5FFD9,
                  ).withValues(alpha: 0.65),
                  shape:
                  BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              top: -55,
              right: -45,
              child: Container(
                width: 150,
                height: 150,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFDDF1FF,
                  ).withValues(alpha: 0.70),
                  shape:
                  BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              bottom: -80,
              right: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFDFFFE2,
                  ).withValues(alpha: 0.65),
                  shape:
                  BoxShape.circle,
                ),
              ),
            ),

            // -----------------------------------------------------
            // ANA İÇERİK
            // -----------------------------------------------------

            if (word != null)
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      // =============================================
                      // ÜST BAR
                      // =============================================

                      Padding(
                        padding:
                        const EdgeInsets
                            .fromLTRB(
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
                                  BoxShape
                                      .circle,
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
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  Text(
                                    'Kelime Avı',
                                    style:
                                    TextStyle(
                                      fontSize:
                                      21,
                                      fontWeight:
                                      FontWeight
                                          .w900,
                                      color: Color(
                                        0xFF259242,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // CAN
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

                            // Oyun nasil oynanir: talimat bu dugmenin arkasinda.
                            GameHelpButton(game: game),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // =============================================
                      // İLERLEME + SKOR + SÜRE
                      // =============================================

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
                                  horizontal: 13,
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
                        height: 15,
                      ),

                      // =============================================
                      // OYUN ALANI
                      // =============================================

                      Expanded(
                        child: SingleChildScrollView(
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
                              // =======================================
                              // İPUCU KARTI
                              // =======================================

                              Container(
                                width:
                                double.infinity,
                                padding:
                                const EdgeInsets
                                    .fromLTRB(
                                  20,
                                  20,
                                  20,
                                  19,
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
                                    27,
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
                                      15,
                                      offset:
                                      const Offset(
                                        0,
                                        7,
                                      ),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 92,
                                      height: 92,
                                      decoration:
                                      BoxDecoration(
                                        color: Colors
                                            .white
                                            .withValues(
                                          alpha: 0.75,
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
                                            52,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 12,
                                    ),

                                    const Text(
                                      'Kelimeyi oluştur!',
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
                                height: 14,
                              ),

                              // =======================================
                              // SEÇİLEN HARFLER
                              // =======================================

                              _selectedLetters(),

                              const SizedBox(
                                height: 14,
                              ),

                              // =======================================
                              // HARFLER
                              // =======================================

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
                                  List.generate(
                                    _letters.length,
                                        (index) {
                                      return _letterButton(
                                        _letters[
                                        index],
                                        index,
                                      );
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              // =======================================
                              // YARDIM
                              // =======================================

                              Container(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal: 15,
                                  vertical: 12,
                                ),
                                decoration:
                                BoxDecoration(
                                  color:
                                  Colors.white
                                      .withValues(
                                    alpha: 0.55,
                                  ),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    17,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                                  children: [
                                    Text(
                                      '💡',
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
                                      child: Text(
                                        'Seçtiğin harfe tekrar dokunarak geri alabilirsin.',
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
              ),

            // =============================================
            // DOĞRU CEVAP ANİMASYONU
            // =============================================

            if (_showCorrectAnimation)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.white
                        .withValues(alpha: 0.25),
                    child: Center(
                      child: TweenAnimationBuilder<
                          double>(
                        tween:
                        Tween<double>(
                          begin: 0.5,
                          end: 1.0,
                        ),
                        duration:
                        const Duration(
                          milliseconds: 500,
                        ),
                        curve:
                        Curves.elasticOut,
                        builder:
                            (
                            context,
                            value,
                            child,
                            ) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration:
                          BoxDecoration(
                            color: Colors.white,
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
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                            children: [
                              Text(
                                '🎉',
                                style:
                                TextStyle(
                                  fontSize: 48,
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text(
                                'Harika!',
                                style:
                                TextStyle(
                                  fontSize: 19,
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

            // =============================================
            // YANLIŞ CEVAP ANİMASYONU
            // =============================================

            if (_showWrongAnimation)
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<
                      double>(
                    tween:
                    Tween<double>(
                      begin: 0,
                      end: 1,
                    ),
                    duration:
                    const Duration(
                      milliseconds: 350,
                    ),
                    builder:
                        (
                        context,
                        value,
                        child,
                        ) {
                      return Container(
                        color:
                        const Color(
                          0xFFFFDADA,
                        ).withValues(
                          alpha: 0.20 * value,
                        ),
                        child: Center(
                          child:
                          Transform.scale(
                            scale:
                            0.85 +
                                (0.15 *
                                    value),
                            child:
                            Container(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 28,
                                vertical: 18,
                              ),
                              decoration:
                              BoxDecoration(
                                color:
                                Colors.white,
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
                                    '🤔',
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

  // -------------------------------------------------------------
  // İSTATİSTİK KARTI
  // -------------------------------------------------------------

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
        Colors.white.withValues(alpha: 0.82),
        borderRadius:
        BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
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

  // -------------------------------------------------------------
  // SÜRE FORMAT
  // -------------------------------------------------------------

  String _formatTime(
      int seconds,
      ) {
    final minutes =
        seconds ~/ 60;
    final remainingSeconds =
        seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // -------------------------------------------------------------
  // DISPOSE
  // -------------------------------------------------------------

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    // gameTimer'i GameSessionMixin kapatir.
    super.dispose();
  }
}