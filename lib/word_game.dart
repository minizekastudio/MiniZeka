import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'achievement_manager.dart';
import 'app_theme.dart';
import 'difficulty.dart';
import 'game_id.dart';
import 'game_kit.dart';
import 'games/word_round.dart';
import 'sound_manager.dart';
import 'storage_keys.dart';

/// Build the word for the picture out of letter tiles.
///
/// The word list used to be stored without Turkish letters (KEDI, CICEK) and
/// upper-cased in code, which turns "i" into "I"; a spelling game cannot
/// teach the spelling wrong. The game also ran a two minute countdown and
/// took a life for every miss — a stopwatch and a way to lose, for four year
/// olds, in an app that has neither anywhere else.
class WordGame extends StatefulWidget {
  const WordGame({super.key, this.random});

  /// Injected by tests so a round can be reproduced.
  final Random? random;

  @override
  State<WordGame> createState() => _WordGameState();
}

class _WordGameState extends State<WordGame>
    with TickerProviderStateMixin, GameSessionMixin {
  @override
  GameId get game => GameId.word;

  @override
  String get timeUpMessage =>
      'Kelime Avı için belirlenen günlük süreyi kullandın. 🌙';

  @override
  int get currentScore => score;

  @override
  bool get canShowTimeUpDialog => !_isRoundOver;

  static const double _tileGap = 8;

  static const double _slotGap = 4;

  static const Duration _foundHold = Duration(milliseconds: 900);

  /// After this many wrong tries the next letter is pointed out.
  static const int _hintAfterWrongTries = 2;

  late final Random _random = widget.random ?? Random();

  // ---- ladder -------------------------------------------------------------

  int levelIndex = 0;
  int roundsCleared = 0;

  GameLevel get level => wordLadder[levelIndex];

  @override
  void onChildAgeLoaded() {
    levelIndex = startingLevelFor(ageBand);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final resumed = resumeLadder(
      ladder: wordLadder,
      startingLevel: levelIndex,
      savedLevel: prefs.getInt(StorageKeys.gameLevel(game)),
      savedRounds: prefs.getInt(StorageKeys.gameRoundsCleared(game)) ?? 0,
    );

    if (!mounted) return;

    setState(() {
      levelIndex = resumed.levelIndex;
      roundsCleared = resumed.roundsCleared;
      _startRound();
    });
  }

  Future<void> _saveProgress(int level, int rounds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.gameLevel(game), level);
    await prefs.setInt(StorageKeys.gameRoundsCleared(game), rounds);
  }

  // ---- round state --------------------------------------------------------

  List<WordQuestion> _round = const [];
  int _questionIndex = 0;
  int score = 0;

  int _firstTryMistakes = 0;
  int _wrongTriesThisWord = 0;

  /// Tiles put into the slots, in order.
  final List<int> _placed = [];

  bool _isSolved = false;
  bool _isResolving = false;
  bool _isRoundOver = false;
  int _roundGeneration = 0;

  WordQuestion? get _question => _round.isEmpty ? null : _round[_questionIndex];

  bool get _showsHint => _wrongTriesThisWord >= _hintAfterWrongTries;

  // ---- animation ----------------------------------------------------------

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    startGameSession();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _shake.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ---- flow ---------------------------------------------------------------

  void _startRound() {
    _roundGeneration++;

    _round = buildWordRound(rung: levelIndex, random: _random);
    _questionIndex = 0;
    score = 0;
    _firstTryMistakes = 0;
    _isRoundOver = false;

    _beginQuestion();
  }

  void _beginQuestion() {
    _wrongTriesThisWord = 0;
    _placed.clear();
    _isSolved = false;
    _isResolving = false;

    _pulse
      ..stop()
      ..value = 0;
  }

  /// How many letters the answer needs.
  int get _slotCount => _question?.word.length ?? 0;

  /// The tile a child should reach for next, for the hint.
  int? get _nextCorrectTile {
    final question = _question;
    if (question == null) return null;

    final wanted = question.spelling[_placed.length.clamp(0, _slotCount - 1)];

    for (var i = 0; i < question.letters.length; i++) {
      if (question.letters[i] == wanted && !_placed.contains(i)) return i;
    }

    return null;
  }

  void _handleTileTap(int index) {
    if (!ensurePlayTimeLeft()) return;

    final question = _question;
    if (question == null || _isResolving || _isRoundOver) return;
    if (_placed.contains(index) || _placed.length >= _slotCount) return;

    setState(() => _placed.add(index));

    if (_placed.length == _slotCount) _checkAnswer(question);
  }

  /// Taking a letter back out of the slots.
  void _handleSlotTap(int slot) {
    if (_isResolving || _isRoundOver) return;
    if (slot >= _placed.length) return;

    setState(() => _placed.removeRange(slot, _placed.length));
  }

  void _checkAnswer(WordQuestion question) {
    final attempt = _placed.map((i) => question.letters[i]).join();

    if (attempt == question.answer) {
      _resolveCorrect();
    } else {
      _handleWrong();
    }
  }

  void _handleWrong() {
    SoundManager.playWrong();

    if (_wrongTriesThisWord == 0) _firstTryMistakes++;
    _wrongTriesThisWord++;

    _shake.forward(from: 0);

    // Wrong letters simply come back: no lives, nothing ends. After a couple
    // of tries the next letter starts to pulse.
    setState(_placed.clear);

    if (_wrongTriesThisWord >= _hintAfterWrongTries) {
      _pulse.repeat(reverse: true);
    }
  }

  void _resolveCorrect() {
    final generation = _roundGeneration;
    final isFirstTry = _wrongTriesThisWord == 0;

    SoundManager.playCorrect();
    _pulse
      ..stop()
      ..value = 0;

    setState(() {
      _isSolved = true;
      _isResolving = true;

      if (isFirstTry) score += (levelIndex + 1) * 10;
    });

    final isLastQuestion = _questionIndex + 1 >= _round.length;
    final settled = isLastQuestion ? _settleRound() : null;

    _holdTimer?.cancel();
    _holdTimer = Timer(_foundHold, () {
      if (!mounted || generation != _roundGeneration) return;

      if (settled == null) {
        setState(() {
          _questionIndex++;
          _beginQuestion();
        });
      } else {
        _finishRound(settled);
      }
    });
  }

  _SettledRound _settleRound() {
    AchievementManager.unlock('word_master');
    AchievementManager.unlock('first_step');
    AchievementManager.markGamePlayed(game);

    if (isCleanRound(_firstTryMistakes)) {
      final next = advanceLadder(
        ladder: wordLadder,
        levelIndex: levelIndex,
        roundsCleared: roundsCleared,
      );

      _saveProgress(next.levelIndex, next.roundsCleared);

      return next;
    }

    return (
      levelIndex: levelIndex,
      roundsCleared: roundsCleared,
      outcome: RoundOutcome.retry,
    );
  }

  void _finishRound(_SettledRound settled) {
    setState(() {
      levelIndex = settled.levelIndex;
      roundsCleared = settled.roundsCleared;
      _isRoundOver = true;
    });

    if (timeUpDialogShown) return;

    final firstTryRight = _round.length - _firstTryMistakes;

    showLadderRoundDialog(
      context: context,
      palette: palette,
      outcome: settled.outcome,
      ladder: wordLadder,
      levelIndex: levelIndex,
      roundsCleared: roundsCleared,
      levelUpMessage: _newRungMessage(levelIndex),
      masteredMessage: 'En uzun kelimeleri bile yazıyorsun! ✨',
      flair: '🔎',
      results: [
        GameResultBox(
          palette: palette,
          emoji: '⭐',
          title: 'Puan',
          value: '$score',
        ),
        GameResultBox(
          palette: palette,
          emoji: '✅',
          title: 'İlk seferde',
          value: '$firstTryRight/${_round.length}',
        ),
        GameResultBox(
          palette: palette,
          emoji: '⏱️',
          title: 'Süre',
          value: formatSeconds(gameTimer.usedSeconds),
        ),
      ],
      onNextRound: () {
        if (!ensurePlayTimeLeft()) return;

        setState(_startRound);
      },
    );
  }

  static String _newRungMessage(int rung) {
    if (rung == 0) return 'Hadi başlayalım! ✨';
    if (wordRuleFor(rung).tiles > wordRuleFor(rung - 1).tiles) {
      return 'Artık daha çok harf var! 🔤';
    }
    return 'Artık kelimeler uzuyor! 🔤';
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final question = _question;

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  InfoBox(emoji: '⭐', title: 'Puan', value: '$score'),
                  const SizedBox(width: 8),
                  InfoBox(
                    emoji: '🎯',
                    title: 'Soru',
                    value: '${_questionIndex + 1} / $questionsPerRound',
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
            LadderStrip(
              palette: palette,
              levelIndex: levelIndex,
              roundsCleared: roundsCleared,
              roundsToAdvance: level.roundsToAdvance,
            ),
            const SizedBox(height: 8),
            GameTimeBar(
              palette: palette,
              progress: timeProgress,
              remaining: gameTimer.formattedRemaining,
            ),
            const SizedBox(height: 12),
            Expanded(flex: 5, child: _buildPictureCard(question)),
            const SizedBox(height: 10),
            Expanded(flex: 5, child: _buildTiles(question)),
          ],
        ),
      ),
    );
  }

  Widget _buildPictureCard(WordQuestion? question) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Brand.cardLight,
        borderRadius: BorderRadius.circular(Brand.cardRadius),
        border: Border.all(
          color: _isSolved ? Brand.leaf : Colors.transparent,
          width: 4,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 7, offset: Offset(0, 3)),
        ],
      ),
      child: question == null
          ? const SizedBox.shrink()
          : LayoutBuilder(
              builder: (context, constraints) {
                final box = constraints.biggest;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Semantics(
                          label: 'Resimdeki: ${question.word}',
                          child: Text(
                            question.item.emoji,
                            style: TextStyle(fontSize: box.height * 0.45),
                          ),
                        ),
                      ),
                    ),
                    _buildSlots(question, box),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSlots(WordQuestion question, Size box) {
    // Long words break into two rows rather than shrinking to a sliver.
    final rowCount = _slotCount > 6 ? 2 : 1;
    final perRow = (_slotCount / rowCount).ceil();

    final double largestSlot = max(
      22.0,
      box.height * (rowCount == 1 ? 0.3 : 0.18),
    );
    final slotSize = ((box.width - _slotGap * (perRow - 1)) / perRow).clamp(
      22.0,
      largestSlot,
    );

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(sin(_shake.value * pi * 6) * 10 * (1 - _shake.value), 0),
        child: child,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: _slotGap,
        runSpacing: _slotGap,
        children: [
          for (var slot = 0; slot < _slotCount; slot++)
            GestureDetector(
              onTap: () => _handleSlotTap(slot),
              child: Container(
                width: slotSize,
                height: slotSize * 1.15,
                decoration: BoxDecoration(
                  color: slot < _placed.length
                      ? palette.softBackground
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(slotSize * 0.25),
                  border: Border.all(color: palette.button, width: 2),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      slot < _placed.length
                          ? question.letters[_placed[slot]]
                          : '',
                      style: TextStyle(
                        fontSize: slotSize * 0.6,
                        fontWeight: FontWeight.w900,
                        color: palette.value,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTiles(WordQuestion? question) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: question == null
          ? const SizedBox.shrink()
          : LayoutBuilder(
              builder: (context, constraints) {
                final grid = fitGrid(
                  question.letters.length,
                  constraints.biggest,
                  _tileGap,
                );

                return AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) => GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: question.letters.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: grid.columns,
                      crossAxisSpacing: _tileGap,
                      mainAxisSpacing: _tileGap,
                      childAspectRatio: grid.aspectRatio,
                    ),
                    itemBuilder: (context, index) =>
                        _buildTile(question, index),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTile(WordQuestion question, int index) {
    final isUsed = _placed.contains(index);
    final isHinted = _showsHint && index == _nextCorrectTile;

    // The hint grows the tile itself, so it is visible without reading.
    return Transform.scale(
      scale: isHinted ? 1 + 0.08 * _pulse.value : 1,
      child: Semantics(
        button: true,
        enabled: !isUsed,
        label: question.letters[index],
        excludeSemantics: true,
        onTap: isUsed ? null : () => _handleTileTap(index),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleTileTap(index),
          child: AnimatedOpacity(
            opacity: isUsed ? 0.3 : 1,
            duration: const Duration(milliseconds: 150),
            child: LayoutBuilder(
              builder: (context, constraints) => Container(
                decoration: BoxDecoration(
                  color: palette.button,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        question.letters[index],
                        style: TextStyle(
                          fontSize: constraints.biggest.shortestSide * 0.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _SettledRound = ({
  int levelIndex,
  int roundsCleared,
  RoundOutcome outcome,
});
