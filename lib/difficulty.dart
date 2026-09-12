/// How hard a game should be, in one place.
///
/// Before this, "difficulty" meant three unrelated things:
///   * `childAge` if-chains copied into five games, with four age bands
///   * `levelForAge`, which used only three bands, so a 4 and a 7 year old
///     were treated the same in one game but differently in another
///   * a `level` field that in two games was recomputed from the question
///     index and never touched the questions at all — it only multiplied the
///     score while the screen claimed "Zor Seviye"
///
/// Now there is one concept: the child's [AgeBand] sets the baseline, and
/// [DifficultyTracker] raises it only when the child earns it.
library;

/// The four age bands the games are tuned for.
enum AgeBand {
  /// 4-5
  preschool,

  /// 6-7
  early,

  /// 8-9
  mid,

  /// 10-12
  older;

  static AgeBand forAge(int age) {
    if (age <= 5) return AgeBand.preschool;
    if (age <= 7) return AgeBand.early;
    if (age <= 9) return AgeBand.mid;
    return AgeBand.older;
  }

  /// 0..3 — index into a per-game table of four values.
  int get step => index;

  /// Parent-facing label for this band.
  String get label => switch (this) {
        AgeBand.preschool => '4 – 5 Yaş',
        AgeBand.early => '6 – 7 Yaş',
        AgeBand.mid => '8 – 9 Yaş',
        AgeBand.older => '10 – 12 Yaş',
      };
}

/// In-game difficulty that actually moves.
///
/// Starts at level 1 and rises after [stepsToLevelUp] correct answers in a
/// row. A wrong answer resets the streak but never lowers the level: for a
/// 4-8 year old the point is encouragement, not punishment.
class DifficultyTracker {
  DifficultyTracker({required this.band});

  final AgeBand band;

  static const int stepsToLevelUp = 3;
  static const int maxLevel = 3;

  int _level = 1;
  int _streak = 0;

  /// 1..3. Shown to the child as Kolay / Orta / Zor.
  int get level => _level;

  /// How many correct answers in a row so far.
  int get streak => _streak;

  /// 0..2 — how much to add on top of the age baseline.
  int get boost => _level - 1;

  void correct() {
    _streak++;

    if (_streak >= stepsToLevelUp && _level < maxLevel) {
      _level++;
      _streak = 0;
    }
  }

  void wrong() => _streak = 0;

  void reset() {
    _level = 1;
    _streak = 0;
  }

  /// Picks from a four-entry table by age band, then adds what the child has
  /// earned, clamped to [max].
  int scaled(List<int> byBand, {required int max}) {
    final base = byBand[band.step];
    final value = base + boost;
    return value > max ? max : value;
  }
}

/// Label for the level chip.
String levelLabel(int level) => switch (level) {
      1 => '🟢 Kolay Seviye',
      2 => '🟡 Orta Seviye',
      _ => '🔴 Zor Seviye',
    };

/// One rung of a game's level ladder.
class GameLevel {
  const GameLevel({required this.cards, required this.roundsToAdvance});

  /// How many cards are on the board at this level.
  final int cards;

  /// Clean rounds needed here before the next rung opens.
  final int roundsToAdvance;
}

/// The memory game's ladder.
///
/// Shaped from developmental evidence rather than round numbers:
///
///   * Visual working memory is roughly 1.5 items at age 5, 3 at 7 and
///     adult-like (3-4) around 10 (Riggs et al. 2006; Ross-Sheehy et al.
///     2021). A matching grid is easier than a span test — it is sequential,
///     self-paced, and the board itself is an external memory aid — so grid
///     size can exceed that span, but not by an unlimited factor.
///   * Ross-Sheehy et al. (2021) found 4-7 year olds' measured capacity
///     DROPS on larger arrays: they disengage and start guessing. An
///     oversized board does not just slow a child down, it teaches the wrong
///     behaviour. Hence the conservative bottom of this ladder.
///   * 4 -> 8 would double the cards in one step, the largest proportional
///     jump anywhere, landing exactly on the 4-5 year old ceiling. A 6-card
///     rung sits in between.
///   * 10 cards is skipped: it has no layout that fills a phone screen
///     without a ragged last row.
///
/// The rung counts are a calibration, not a measured constant. What the
/// evidence settles is the shape: start low, grow slowly at the bottom.
const List<GameLevel> memoryLadder = [
  // Teaches the rule without words; a non-reader cannot really fail it.
  GameLevel(cards: 4, roundsToAdvance: 2),
  GameLevel(cards: 6, roundsToAdvance: 3),
  GameLevel(cards: 8, roundsToAdvance: 3),
  GameLevel(cards: 12, roundsToAdvance: 3),
  GameLevel(cards: 16, roundsToAdvance: 3),
  GameLevel(cards: 20, roundsToAdvance: 3),
];

/// Where a child of this age starts the ladder.
///
/// Nobody is locked out of the lower rungs and nobody is dropped back down:
/// helplessness responses are already present at 4-7 (Burhans & Dweck 1995),
/// so the level never visibly goes backwards.
int startingLevelFor(AgeBand band) => switch (band) {
      AgeBand.preschool => 0,
      AgeBand.early => 1,
      AgeBand.mid => 2,
      AgeBand.older => 3,
    };
