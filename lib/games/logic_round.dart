import 'dart:math';

import '../difficulty.dart';
import 'memory_symbols.dart';

/// The unit that repeats through a pattern.
///
/// Letters stand for distinct things: `aab` is 🍎🍎🍌 over and over.
enum PatternUnit {
  ab,
  aab,
  abb,
  abc,
  aabb;

  /// Positions of the distinct things inside one repetition.
  List<int> get slots => switch (this) {
        PatternUnit.ab => const [0, 1],
        PatternUnit.aab => const [0, 0, 1],
        PatternUnit.abb => const [0, 1, 1],
        PatternUnit.abc => const [0, 1, 2],
        PatternUnit.aabb => const [0, 0, 1, 1],
      };

  /// How many different things the unit needs.
  int get symbolCount => slots.toSet().length;
}

/// What each rung of [logicLadder] asks for.
class LogicRule {
  const LogicRule({required this.units, required this.isGapAtEnd});

  final List<PatternUnit> units;

  /// Whether the hidden step is the next one (easier) or somewhere inside
  /// the row, which means reading the pattern in both directions.
  final bool isGapAtEnd;
}

const List<LogicRule> logicRules = [
  LogicRule(units: [PatternUnit.ab], isGapAtEnd: true),
  LogicRule(units: [PatternUnit.aab, PatternUnit.abb], isGapAtEnd: true),
  LogicRule(units: [PatternUnit.abc], isGapAtEnd: true),
  LogicRule(
    units: [PatternUnit.ab, PatternUnit.aab, PatternUnit.abb],
    isGapAtEnd: false,
  ),
  LogicRule(units: [PatternUnit.abc, PatternUnit.aabb], isGapAtEnd: false),
  LogicRule(
    units: [PatternUnit.abc, PatternUnit.aabb, PatternUnit.abb],
    isGapAtEnd: false,
  ),
];

LogicRule logicRuleFor(int rung) =>
    logicRules[rung.clamp(0, logicRules.length - 1)];

/// Shortest row a pattern is shown in. Two full repetitions plus a bit, so
/// the repeat is visible before the gap.
const int _minLength = 6;

class LogicQuestion {
  const LogicQuestion({
    required this.unit,
    required this.sequence,
    required this.gapIndex,
    required this.options,
  });

  final PatternUnit unit;

  /// The whole row, gap included: [sequence] at [gapIndex] is the answer.
  final List<String> sequence;

  final int gapIndex;
  final List<String> options;

  String get answer => sequence[gapIndex];

  int get correctIndex => options.indexOf(answer);

  bool get isGapAtEnd => gapIndex == sequence.length - 1;
}

/// Builds a round of [questionsPerRound] patterns for [rung].
///
/// [random] is injected so a round can be reproduced in tests.
List<LogicQuestion> buildLogicRound({
  required int rung,
  required Random random,
  int questionCount = questionsPerRound,
}) {
  final safeRung = rung.clamp(0, logicLadder.length - 1);
  final rule = logicRuleFor(safeRung);
  final optionCount = logicLadder[safeRung].cards;

  return [
    for (var i = 0; i < questionCount; i++)
      _buildQuestion(rule: rule, optionCount: optionCount, random: random),
  ];
}

LogicQuestion _buildQuestion({
  required LogicRule rule,
  required int optionCount,
  required Random random,
}) {
  final unit = rule.units[random.nextInt(rule.units.length)];

  // One face per look-alike group: a pattern of 🍎 and 🍓 would be a test of
  // eyesight rather than of the pattern.
  // Enough faces for the pattern itself and for the wrong choices.
  final faces = dealPairSymbols(
    pairCount: unit.symbolCount + optionCount - 1,
    random: random,
  );

  final patternFaces = faces.take(unit.symbolCount).toList();
  final outsiders = faces.skip(unit.symbolCount).toList();

  // Whole repetitions only, so the row always ends a unit cleanly.
  final repeats = (_minLength / unit.slots.length).ceil();
  final sequence = <String>[
    for (var i = 0; i < repeats; i++)
      for (final slot in unit.slots) patternFaces[slot],
  ];

  final gapIndex = rule.isGapAtEnd
      ? sequence.length - 1
      // Never in the first repetition: the child has to see the unit first.
      : unit.slots.length +
          random.nextInt(sequence.length - unit.slots.length - 1);

  // The answer, the pattern's other faces, then strangers: a child cannot
  // get there by picking "the one that is in the row" or "the one that is
  // not".
  final options = <String>{
    sequence[gapIndex],
    ...patternFaces,
    ...outsiders,
  }.take(optionCount).toList()
    ..shuffle(random);

  return LogicQuestion(
    unit: unit,
    sequence: sequence,
    gapIndex: gapIndex,
    options: options,
  );
}
