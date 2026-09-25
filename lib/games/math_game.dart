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
import 'math_round.dart';

/// Counting, adding and taking away.
///
/// It used to ask "4 + 1 = ?" in digits only, at every age. Most of the
/// target age is still learning what a digit means, so the lower rungs of
/// [mathLadder] show things to count and the digits sit underneath them; the
/// objects drop away only once the sums are familiar (see [MathRule]).
class MathGame extends StatefulWidget {
  const MathGame({super.key, this.random});

  /// Injected by tests so a round can be reproduced.
  final Random? random;

  @override
  State<MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<MathGame>
    with TickerProviderStateMixin, GameSessionMixin {
  @override
  GameId get game => GameId.math;

  @override
  String get timeUpMessage =>
      'Matematik oyunu için belirlenen günlük süreyi kullandın. 🌙';

  @override
  int get currentScore => score;

  @override
  bool get canShowTimeUpDialog => !_isRoundOver;

  static const double _optionGap = 12;

  /// Time to see the chosen answer light up before the next question.
  static const Duration _foundHold = Duration(milliseconds: 800);

  /// After this many wrong taps the things to count appear, on every rung.
  static const int _hintAfterWrongTaps = 2;

  late final Random _random = widget.random ?? Random();

  // ---- ladder -------------------------------------------------------------

  int levelIndex = 0;
  int roundsCleared = 0;

  GameLevel get level => mathLadder[levelIndex];

  @override
  void onChildAgeLoaded() {
    levelIndex = startingLevelFor(ageBand);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final resumed = resumeLadder(
      ladder: mathLadder,
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

  List<MathQuestion> _round = const [];
  int _questionIndex = 0;
  int score = 0;

  int _firstTryMistakes = 0;
  int _wrongTapsThisQuestion = 0;
  final Set<int> _lockedOptions = {};

  int? _answeredIndex;
  bool _isResolving = false;
  bool _isRoundOver = false;
  int _roundGeneration = 0;

  MathQuestion? get _question =>
      _round.isEmpty ? null : _round[_questionIndex];

  /// Things to count are shown when the rung says so, and as a hand-hold
  /// after a couple of wrong taps on rungs that normally hide them.
  bool get _showsObjects =>
      (_question?.hasObjects ?? false) ||
      _wrongTapsThisQuestion >= _hintAfterWrongTaps;

  // ---- animation ----------------------------------------------------------

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  int? _shakingIndex;
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

    _round = buildMathRound(rung: levelIndex, random: _random);
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

    _pulse
      ..stop()
      ..value = 0;
  }

  void _handleOptionTap(int index) {
    if (!ensurePlayTimeLeft()) return;

    final question = _question;
    if (question == null || _isResolving || _isRoundOver) return;
    if (_lockedOptions.contains(index)) return;

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
    });

    _shake.forward(from: 0);

    // A wrong answer no longer ends the question. After two tries the things
    // to count appear, so a stuck child can work it out rather than guess.
    if (_wrongTapsThisQuestion >= _hintAfterWrongTaps) {
      _pulse.repeat(reverse: true);
    }
  }

  void _resolveCorrect(int index) {
    final generation = _roundGeneration;
    final isFirstTry = _wrongTapsThisQuestion == 0;

    SoundManager.playCorrect();
    _pulse
      ..stop()
      ..value = 0;

    setState(() {
      _isResolving = true;
      _answeredIndex = index;

      if (isFirstTry) score += (levelIndex + 1) * 10;
    });

    // A finished round is settled and saved before the pause.
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
    AchievementManager.unlock('math_master');
    AchievementManager.unlock('first_step');
    AchievementManager.markGamePlayed(game);

    if (isCleanRound(_firstTryMistakes)) {
      final next = advanceLadder(
        ladder: mathLadder,
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
      ladder: mathLadder,
      levelIndex: levelIndex,
      roundsCleared: roundsCleared,
      levelUpMessage: _newRungMessage(mathRuleFor(levelIndex)),
      masteredMessage: 'Toplama da çıkarma da sende! ✨',
      flair: '🔢',
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

  static String _newRungMessage(MathRule rule) => switch (rule.task) {
        MathTask.count => 'Hadi sayalım! ✨',
        MathTask.add => rule.hasObjects
            ? 'Artık ${rule.largest}\'e kadar topluyoruz! ➕'
            : 'Artık sayılar büyüdü! ➕',
        MathTask.subtract => 'Artık çıkarma da var! ➖',
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
            Expanded(flex: 5, child: _buildQuestionCard(question)),
            const SizedBox(height: 12),
            Expanded(flex: 6, child: _buildOptions(question)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(MathQuestion? question) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(14),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Brand.cardLight,
        borderRadius: BorderRadius.circular(Brand.cardRadius),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: question == null
          ? const SizedBox.shrink()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_showsObjects)
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) => Transform.scale(
                        // Pulses when it appears as a hint.
                        scale: 1 + 0.05 * _pulse.value,
                        child: child,
                      ),
                      child: _ObjectPicture(
                        question: question,
                        palette: palette,
                      ),
                    ),
                  ),
                if (_showsObjects) const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _expressionOf(question),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: palette.value,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  static String _expressionOf(MathQuestion question) => switch (question.task) {
        MathTask.count => '?',
        MathTask.add => '${question.left} + ${question.right} = ?',
        MathTask.subtract => '${question.left} − ${question.right} = ?',
      };

  Widget _buildOptions(MathQuestion? question) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: question == null
          ? const SizedBox.shrink()
          : LayoutBuilder(
              builder: (context, constraints) {
                final grid = fitGrid(
                  question.options.length,
                  constraints.biggest,
                  _optionGap,
                );

                return AnimatedBuilder(
                  animation: _shake,
                  builder: (context, _) => GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: question.options.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: grid.columns,
                      crossAxisSpacing: _optionGap,
                      mainAxisSpacing: _optionGap,
                      childAspectRatio: grid.aspectRatio,
                    ),
                    itemBuilder: (context, index) =>
                        _buildOption(question, index),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildOption(MathQuestion question, int index) {
    final value = question.options[index];
    final isLocked = _lockedOptions.contains(index);
    final isAnswered = _answeredIndex == index;

    // Colours only tell the options apart. Red and green are left out so no
    // option reads as "right" or "wrong" before it is chosen.
    const colors = [
      Brand.gameAttention,
      Brand.gameMemory,
      Brand.gameWord,
      Brand.gameLetter,
    ];
    final color = colors[index % colors.length];

    var shift = 0.0;
    if (_shakingIndex == index && _shake.isAnimating) {
      shift = sin(_shake.value * pi * 6) * 8 * (1 - _shake.value);
    }

    return Semantics(
      button: true,
      enabled: !isLocked,
      selected: isAnswered,
      label: '$value',
      excludeSemantics: true,
      onTap: isLocked ? null : () => _handleOptionTap(index),
      child: Transform.translate(
        offset: Offset(shift, 0),
        child: AnimatedOpacity(
          opacity: isLocked ? 0.35 : 1,
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(Brand.cardRadius),
            elevation: 3,
            shadowColor: color.withValues(alpha: 0.45),
            child: InkWell(
              onTap: () => _handleOptionTap(index),
              borderRadius: BorderRadius.circular(Brand.cardRadius),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Brand.cardRadius),
                  border: Border.all(
                    color: isAnswered ? Brand.leaf : Colors.transparent,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$value',
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
            ),
          ),
        ),
      ),
    );
  }
}

/// The things a question is about: one group to count, two groups to add, or
/// a group with some of them crossed out to take away.
class _ObjectPicture extends StatelessWidget {
  const _ObjectPicture({required this.question, required this.palette});

  final MathQuestion question;
  final GamePalette palette;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = switch (question.task) {
          MathTask.count => question.left,
          MathTask.add => question.left + question.right,
          MathTask.subtract => question.left,
        };

        // Small enough that twenty of them still fit the card.
        final size =
            (constraints.biggest.shortestSide / 2.4 - total * 0.6).clamp(
          14.0,
          34.0,
        );

        final gone = question.task == MathTask.subtract ? question.right : 0;

        final things = <Widget>[
          for (var i = 0; i < total; i++)
            _Thing(
              symbol: question.object,
              size: size,
              // Taking away crosses out the last ones.
              isGone: i >= total - gone,
              palette: palette,
            ),
        ];

        if (question.task != MathTask.add) {
          return Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: things,
            ),
          );
        }

        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: things.take(question.left).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: size,
                    fontWeight: FontWeight.w900,
                    color: palette.label,
                  ),
                ),
              ),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: things.skip(question.left).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Thing extends StatelessWidget {
  const _Thing({
    required this.symbol,
    required this.size,
    required this.isGone,
    required this.palette,
  });

  final String symbol;
  final double size;
  final bool isGone;
  final GamePalette palette;

  @override
  Widget build(BuildContext context) {
    final thing = Text(symbol, style: TextStyle(fontSize: size));

    if (!isGone) return thing;

    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: 0.3, child: thing),
        Icon(Icons.close_rounded, size: size * 0.9, color: palette.label),
      ],
    );
  }
}

typedef _SettledRound = ({
  int levelIndex,
  int roundsCleared,
  RoundOutcome outcome,
});
