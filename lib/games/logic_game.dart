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
import 'logic_round.dart';

/// Spot what repeats, then say what belongs in the gap.
///
/// The game used to be twenty hand-written questions, five per age band —
/// a child saw a whole band in one round and the same five the next time —
/// and most of them were sentences the target age cannot read. Patterns are
/// wordless and endless; the rungs of [logicLadder] lengthen the unit that
/// repeats and then hide a step in the middle of the row.
class LogicGame extends StatefulWidget {
  const LogicGame({super.key, this.random});

  /// Injected by tests so a round can be reproduced.
  final Random? random;

  @override
  State<LogicGame> createState() => _LogicGameState();
}

class _LogicGameState extends State<LogicGame>
    with TickerProviderStateMixin, GameSessionMixin {
  @override
  GameId get game => GameId.logic;

  @override
  String get timeUpMessage =>
      'Mantık oyunu için belirlenen günlük süreyi kullandın. 🌙';

  @override
  int get currentScore => score;

  @override
  bool get canShowTimeUpDialog => !_isRoundOver;

  static const double _optionGap = 12;

  static const Duration _foundHold = Duration(milliseconds: 800);

  /// After this many wrong taps the repeating unit is pointed out.
  static const int _hintAfterWrongTaps = 2;

  late final Random _random = widget.random ?? Random();

  // ---- ladder -------------------------------------------------------------

  int levelIndex = 0;
  int roundsCleared = 0;

  GameLevel get level => logicLadder[levelIndex];

  @override
  void onChildAgeLoaded() {
    levelIndex = startingLevelFor(ageBand);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final resumed = resumeLadder(
      ladder: logicLadder,
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

  List<LogicQuestion> _round = const [];
  int _questionIndex = 0;
  int score = 0;

  int _firstTryMistakes = 0;
  int _wrongTapsThisQuestion = 0;
  final Set<int> _lockedOptions = {};

  int? _answeredIndex;
  bool _isResolving = false;
  bool _isRoundOver = false;
  int _roundGeneration = 0;

  LogicQuestion? get _question =>
      _round.isEmpty ? null : _round[_questionIndex];

  bool get _showsUnitHint => _wrongTapsThisQuestion >= _hintAfterWrongTaps;

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

    _round = buildLogicRound(rung: levelIndex, random: _random);
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

    // A wrong answer does not end the question. After two tries the part
    // that repeats is pointed out, which is the thing to read here.
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
    AchievementManager.unlock('logic_master');
    AchievementManager.unlock('first_step');
    AchievementManager.markGamePlayed(game);

    if (isCleanRound(_firstTryMistakes)) {
      final next = advanceLadder(
        ladder: logicLadder,
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
      ladder: logicLadder,
      levelIndex: levelIndex,
      roundsCleared: roundsCleared,
      levelUpMessage: _newRungMessage(logicRuleFor(levelIndex)),
      masteredMessage: 'Örüntüleri çözüyorsun! ✨',
      flair: '🧩',
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

  static String _newRungMessage(LogicRule rule) {
    if (!rule.isGapAtEnd) return 'Artık eksik parça ortada! 🔎';
    if (rule.units.contains(PatternUnit.abc)) {
      return 'Artık üç şeyli örüntüler! 🧩';
    }
    if (rule.units.length > 1) return 'Artık örüntüler uzuyor! 🧩';
    return 'Hadi başlayalım! ✨';
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
            Expanded(flex: 4, child: _buildPatternCard(question)),
            const SizedBox(height: 12),
            Expanded(flex: 6, child: _buildOptions(question)),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternCard(LogicQuestion? question) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(12),
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
          : LayoutBuilder(
              builder: (context, constraints) {
                final step = constraints.biggest.width /
                    (question.sequence.length + 0.5);
                final size = min(step * 0.7, constraints.biggest.height * 0.5);

                return AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < question.sequence.length; i++)
                        _buildStep(question, i, size),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStep(LogicQuestion question, int index, double size) {
    final isGap = index == question.gapIndex;
    final isAnswered = isGap && _answeredIndex != null;

    // The hint lifts the first repetition: that is the part to read.
    final isInUnit = index < question.unit.slots.length;
    final scale = _showsUnitHint && isInUnit ? 1 + 0.12 * _pulse.value : 1.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size * 0.06),
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: size,
          height: size,
          child: isGap && !isAnswered
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.softBackground,
                    borderRadius: BorderRadius.circular(size * 0.25),
                    border: Border.all(color: palette.button, width: 3),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '?',
                        style: TextStyle(
                          fontSize: size * 0.6,
                          fontWeight: FontWeight.w900,
                          color: palette.button,
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      question.sequence[index],
                      style: TextStyle(fontSize: size * 0.8),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOptions(LogicQuestion? question) {
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

  Widget _buildOption(LogicQuestion question, int index) {
    final symbol = question.options[index];
    final isLocked = _lockedOptions.contains(index);
    final isAnswered = _answeredIndex == index;

    var shift = 0.0;
    if (_shakingIndex == index && _shake.isAnimating) {
      shift = sin(_shake.value * pi * 6) * 8 * (1 - _shake.value);
    }

    return Semantics(
      button: true,
      enabled: !isLocked,
      selected: isAnswered,
      label: symbol,
      excludeSemantics: true,
      onTap: isLocked ? null : () => _handleOptionTap(index),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleOptionTap(index),
        child: Transform.translate(
          offset: Offset(shift, 0),
          child: AnimatedOpacity(
            opacity: isLocked ? 0.35 : 1,
            duration: const Duration(milliseconds: 200),
            child: LayoutBuilder(
              builder: (context, constraints) => Container(
                decoration: BoxDecoration(
                  color: Brand.cardLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAnswered ? Brand.leaf : Colors.transparent,
                    width: 4,
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
                  child: Text(
                    symbol,
                    style: TextStyle(
                      fontSize: constraints.biggest.shortestSide * 0.5,
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
