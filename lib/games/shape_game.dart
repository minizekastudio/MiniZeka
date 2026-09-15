import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../achievement_manager.dart';
import '../app_theme.dart';
import '../difficulty.dart';
import '../game_id.dart';
import '../game_kit.dart';
import '../sound_manager.dart';
import '../storage_keys.dart';
import 'shape_figure.dart';
import 'shape_round.dart';

/// Find the card that is the same kind of shape as the target, however it is
/// dressed up.
///
/// It used to show the target emoji and an identical emoji among the
/// options, which trains matching pictures, not recognising shapes. Now each
/// rung of [shapeLadder] disguises the matching card a little more
/// ([ShapeVariation]), and nothing on the board needs reading.
class ShapeGame extends StatefulWidget {
  const ShapeGame({super.key, this.random});

  /// Injected by tests so a round can be reproduced.
  final Random? random;

  @override
  State<ShapeGame> createState() => _ShapeGameState();
}

typedef _SettledRound = ({
  int levelIndex,
  int roundsCleared,
  RoundOutcome outcome,
});

class _ShapeGameState extends State<ShapeGame>
    with TickerProviderStateMixin, GameSessionMixin {
  @override
  GameId get game => GameId.shape;

  @override
  String get timeUpMessage =>
      'Eşleştirme oyunu için belirlenen günlük süreyi kullandın. 🌙';

  @override
  int get currentScore => score;

  @override
  bool get canShowTimeUpDialog => !_isRoundOver;

  static const double _cardGap = 12;

  /// Tallest a card may be, as a multiple of its width.
  static const double _maxCardTallness = 1.15;

  /// Time for the target to turn into the picked card and be seen.
  static const Duration _correctHold = Duration(milliseconds: 900);

  static const Duration _idleBeforeDemo = Duration(seconds: 5);

  /// After this many wrong taps on one question the matching card pulses.
  static const int _hintAfterWrongTaps = 2;

  late final Random _random = widget.random ?? Random();

  // ---- ladder -------------------------------------------------------------

  int levelIndex = 0;
  int roundsCleared = 0;

  GameLevel get level => shapeLadder[levelIndex];

  @override
  void onChildAgeLoaded() {
    // Age only sets where the climb starts; saved progress can lift it and
    // the level never goes back down.
    levelIndex = startingLevelFor(ageBand);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final resumed = resumeLadder(
      ladder: shapeLadder,
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

  List<ShapeQuestion> _round = const [];
  int _questionIndex = 0;
  int score = 0;

  /// Questions whose first tap was wrong; decides whether the round is clean.
  int _firstTryMistakes = 0;

  int _wrongTapsThisQuestion = 0;
  final Set<int> _lockedOptions = {};

  /// The matching card once it has been found, while the target turns into it.
  int? _answeredIndex;

  bool _isResolving = false;
  bool _isRoundOver = false;

  /// Bumped for every new round, so a delayed step from the previous round
  /// can tell it is stale.
  int _roundGeneration = 0;

  ShapeQuestion? get _question =>
      _round.isEmpty ? null : _round[_questionIndex];

  // ---- animation ----------------------------------------------------------

  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  int? _shakingIndex;

  Timer? _demoTimer;
  bool _isShowingDemo = false;

  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    startGameSession();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _holdTimer?.cancel();
    _morph.dispose();
    _shake.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ---- flow ---------------------------------------------------------------

  void _startRound() {
    _roundGeneration++;

    _round = buildShapeRound(rung: levelIndex, random: _random);
    _questionIndex = 0;
    score = 0;
    _firstTryMistakes = 0;
    _isRoundOver = false;

    _beginQuestion();
  }

  void _beginQuestion() {
    _wrongTapsThisQuestion = 0;
    _lockedOptions.clear();
    _answeredIndex = null;
    _shakingIndex = null;
    _isResolving = false;

    _morph.value = 0;
    _stopPulse();
    _scheduleDemo();
  }

  /// On the very first rung, a hand shows where to tap if the first question
  /// sits untouched for a while. Nowhere else: it would give answers away.
  void _scheduleDemo() {
    _demoTimer?.cancel();
    _isShowingDemo = false;

    if (levelIndex != 0 || _questionIndex != 0) return;

    final generation = _roundGeneration;

    _demoTimer = Timer(_idleBeforeDemo, () {
      if (!mounted || generation != _roundGeneration || _isResolving) return;

      setState(() => _isShowingDemo = true);
      _pulse.repeat(reverse: true);
    });
  }

  void _stopPulse() {
    _pulse
      ..stop()
      ..value = 0;
  }

  void _handleOptionTap(int index) {
    if (!ensurePlayTimeLeft()) return;

    final question = _question;
    if (question == null || _isResolving || _isRoundOver) return;
    if (_lockedOptions.contains(index)) return;

    _demoTimer?.cancel();

    if (index == question.correctIndex) {
      _resolveCorrect(index);
    } else {
      _handleWrong(index);
    }
  }

  void _handleWrong(int index) {
    SoundManager.playWrong();

    if (_wrongTapsThisQuestion == 0) _firstTryMistakes++;
    _wrongTapsThisQuestion++;

    setState(() {
      _lockedOptions.add(index);
      _shakingIndex = index;
      _isShowingDemo = false;
    });

    _shake.forward(from: 0);

    if (_wrongTapsThisQuestion >= _hintAfterWrongTaps) {
      _pulse.repeat(reverse: true);
    } else {
      _stopPulse();
    }
  }

  void _resolveCorrect(int index) {
    final generation = _roundGeneration;
    final isFirstTry = _wrongTapsThisQuestion == 0;

    SoundManager.playCorrect();
    _stopPulse();

    setState(() {
      _isResolving = true;
      _answeredIndex = index;
      _isShowingDemo = false;

      // A found-after-mistakes answer still moves on, but scores nothing.
      if (isFirstTry) score += (levelIndex + 1) * 10;
    });

    // A finished round is settled and saved before the pause, not after it:
    // a child who leaves during the pause keeps what they earned.
    final isLastQuestion = _questionIndex + 1 >= _round.length;
    final settled = isLastQuestion ? _settleRound() : null;

    // The target turns into the picked card: same shape, new clothes.
    _morph.forward(from: 0);

    // A cancellable timer rather than a delayed future, so a screen that is
    // closed during the pause leaves nothing running behind it.
    _holdTimer?.cancel();
    _holdTimer = Timer(_correctHold, () {
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

  /// What the round just finished earned, saved straight away.
  _SettledRound _settleRound() {
    AchievementManager.unlock('shape_master');
    AchievementManager.unlock('first_step');
    AchievementManager.markGamePlayed(game);

    if (isCleanShapeRound(_firstTryMistakes)) {
      final next = advanceLadder(
        ladder: shapeLadder,
        levelIndex: levelIndex,
        roundsCleared: roundsCleared,
      );

      _saveProgress(next.levelIndex, next.roundsCleared);

      return next;
    }

    // Not clean: nothing earned, nothing lost. At the top with every star
    // already earned there is nothing left to count down to.
    final top = shapeLadder.length - 1;
    final isMastered =
        levelIndex == top && roundsCleared >= level.roundsToAdvance;

    return (
      levelIndex: levelIndex,
      roundsCleared: roundsCleared,
      outcome: isMastered ? RoundOutcome.mastered : RoundOutcome.progress,
    );
  }

  void _finishRound(_SettledRound settled) {
    setState(() {
      levelIndex = settled.levelIndex;
      roundsCleared = settled.roundsCleared;
      _isRoundOver = true;
    });

    // The allowance ran out during the pause and its warning is already up.
    // That warning leads out of the game and the round is saved, so a round
    // dialog on top of it would only trap the child between the two.
    if (timeUpDialogShown) return;

    final outcome = settled.outcome;
    final firstTryRight = _round.length - _firstTryMistakes;

    showLadderRoundDialog(
      context: context,
      palette: palette,
      outcome: outcome,
      ladder: shapeLadder,
      levelIndex: levelIndex,
      roundsCleared: roundsCleared,
      levelUpMessage: _newRungMessage(ShapeVariation.forRung(levelIndex)),
      masteredMessage: 'Şekilleri her kılıkta tanıyorsun! ✨',
      flair: '✨',
      results: [
        GameResultBox(
          palette: palette,
          emoji: '⭐',
          title: 'Puan',
          value: '$score',
        ),
        GameResultBox(
          palette: palette,
          emoji: '🎯',
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

  static String _newRungMessage(ShapeVariation variation) =>
      switch (variation) {
        ShapeVariation.identical => 'Hadi başlayalım! ✨',
        ShapeVariation.color => 'Artık renkler değişiyor! 🎨',
        ShapeVariation.size => 'Artık boylar da değişiyor! 🔍',
        ShapeVariation.orientation => 'Artık şekiller dönebiliyor! 🔄',
        ShapeVariation.proportion => 'Artık şekiller uzayıp basıklaşıyor! ✨',
        ShapeVariation.nearMiss => 'Artık benzer şekillere dikkat! 👀',
      };

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
                    value: '${_questionIndex + 1} / $shapeQuestionsPerRound',
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
            _buildLevelStrip(),
            const SizedBox(height: 8),
            _buildTimeBar(),
            const SizedBox(height: 12),
            Expanded(flex: 3, child: _buildTarget(question)),
            const SizedBox(height: 12),
            Expanded(flex: 7, child: _buildOptions(question)),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelStrip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            Text(
              '${levelIndex + 1}. Bölüm',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: palette.value,
              ),
            ),
            const SizedBox(width: 10),
            ...List.generate(level.roundsToAdvance, (i) {
              final isEarned = i < roundsCleared;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 22,
                  color: isEarned
                      ? Brand.sun
                      : palette.value.withValues(alpha: 0.35),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// The allowance, as a bar only: the same time is already written in the
  /// ⏱️ box above.
  Widget _buildTimeBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Semantics(
        label: 'Kalan günlük süre: ${gameTimer.formattedRemaining}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: timeProgress,
            minHeight: 7,
            backgroundColor: palette.softBackground,
            valueColor: AlwaysStoppedAnimation<Color>(
              timeProgress < 0.2 ? Brand.ladybug : palette.button,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTarget(ShapeQuestion? question) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(Brand.cardRadius),
      ),
      child: question == null
          ? const SizedBox.shrink()
          : Semantics(
              label: 'Hedef şekil: ${question.target.kind.label}',
              child: AnimatedBuilder(
                animation: _morph,
                builder: (context, _) {
                  final answered = _answeredIndex;

                  return CustomPaint(
                    size: Size.infinite,
                    painter: ShapePainter(
                      figure: question.target,
                      morphTarget:
                          answered == null ? null : question.options[answered],
                      morph: Curves.easeInOut.transform(_morph.value),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildOptions(ShapeQuestion? question) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: question == null
          ? const SizedBox.shrink()
          : LayoutBuilder(
              builder: (context, constraints) {
                final count = question.options.length;
                final box = constraints.biggest;
                final grid = fitGrid(count, box, _cardGap);

                final rows = (count / grid.columns).ceil();
                final cardWidth =
                    (box.width - _cardGap * (grid.columns - 1)) / grid.columns;

                // Three cards in a row on a tall phone came out twice as tall
                // as wide: the card read as a rectangle itself and the shape
                // drawn in it stayed small. Cap the height and keep the board
                // right under the target, where the eye compares the two.
                final cardHeight = min(
                  (box.height - _cardGap * (rows - 1)) / rows,
                  cardWidth * _maxCardTallness,
                );
                final boardHeight = cardHeight * rows + _cardGap * (rows - 1);

                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: boardHeight,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_shake, _pulse, _morph]),
                      builder: (context, _) => GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: count,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: grid.columns,
                          crossAxisSpacing: _cardGap,
                          mainAxisSpacing: _cardGap,
                          childAspectRatio: cardWidth / cardHeight,
                        ),
                        itemBuilder: (context, index) =>
                            _buildOption(question, index),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildOption(ShapeQuestion question, int index) {
    final figure = question.options[index];
    final isCorrect = index == question.correctIndex;
    final isLocked = _lockedOptions.contains(index);
    final isAnswered = _answeredIndex == index;
    final isHinted = isCorrect &&
        !_isResolving &&
        (_isShowingDemo || _wrongTapsThisQuestion >= _hintAfterWrongTaps);

    var scale = 1.0;
    if (isHinted) scale += 0.07 * _pulse.value;
    if (isAnswered) scale += 0.08 * sin(pi * _morph.value);

    var shift = 0.0;
    if (_shakingIndex == index && _shake.isAnimating) {
      shift = sin(_shake.value * pi * 6) * 8 * (1 - _shake.value);
    }

    return Semantics(
      button: true,
      label: figure.kind.label,
      // The demo hand is decoration; the card is just its shape's name.
      excludeSemantics: true,
      onTap: () => _handleOptionTap(index),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleOptionTap(index),
        child: Transform.translate(
          offset: Offset(shift, 0),
          child: Transform.scale(
            scale: scale,
            child: AnimatedOpacity(
              opacity: isLocked ? 0.35 : 1,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  color: Brand.cardLight,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isAnswered ? Brand.leaf : Colors.transparent,
                    width: 4,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: CustomPaint(
                        painter: ShapePainter(figure: figure),
                      ),
                    ),
                    if (isCorrect && _isShowingDemo)
                      Align(
                        alignment: const Alignment(0.55, 0.75),
                        child: Transform.translate(
                          offset: Offset(0, -8 * _pulse.value),
                          child: const Text(
                            '👆',
                            style: TextStyle(fontSize: 34),
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
    );
  }
}
