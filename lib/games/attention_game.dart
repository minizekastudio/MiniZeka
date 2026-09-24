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
import 'attention_round.dart';

/// Find the one box that is not like the others.
///
/// How hard that is comes from how much the odd one out resembles the rest,
/// not from how many boxes there are, so the rungs of [attentionLadder] raise
/// similarity first (see [AttentionRule]). It used to pair two faces at
/// random from one flat list, which made one board free and the next
/// impossible.
class AttentionGame extends StatefulWidget {
  const AttentionGame({super.key, this.random});

  /// Injected by tests so a round can be reproduced.
  final Random? random;

  @override
  State<AttentionGame> createState() => _AttentionGameState();
}

class _AttentionGameState extends State<AttentionGame>
    with TickerProviderStateMixin, GameSessionMixin {
  @override
  GameId get game => GameId.attention;

  @override
  String get timeUpMessage =>
      'Dikkat oyunu için belirlenen günlük süreyi kullandın. 🌙';

  @override
  int get currentScore => score;

  @override
  bool get canShowTimeUpDialog => !_isRoundOver;

  static const double _boxGap = 8;

  /// Time to see the found box light up before the next board.
  static const Duration _foundHold = Duration(milliseconds: 800);

  static const Duration _idleBeforeDemo = Duration(seconds: 5);

  /// After this many wrong taps on one board, the odd one out pulses.
  static const int _hintAfterWrongTaps = 2;

  late final Random _random = widget.random ?? Random();

  // ---- ladder -------------------------------------------------------------

  int levelIndex = 0;
  int roundsCleared = 0;

  GameLevel get level => attentionLadder[levelIndex];

  @override
  void onChildAgeLoaded() {
    levelIndex = startingLevelFor(ageBand);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final resumed = resumeLadder(
      ladder: attentionLadder,
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

  List<AttentionBoard> _round = const [];
  int _boardIndex = 0;
  int score = 0;

  int _firstTryMistakes = 0;
  int _wrongTapsThisBoard = 0;
  final Set<int> _lockedBoxes = {};

  int? _foundIndex;
  bool _isResolving = false;
  bool _isRoundOver = false;
  int _roundGeneration = 0;

  AttentionBoard? get _board => _round.isEmpty ? null : _round[_boardIndex];

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
  Timer? _demoTimer;
  Timer? _holdTimer;
  bool _isShowingDemo = false;

  @override
  void initState() {
    super.initState();
    startGameSession();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _holdTimer?.cancel();
    _shake.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ---- flow ---------------------------------------------------------------

  void _startRound() {
    _roundGeneration++;

    _round = buildAttentionRound(rung: levelIndex, random: _random);
    _boardIndex = 0;
    score = 0;
    _firstTryMistakes = 0;
    _isRoundOver = false;

    _beginBoard();
  }

  void _beginBoard() {
    _wrongTapsThisBoard = 0;
    _lockedBoxes.clear();
    _foundIndex = null;
    _shakingIndex = null;
    _isResolving = false;

    _stopPulse();
    _scheduleDemo();
  }

  /// On the very first rung a hand shows what to tap if the first board sits
  /// untouched. Nowhere else: it would hand over the answer.
  void _scheduleDemo() {
    _demoTimer?.cancel();
    _isShowingDemo = false;

    if (levelIndex != 0 || _boardIndex != 0) return;

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

  void _handleBoxTap(int index) {
    if (!ensurePlayTimeLeft()) return;

    final board = _board;
    if (board == null || _isResolving || _isRoundOver) return;
    if (_lockedBoxes.contains(index)) return;

    _demoTimer?.cancel();

    if (index == board.differentIndex) {
      _resolveFound(index);
    } else {
      _handleWrong(index);
    }
  }

  void _handleWrong(int index) {
    SoundManager.playWrong();

    if (_wrongTapsThisBoard == 0) _firstTryMistakes++;
    _wrongTapsThisBoard++;

    setState(() {
      _lockedBoxes.add(index);
      _shakingIndex = index;
      _isShowingDemo = false;
    });

    _shake.forward(from: 0);

    // A wrong tap no longer ends the board: the child keeps looking, and
    // after a couple of tries the odd one out starts to pulse.
    if (_wrongTapsThisBoard >= _hintAfterWrongTaps) {
      _pulse.repeat(reverse: true);
    } else {
      _stopPulse();
    }
  }

  void _resolveFound(int index) {
    final generation = _roundGeneration;
    final isFirstTry = _wrongTapsThisBoard == 0;

    SoundManager.playCorrect();
    _stopPulse();

    setState(() {
      _isResolving = true;
      _foundIndex = index;
      _isShowingDemo = false;

      if (isFirstTry) score += (levelIndex + 1) * 10;
    });

    // A finished round is settled and saved before the pause, so leaving
    // during it keeps what the round earned.
    final isLastBoard = _boardIndex + 1 >= _round.length;
    final settled = isLastBoard ? _settleRound() : null;

    _holdTimer?.cancel();
    _holdTimer = Timer(_foundHold, () {
      if (!mounted || generation != _roundGeneration) return;

      if (settled == null) {
        setState(() {
          _boardIndex++;
          _beginBoard();
        });
      } else {
        _finishRound(settled);
      }
    });
  }

  _SettledRound _settleRound() {
    AchievementManager.unlock('attention_master');
    AchievementManager.unlock('first_step');
    AchievementManager.markGamePlayed(game);

    if (isCleanRound(_firstTryMistakes)) {
      final next = advanceLadder(
        ladder: attentionLadder,
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

    // The allowance ran out during the pause and its warning is already up.
    if (timeUpDialogShown) return;

    final firstTryRight = _round.length - _firstTryMistakes;

    showLadderRoundDialog(
      context: context,
      palette: palette,
      outcome: settled.outcome,
      ladder: attentionLadder,
      levelIndex: levelIndex,
      roundsCleared: roundsCleared,
      levelUpMessage: _newRungMessage(attentionRuleFor(levelIndex)),
      masteredMessage: 'Gözünden hiçbir şey kaçmıyor! ✨',
      flair: '👀',
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

  static String _newRungMessage(AttentionRule rule) {
    if (rule.isTargetFromSameGroup && rule.hasMixedDistractors) {
      return 'Artık hepsi birbirine benziyor! 👀';
    }
    if (rule.isTargetFromSameGroup) return 'Artık fark çok küçük! 🔍';
    if (rule.hasMixedDistractors) return 'Artık kutular karışık! 🔀';
    return 'Hadi başlayalım! ✨';
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final board = _board;

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
                    value: '${_boardIndex + 1} / $questionsPerRound',
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
            Expanded(child: _buildBoard(board)),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(AttentionBoard? board) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: board == null
          ? const SizedBox.shrink()
          : LayoutBuilder(
              builder: (context, constraints) {
                final grid = fitGrid(
                  board.items.length,
                  constraints.biggest,
                  _boxGap,
                );

                return AnimatedBuilder(
                  animation: Listenable.merge([_shake, _pulse]),
                  builder: (context, _) => GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: board.items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: grid.columns,
                      crossAxisSpacing: _boxGap,
                      mainAxisSpacing: _boxGap,
                      childAspectRatio: grid.aspectRatio,
                    ),
                    itemBuilder: (context, index) => _buildBox(board, index),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBox(AttentionBoard board, int index) {
    final isTarget = index == board.differentIndex;
    final isLocked = _lockedBoxes.contains(index);
    final isFound = _foundIndex == index;
    final isHinted =
        isTarget &&
        !_isResolving &&
        (_isShowingDemo || _wrongTapsThisBoard >= _hintAfterWrongTaps);

    var scale = 1.0;
    if (isHinted) scale += 0.07 * _pulse.value;
    if (isFound) scale += 0.08;

    var shift = 0.0;
    if (_shakingIndex == index && _shake.isAnimating) {
      shift = sin(_shake.value * pi * 6) * 8 * (1 - _shake.value);
    }

    return Semantics(
      button: true,
      enabled: !isLocked,
      selected: isFound,
      label: board.items[index],
      excludeSemantics: true,
      onTap: isLocked ? null : () => _handleBoxTap(index),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleBoxTap(index),
        child: Transform.translate(
          offset: Offset(shift, 0),
          child: Transform.scale(
            scale: scale,
            child: AnimatedOpacity(
              opacity: isLocked ? 0.35 : 1,
              duration: const Duration(milliseconds: 200),
              child: LayoutBuilder(
                builder: (context, constraints) => Container(
                  decoration: BoxDecoration(
                    color: Brand.cardLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isFound ? Brand.leaf : Colors.transparent,
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Text(
                          board.items[index],
                          // Sized from the box, not fixed: a 16-box board on
                          // a small phone used to clip its emoji.
                          style: TextStyle(
                            fontSize: constraints.biggest.shortestSide * 0.5,
                          ),
                        ),
                      ),
                      if (isTarget && _isShowingDemo)
                        Align(
                          alignment: const Alignment(0.7, 0.8),
                          child: Transform.translate(
                            offset: Offset(0, -8 * _pulse.value),
                            child: const Text(
                              '👆',
                              style: TextStyle(fontSize: 28),
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
    );
  }
}

typedef _SettledRound = ({
  int levelIndex,
  int roundsCleared,
  RoundOutcome outcome,
});
