import 'dart:math';

import '../difficulty.dart';
import 'memory_symbols.dart';

/// The board is a unit square; the screen scales it. Keeping the simulation
/// resolution-free is what lets a test step it frame by frame.
typedef BoardPoint = Point<double>;

/// What each rung of [collectLadder] puts on the board.
class CollectRule {
  const CollectRule({
    required this.targetCount,
    required this.distractorCount,
    required this.chaserCount,
    this.isSameCluster = false,
    this.hasMixedDistractors = false,
    this.switchesTarget = false,
    this.chaserSpeed = 0.20,
  });

  /// How many faces the child has to gather.
  final int targetCount;

  final int distractorCount;

  /// Owls. The first rung has none: the rule is learned before the chase.
  final int chaserCount;

  /// Whether the wrong faces come from the target's own look-alike group.
  ///
  /// Telling 🍎 from 🚗 is seeing two different things; telling 🍎 from 🍓
  /// while moving is the skill. The same groups the memory game keeps apart.
  final bool isSameCluster;

  /// Whether the wrong faces are drawn from more than one group.
  final bool hasMixedDistractors;

  /// Whether the target changes once the first face runs out.
  ///
  /// The board holds two collectable faces. Gather the first, and the banner
  /// switches to the second — the rule the child was following stops being
  /// the rule. That switch is the point of the top rung.
  final bool switchesTarget;

  /// Units per second. Always well under [CollectWorld.playerSpeed], so the
  /// child can always get away.
  final double chaserSpeed;

  /// Wrong grabs a board can still count as a clean round.
  ///
  /// The other games allow one mistake in five questions. A child crossing
  /// this board passes far more than five things, so a flat one would make
  /// the same carelessness cost much more here. Same ratio, more decisions.
  int get allowedMistakes =>
      max(1, (targetCount + distractorCount) ~/ questionsPerRound);
}

const List<CollectRule> collectRules = [
  CollectRule(targetCount: 5, distractorCount: 3, chaserCount: 0),
  CollectRule(
    targetCount: 6,
    distractorCount: 4,
    chaserCount: 1,
    chaserSpeed: 0.16,
  ),
  CollectRule(
    targetCount: 6,
    distractorCount: 5,
    chaserCount: 1,
    isSameCluster: true,
  ),
  CollectRule(
    targetCount: 7,
    distractorCount: 6,
    chaserCount: 1,
    isSameCluster: true,
    hasMixedDistractors: true,
  ),
  CollectRule(
    targetCount: 8,
    distractorCount: 7,
    chaserCount: 2,
    isSameCluster: true,
    hasMixedDistractors: true,
  ),
  CollectRule(
    targetCount: 8,
    distractorCount: 7,
    chaserCount: 2,
    isSameCluster: true,
    hasMixedDistractors: true,
    switchesTarget: true,
  ),
];

CollectRule collectRuleFor(int rung) =>
    collectRules[rung.clamp(0, collectRules.length - 1)];

/// One thing lying on the board.
class CollectItem {
  CollectItem({required this.face, required this.position});

  final String face;
  BoardPoint position;
  bool isCollected = false;

  /// True while the squirrel is standing on it.
  ///
  /// A mistake is counted when a contact *begins*. Without that, standing
  /// on a wrong face counted a new mistake every frame, and a child who
  /// paused in the wrong spot lost the round by doing nothing.
  bool isTouching = false;

  /// Seconds left of the "no, not that one" flash. Visual only.
  double refusedFor = 0;
}

/// A sleepy owl that drifts towards the squirrel.
class Chaser {
  Chaser({required this.position});

  BoardPoint position;

  /// Seconds of sleep left. A sleeping owl does not move.
  double sleepFor = 0;

  bool get isAsleep => sleepFor > 0;
}

/// The board, as a thing that can be stepped forward in time.
///
/// No Flutter here on purpose: the screen draws whatever this says, and a
/// test can run a whole round deterministically without a widget tree.
class CollectWorld {
  CollectWorld({
    required this.rule,
    required this.items,
    required this.targetFaces,
    required this.chasers,
    required BoardPoint player,
  }) : _player = player,
       _steer = player;

  /// Units per second. The board is crossed in a little over a second.
  static const double playerSpeed = 0.85;

  /// Half-widths, in board units.
  ///
  /// Sized from the narrowest phone: the board is about 284 px wide there,
  /// so an item is roughly 43 px across. Smaller than that and a four year
  /// old cannot tell 🍎 from 🍓, which is what the harder rungs ask.
  static const double playerRadius = 0.085;
  static const double itemRadius = 0.075;
  static const double chaserRadius = 0.085;

  /// How long an owl sleeps after it catches up.
  static const double sleepSeconds = 3;

  /// How long the squirrel cannot be caught again.
  static const double safeSeconds = 1.5;

  /// How long a wrongly grabbed face stays inert.
  static const double refusedSeconds = 1.2;

  final CollectRule rule;
  final List<CollectItem> items;
  final List<Chaser> chasers;

  /// The faces worth collecting, in the order they become the target.
  final List<String> targetFaces;

  BoardPoint _player;
  BoardPoint _steer;
  double _safeFor = 0;

  int collected = 0;
  int wrongGrabs = 0;

  /// Set for one frame when an owl catches up, so the screen can react.
  bool wasCaught = false;

  /// Set for one frame when a wrong face is grabbed.
  bool wasRefused = false;

  /// Set for one frame when the target changes.
  bool targetJustChanged = false;

  BoardPoint get player => _player;

  bool get isSafe => _safeFor > 0;

  /// Where the child's finger is pulling the squirrel.
  void steerTo(BoardPoint point) => _steer = _clampToBoard(point);

  /// The face to gather right now: the first one still on the board.
  String get targetFace {
    for (final face in targetFaces) {
      if (items.any((item) => item.face == face && !item.isCollected)) {
        return face;
      }
    }

    return targetFaces.last;
  }

  int get targetTotal =>
      items.where((item) => targetFaces.contains(item.face)).length;

  bool get isFinished => collected >= targetTotal;

  /// Advances the world by [dt] seconds.
  void step(double dt) {
    wasCaught = false;
    wasRefused = false;
    targetJustChanged = false;

    final faceBefore = targetFace;

    _safeFor = max(0, _safeFor - dt);

    for (final item in items) {
      item.refusedFor = max(0, item.refusedFor - dt);
    }

    _movePlayer(dt);
    _collide();
    _moveChasers(dt);

    if (targetFace != faceBefore) targetJustChanged = true;
  }

  void _movePlayer(double dt) {
    final toSteer = _steer - _player;
    final distance = toSteer.magnitude;

    if (distance < 1e-4) return;

    final step = min(distance, playerSpeed * dt);

    _player = _clampToBoard(
      BoardPoint(
        _player.x + toSteer.x / distance * step,
        _player.y + toSteer.y / distance * step,
      ),
    );
  }

  void _collide() {
    for (final item in items) {
      if (item.isCollected) {
        item.isTouching = false;
        continue;
      }

      final isTouching =
          _player.distanceTo(item.position) <= playerRadius + itemRadius;

      if (isTouching) {
        if (item.face == targetFace) {
          // Always collectable, even if the squirrel was already standing
          // here when this face became the target.
          item.isCollected = true;
          collected++;
        } else if (!item.isTouching) {
          // Wrong face: it refuses to be picked up and nothing else happens.
          // No life is lost, the round does not end, the board stays put.
          // Counted once per contact, not once per frame.
          item.refusedFor = refusedSeconds;
          wrongGrabs++;
          wasRefused = true;
        }
      }

      item.isTouching = isTouching;
    }
  }

  void _moveChasers(double dt) {
    for (final chaser in chasers) {
      if (chaser.isAsleep) {
        chaser.sleepFor = max(0, chaser.sleepFor - dt);
        continue;
      }

      final toPlayer = _player - chaser.position;
      final distance = toPlayer.magnitude;

      if (distance > 1e-4) {
        final step = min(distance, rule.chaserSpeed * dt);

        chaser.position = _clampToBoard(
          BoardPoint(
            chaser.position.x + toPlayer.x / distance * step,
            chaser.position.y + toPlayer.y / distance * step,
          ),
        );
      }

      if (isSafe) continue;
      if (_player.distanceTo(chaser.position) > playerRadius + chaserRadius) {
        continue;
      }

      _dropOne(chaser);
    }
  }

  /// Being caught costs one gathered face, which lands back on the board.
  ///
  /// It is never a loss: the face is still there to pick up again, the owl
  /// goes to sleep, and the squirrel cannot be caught again for a moment.
  void _dropOne(Chaser chaser) {
    chaser.sleepFor = sleepSeconds;
    _safeFor = safeSeconds;
    wasCaught = true;

    for (final item in items.reversed) {
      if (!item.isCollected) continue;

      item.isCollected = false;
      collected--;

      // Dropped a little away from the squirrel, so it is not re-collected
      // on the very next frame.
      item.position = _clampToBoard(
        BoardPoint(_player.x + 0.18, _player.y + 0.14),
      );

      return;
    }
  }

  static BoardPoint _clampToBoard(BoardPoint point) =>
      BoardPoint(point.x.clamp(0.0, 1.0), point.y.clamp(0.0, 1.0));
}

/// Builds a board for [rung].
///
/// [random] is injected so a board can be reproduced in tests.
CollectWorld buildCollectBoard({required int rung, required Random random}) {
  final rule = collectRuleFor(rung.clamp(0, collectLadder.length - 1));

  final faces = _dealFaces(rule, random);
  final targetFaces = rule.switchesTarget
      ? [faces.target, faces.distractors.first]
      : [faces.target];

  const playerStart = BoardPoint(0.5, 0.5);
  const corners = [BoardPoint(0.06, 0.06), BoardPoint(0.94, 0.94)];

  final items = <CollectItem>[];

  // The squirrel's spot and the owls' corners are taken before anything is
  // placed: a face sitting under the squirrel was gathered before the round
  // had begun, so a board opened at 1 / 5.
  final taken = <BoardPoint>[playerStart, ...corners.take(rule.chaserCount)];

  final keepOut = <BoardPoint>[playerStart, ...corners.take(rule.chaserCount)];

  BoardPoint place() {
    final point = _freeSpot(taken, keepOut, random);
    taken.add(point);
    return point;
  }

  // With a switching rule the child gathers both faces, so the target count
  // is split between them rather than doubled.
  if (rule.switchesTarget) {
    final first = rule.targetCount - rule.targetCount ~/ 2;

    for (var i = 0; i < first; i++) {
      items.add(CollectItem(face: targetFaces.first, position: place()));
    }
    for (var i = first; i < rule.targetCount; i++) {
      items.add(CollectItem(face: targetFaces.last, position: place()));
    }
  } else {
    for (var i = 0; i < rule.targetCount; i++) {
      items.add(CollectItem(face: faces.target, position: place()));
    }
  }

  final wrongFaces = [
    for (final face in faces.distractors)
      if (!targetFaces.contains(face)) face,
  ];

  for (var i = 0; i < rule.distractorCount; i++) {
    items.add(
      CollectItem(face: wrongFaces[i % wrongFaces.length], position: place()),
    );
  }

  items.shuffle(random);

  return CollectWorld(
    rule: rule,
    items: items,
    targetFaces: targetFaces,
    player: playerStart,
    chasers: [
      for (var i = 0; i < rule.chaserCount; i++)
        Chaser(position: corners[i % corners.length]),
    ],
  );
}

/// Picks the face to gather and the faces that must not be gathered.
({String target, List<String> distractors}) _dealFaces(
  CollectRule rule,
  Random random,
) {
  final groups = [...symbolClusters]..shuffle(random);

  // A same-cluster rung needs a group with something to confuse the target
  // with; the easy rungs deliberately take the wrong faces from elsewhere.
  final homeGroup = rule.isSameCluster
      ? groups.firstWhere(
          (group) => group.length >= 3,
          orElse: () => groups.first,
        )
      : groups.first;

  final faces = [...homeGroup]..shuffle(random);
  final target = faces.first;

  final nearMisses = faces.skip(1).toList();

  final elsewhere = [
    for (final group in groups)
      if (!identical(group, homeGroup)) group.first,
  ];

  final distractors = rule.isSameCluster
      ? [...nearMisses, if (rule.hasMixedDistractors) ...elsewhere]
      : elsewhere;

  return (target: target, distractors: distractors);
}

/// A spot far enough from everything already placed.
///
/// Distance from [taken] is a preference — a crowded board has to give
/// somewhere. Distance from [keepOut] is not: those are the squirrel's and
/// the owls' starting spots, and a face inside one of them would be gathered
/// before the child had touched the screen.
BoardPoint _freeSpot(
  List<BoardPoint> taken,
  List<BoardPoint> keepOut,
  Random random,
) {
  const margin = 0.12;
  const apart = 0.19;
  const clear = CollectWorld.playerRadius + CollectWorld.itemRadius + 0.03;

  BoardPoint candidate() => BoardPoint(
    margin + random.nextDouble() * (1 - margin * 2),
    margin + random.nextDouble() * (1 - margin * 2),
  );

  var best = candidate();
  var bestGap = _nearest(best, taken);

  // Bounded retries rather than a loop that can wedge on a crowded board.
  for (var attempt = 0; attempt < 60; attempt++) {
    final next = candidate();

    if (_nearest(next, keepOut) < clear) continue;

    final gap = _nearest(next, taken);

    if (gap > bestGap || _nearest(best, keepOut) < clear) {
      best = next;
      bestGap = gap;
    }

    if (bestGap >= apart) break;
  }

  // Whatever the retries settled on, the keep-out zones are guaranteed.
  for (final zone in keepOut) {
    best = _pushOutside(best, zone, clear);
  }

  return best;
}

/// Moves [point] straight out of [zone] until it is [minGap] away.
BoardPoint _pushOutside(BoardPoint point, BoardPoint zone, double minGap) {
  final dx = point.x - zone.x;
  final dy = point.y - zone.y;
  final distance = sqrt(dx * dx + dy * dy);

  if (distance >= minGap) return point;

  // Dead centre on the zone: any direction will do, so pick the one with
  // the most room.
  if (distance < 1e-6) {
    final away = zone.x < 0.5 ? minGap : -minGap;
    return BoardPoint((zone.x + away).clamp(0.05, 0.95), zone.y);
  }

  final scale = minGap / distance;

  return BoardPoint(
    (zone.x + dx * scale).clamp(0.05, 0.95),
    (zone.y + dy * scale).clamp(0.05, 0.95),
  );
}

double _nearest(BoardPoint point, List<BoardPoint> taken) {
  var nearest = double.infinity;

  for (final other in taken) {
    nearest = min(nearest, point.distanceTo(other));
  }

  return nearest;
}
