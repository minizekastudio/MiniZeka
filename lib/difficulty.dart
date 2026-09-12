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
