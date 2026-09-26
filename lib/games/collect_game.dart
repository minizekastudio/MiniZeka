import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../achievement_manager.dart';
import '../app_theme.dart';
import '../difficulty.dart';
import '../game_id.dart';
import '../game_kit.dart';
import '../sound_manager.dart';
import '../storage_keys.dart';
import 'collect_round.dart';

/// Steer the squirrel with a finger and gather the face shown at the top.
///
/// The seven games before this one all ask a child to tap a board that is
/// standing still; this is the first that moves. What it adds is the
/// attention game's skill under motion — keeping to a rule while something
/// else is happening — and the top rung changes the rule halfway through.
///
/// Nothing can be lost. The owl costs one gathered face, which lands back on
/// the board, and then falls asleep.
class CollectGame extends StatefulWidget {
  const CollectGame({super.key, this.random});

  /// Injected by tests so a board can be reproduced.
  final Random? random;

  @override
  State<CollectGame> createState() => _CollectGameState();
}

class _CollectGameState extends State<CollectGame>
    with TickerProviderStateMixin, GameSessionMixin {
  @override
  GameId get game => GameId.collect;

  @override
  String get timeUpMessage =>
      'Sincap Koşusu için belirlenen günlük süreyi kullandın. 🌙';

  @override
  int get currentScore => score;

  @override
  bool get canShowTimeUpDialog => !_isRoundOver;

  static const Duration _wonHold = Duration(milliseconds: 900);

  /// A frame longer than this means the app was away; stepping the world by
  /// it would teleport everything.
  static const double _longestStep = 1 / 20;

  late final Random _random = widget.random ?? Random();

  // ---- ladder -------------------------------------------------------------

  int levelIndex = 0;
  int roundsCleared = 0;

  GameLevel get level => collectLadder[levelIndex];

  @override
  void onChildAgeLoaded() {
    levelIndex = startingLevelFor(ageBand);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final resumed = resumeLadder(
      ladder: collectLadder,
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

  CollectWorld? _world;
  int score = 0;
  bool _isRoundOver = false;
  int _roundGeneration = 0;

  // ---- animation ----------------------------------------------------------

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  Timer? _holdTimer;

  /// Seconds since this board opened. Every idle wiggle reads from it, so
  /// the running loop drives them all rather than a controller each.
  double _elapsed = 0;

  /// Faces caught in the act of being gathered, fading upward.
  final List<_Pop> _pops = [];

  /// Which way the squirrel last ran. Kept rather than read from the current
  /// velocity, or it would snap back to facing left every time it stopped.
  bool _isFacingRight = false;

  late final AnimationController _bannerPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    startGameSession();

    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _ticker?.dispose();
    _bannerPulse.dispose();
    super.dispose();
  }

  /// The board freezes whenever the child cannot play: a dialog on top, the
  /// app in the background, or the day's allowance gone.
  @override
  void onPlayableChanged(bool isPlayable) {
    if (isPlayable && !_isRoundOver) {
      _resumeTicker();
    } else {
      _ticker?.stop();
    }
  }

  void _resumeTicker() {
    if (_ticker?.isTicking ?? true) return;

    // Starting from zero again, so the pause is not replayed as one huge
    // step that teleports everything across the board.
    _lastTick = Duration.zero;
    _ticker?.start();
  }

  // ---- flow ---------------------------------------------------------------

  void _startRound() {
    _roundGeneration++;

    _world = buildCollectBoard(rung: levelIndex, random: _random);
    score = 0;
    _isRoundOver = false;
    _elapsed = 0;
    _pops.clear();
    _isFacingRight = false;

    _resumeTicker();
  }

  void _onTick(Duration elapsed) {
    final world = _world;
    if (world == null) return;

    final dt = _lastTick == Duration.zero
        ? 0.0
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    if (dt <= 0) return;

    final step = min(dt, _longestStep);
    _elapsed += step;

    // Pops outlive the board: the last face is gathered and the round is
    // over on the same frame, and its pop still has to play.
    _pops.removeWhere((pop) => _elapsed - pop.startedAt > _Pop.seconds);

    if (!_isRoundOver) {
      final collectedBefore = world.collected;

      world.step(step);

      for (final item in world.justCollected) {
        _pops.add(
          _Pop(face: item.face, at: item.position, startedAt: _elapsed),
        );
      }

      if (world.collected > collectedBefore) {
        SoundManager.playCorrect();
        score += (levelIndex + 1) * 10;
      }

      if (world.wasRefused) SoundManager.playWrong();

      if (world.targetJustChanged) _bannerPulse.forward(from: 0);

      if (world.velocity.x.abs() > 0.05) {
        _isFacingRight = world.velocity.x > 0;
      }

      if (world.isFinished) _finishBoard();
    }

    setState(() {});
  }

  void _finishBoard() {
    final generation = _roundGeneration;
    final settled = _settleRound();

    // The ticker keeps running through the hold so the last pop plays out;
    // _isRoundOver is what freezes the board itself.
    setState(() => _isRoundOver = true);

    _holdTimer?.cancel();
    _holdTimer = Timer(_wonHold, () {
      if (!mounted || generation != _roundGeneration) return;

      _ticker?.stop();
      _showRoundDialog(settled);
    });
  }

  /// Where the finger is, in board units.
  void _steer(Offset local, Size board) {
    if (_isRoundOver) return;
    if (!ensurePlayTimeLeft()) return;

    _world?.steerTo(
      BoardPoint(local.dx / board.width, local.dy / board.height),
    );
  }

  _SettledRound _settleRound() {
    AchievementManager.unlock('collector');
    AchievementManager.unlock('first_step');
    AchievementManager.markGamePlayed(game);

    // Not isCleanRound: that counts mistakes out of five questions, and a
    // board is not five questions. See CollectRule.allowedMistakes.
    final rule = collectRuleFor(levelIndex);

    if ((_world?.wrongGrabs ?? 0) <= rule.allowedMistakes) {
      final next = advanceLadder(
        ladder: collectLadder,
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

  void _showRoundDialog(_SettledRound settled) {
    final world = _world;

    setState(() {
      levelIndex = settled.levelIndex;
      roundsCleared = settled.roundsCleared;
    });

    if (timeUpDialogShown) return;

    showLadderRoundDialog(
      context: context,
      palette: palette,
      outcome: settled.outcome,
      ladder: collectLadder,
      levelIndex: levelIndex,
      roundsCleared: roundsCleared,
      levelUpMessage: _newRungMessage(collectRuleFor(levelIndex)),
      masteredMessage: 'Sincap senden hızlı değil! ✨',
      flair: '🐿️',
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
          title: 'Yanlış',
          value: '${world?.wrongGrabs ?? 0}',
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

  static String _newRungMessage(CollectRule rule) {
    if (rule.switchesTarget) return 'Artık toplanacak şey değişiyor! 🔄';
    if (rule.chaserCount > 1) return 'Artık iki baykuş var! 🦉';
    if (rule.hasMixedDistractors) return 'Artık her şey karışık! 🌀';
    if (rule.isSameCluster) return 'Artık birbirine benziyorlar! 🔎';
    if (rule.chaserCount > 0) return 'Dikkat, baykuş uyandı! 🦉';
    return 'Hadi başlayalım! ✨';
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final world = _world;

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
                    emoji: '🧺',
                    title: 'Toplanan',
                    value: world == null
                        ? '0 / 0'
                        : '${world.collected} / ${world.targetTotal}',
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
            const SizedBox(height: 8),
            LadderStrip(
              palette: palette,
              levelIndex: levelIndex,
              roundsCleared: roundsCleared,
              roundsToAdvance: level.roundsToAdvance,
            ),
            const SizedBox(height: 6),
            GameTimeBar(
              palette: palette,
              progress: timeProgress,
              remaining: gameTimer.formattedRemaining,
            ),
            const SizedBox(height: 8),
            _buildTargetBanner(world),
            const SizedBox(height: 8),
            Expanded(child: _buildBoard(world)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// What to gather, with no words: the face itself, large.
  Widget _buildTargetBanner(CollectWorld? world) {
    if (world == null) return const SizedBox(height: 58);

    return Semantics(
      label: 'Toplanacak: ${world.targetFace}',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _bannerPulse,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.18 * sin(_bannerPulse.value * pi),
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: palette.softBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.button, width: 3),
          ),
          child: Text(world.targetFace, style: const TextStyle(fontSize: 34)),
        ),
      ),
    );
  }

  Widget _buildBoard(CollectWorld? world) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // A square board: stretching the world to a rectangle would make the
        // squirrel faster sideways than up, and collisions oval.
        final side = min(constraints.maxWidth - 24, constraints.maxHeight);
        final board = Size(side, side);

        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (details) => _steer(details.localPosition, board),
            onPanUpdate: (details) => _steer(details.localPosition, board),
            onTapDown: (details) => _steer(details.localPosition, board),
            child: Container(
              key: const ValueKey('collect-board'),
              width: side,
              height: side,
              decoration: BoxDecoration(
                color: Brand.cardLight,
                borderRadius: BorderRadius.circular(Brand.cardRadius),
                border: Border.all(color: palette.softBackground, width: 3),
              ),
              clipBehavior: Clip.antiAlias,
              child: world == null
                  ? const SizedBox.shrink()
                  : Stack(children: _pieces(world, side)),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _pieces(CollectWorld world, double side) {
    return [
      for (var i = 0; i < world.items.length; i++)
        if (!world.items[i].isCollected)
          _piece(
            key: ValueKey(world.items[i]),
            at: world.items[i].position,
            side: side,
            radius: CollectWorld.itemRadius,
            child: _buildItem(world.items[i], i),
          ),
      for (final pop in _pops)
        _piece(
          key: ValueKey(pop),
          at: pop.at,
          side: side,
          radius: CollectWorld.itemRadius,
          child: _buildPop(pop),
        ),
      for (var i = 0; i < world.chasers.length; i++)
        _piece(
          at: world.chasers[i].position,
          side: side,
          radius: CollectWorld.chaserRadius,
          child: _buildChaser(world.chasers[i], i),
        ),
      _piece(
        at: world.player,
        side: side,
        radius: CollectWorld.playerRadius,
        child: _buildSquirrel(world),
      ),
    ];
  }

  /// A soft patch of ground under a moving piece.
  ///
  /// The board is a blank square, so a hop had nothing to be measured
  /// against: the squirrel read as sliding. The shadow stays put and shrinks
  /// as the piece rises, which is what makes the hop a hop.
  Widget _shadow({double lift = 0}) {
    final closeness = (1 - lift).clamp(0.35, 1.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        widthFactor: 0.52 * closeness,
        heightFactor: 0.12 * closeness,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.10 * closeness),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  /// Waiting faces breathe, each on its own beat, and a refused one shakes
  /// its head instead of merely dimming.
  Widget _buildItem(CollectItem item, int index) {
    final isRefused = item.refusedFor > 0;

    final shake = isRefused
        ? sin(item.refusedFor * pi * 10) * 0.16 * item.refusedFor
        : 0.0;

    final breath = 1 + 0.05 * sin(_elapsed * 2.1 + index * 1.7);

    return Transform.rotate(
      angle: shake,
      child: Transform.scale(
        scale: isRefused ? 0.86 : breath,
        child: Opacity(
          opacity: isRefused ? 0.45 : 1,
          child: FittedBox(fit: BoxFit.contain, child: Text(item.face)),
        ),
      ),
    );
  }

  /// A gathered face swells and lifts away rather than blinking out, so the
  /// child sees where the point came from.
  Widget _buildPop(_Pop pop) {
    final progress = ((_elapsed - pop.startedAt) / _Pop.seconds).clamp(
      0.0,
      1.0,
    );

    return Transform.translate(
      offset: Offset(0, -progress * 34),
      child: Transform.scale(
        scale: 1 + progress * 0.7,
        child: Opacity(
          opacity: 1 - progress,
          child: FittedBox(fit: BoxFit.contain, child: Text(pop.face)),
        ),
      ),
    );
  }

  /// Awake owls rock as they come; a sleeping one slumps with a 💤.
  Widget _buildChaser(Chaser chaser, int index) {
    if (chaser.isAsleep) {
      return Opacity(
        opacity: 0.45,
        child: Stack(
          fit: StackFit.expand,
          children: [_shadow(), _buildSleepingOwl()],
        ),
      );
    }

    final bob = sin(_elapsed * 11 + index * 2) * 2;

    return Stack(
      fit: StackFit.expand,
      children: [
        _shadow(lift: bob.abs() / 10),
        Transform.rotate(
          angle: sin(_elapsed * 5.5 + index * 2) * 0.13,
          child: Transform.translate(
            offset: Offset(0, bob),
            child: const FittedBox(fit: BoxFit.contain, child: Text('🦉')),
          ),
        ),
      ],
    );
  }

  Widget _buildSleepingOwl() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.rotate(
          angle: 0.25,
          child: const FittedBox(fit: BoxFit.contain, child: Text('🦉')),
        ),
        Align(
          alignment: Alignment.topRight,
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 0.5,
            child: Transform.translate(
              offset: Offset(0, sin(_elapsed * 2.4) * 3),
              child: const FittedBox(fit: BoxFit.contain, child: Text('💤')),
            ),
          ),
        ),
      ],
    );
  }

  /// The squirrel faces where it is going and hops while it runs.
  ///
  /// Without this it slid sideways and backwards like a game piece being
  /// pushed across a board, which is what the whole game looked like.
  Widget _buildSquirrel(CollectWorld world) {
    final speed = world.velocity.magnitude;
    final isRunning = speed > 0.02;

    final pace = isRunning ? (speed / CollectWorld.playerSpeed) : 0.0;
    final hop = isRunning ? -(sin(_elapsed * 17).abs()) * 6 * pace : 0.0;
    final lean = isRunning ? sin(_elapsed * 17) * 0.09 * pace : 0.0;
    final idle = isRunning ? 1.0 : 1 + 0.04 * sin(_elapsed * 3);

    // Flashing rather than merely faded, so "cannot be caught again" reads
    // as a state and not as a dimmed sprite.
    final opacity = world.isSafe ? 0.35 + 0.35 * (sin(_elapsed * 16) + 1) : 1.0;

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _shadow(lift: hop.abs() / 6),
          Transform.translate(
            offset: Offset(0, hop),
            child: Transform.rotate(
              angle: lean,
              child: Transform.scale(
                // The emoji faces left, so one heading right is mirrored.
                scaleX: _isFacingRight ? -idle : idle,
                scaleY: idle,
                child: const FittedBox(fit: BoxFit.contain, child: Text('🐿️')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _piece({
    Key? key,
    required BoardPoint at,
    required double side,
    required double radius,
    required Widget child,
  }) {
    final size = radius * 2 * side;

    return Positioned(
      key: key,
      left: at.x * side - size / 2,
      top: at.y * side - size / 2,
      width: size,
      height: size,
      child: child,
    );
  }
}

/// A face in the act of being gathered.
class _Pop {
  _Pop({required this.face, required this.at, required this.startedAt});

  static const double seconds = 0.45;

  final String face;
  final BoardPoint at;
  final double startedAt;
}

typedef _SettledRound = ({
  int levelIndex,
  int roundsCleared,
  RoundOutcome outcome,
});
