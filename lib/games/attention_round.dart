import 'dart:math';

import '../difficulty.dart';
import 'memory_symbols.dart';

/// What makes a board hard on each rung of [attentionLadder].
///
/// Declaration order is rung order.
class AttentionRule {
  const AttentionRule({
    required this.isTargetFromSameGroup,
    required this.hasMixedDistractors,
  });

  /// The odd one out comes from the same look-alike group as the rest
  /// (🍓 among 🍎), instead of an obviously different one (⚽ among 🍎).
  final bool isTargetFromSameGroup;

  /// The rest of the board is two or three faces instead of one, so there is
  /// no single "everything else" to compare against at a glance.
  final bool hasMixedDistractors;
}

const List<AttentionRule> attentionRules = [
  AttentionRule(isTargetFromSameGroup: false, hasMixedDistractors: false),
  AttentionRule(isTargetFromSameGroup: false, hasMixedDistractors: false),
  AttentionRule(isTargetFromSameGroup: true, hasMixedDistractors: false),
  AttentionRule(isTargetFromSameGroup: false, hasMixedDistractors: true),
  AttentionRule(isTargetFromSameGroup: true, hasMixedDistractors: true),
  AttentionRule(isTargetFromSameGroup: true, hasMixedDistractors: true),
];

AttentionRule attentionRuleFor(int rung) =>
    attentionRules[rung.clamp(0, attentionRules.length - 1)];

/// One board: what every box shows, and which one is the odd one out.
class AttentionBoard {
  const AttentionBoard({required this.items, required this.differentIndex});

  final List<String> items;
  final int differentIndex;

  String get target => items[differentIndex];
}

/// Builds a round of [questionsPerRound] boards for [rung].
///
/// [random] is injected so a round can be reproduced in tests.
List<AttentionBoard> buildAttentionRound({
  required int rung,
  required Random random,
  int boardCount = questionsPerRound,
}) {
  final safeRung = rung.clamp(0, attentionLadder.length - 1);

  return [
    for (var i = 0; i < boardCount; i++)
      _buildBoard(
        rule: attentionRuleFor(safeRung),
        boxCount: attentionLadder[safeRung].cards,
        random: random,
      ),
  ];
}

AttentionBoard _buildBoard({
  required AttentionRule rule,
  required int boxCount,
  required Random random,
}) {
  // The group the board is filled from. A same-group target needs one face
  // to spare, and mixed distractors need two.
  final needed =
      (rule.hasMixedDistractors ? 2 : 1) + (rule.isTargetFromSameGroup ? 1 : 0);

  final groupIndexes = [
    for (var i = 0; i < symbolClusters.length; i++)
      if (symbolClusters[i].length >= needed) i,
  ];

  final groupIndex = groupIndexes[random.nextInt(groupIndexes.length)];
  final group = [...symbolClusters[groupIndex]]..shuffle(random);

  // A same-group target has to come out of the same group, so it keeps one
  // face for itself.
  final faceBudget =
      rule.isTargetFromSameGroup ? group.length - 1 : group.length;

  final distractorCount = rule.hasMixedDistractors
      ? min(2 + random.nextInt(2), faceBudget)
      : 1;

  final distractors = group.take(distractorCount).toList();

  final String target;
  if (rule.isTargetFromSameGroup) {
    target = group[distractors.length];
  } else {
    final otherIndexes = [
      for (var i = 0; i < symbolClusters.length; i++)
        if (i != groupIndex) i,
    ];
    final other =
        symbolClusters[otherIndexes[random.nextInt(otherIndexes.length)]];
    target = other[random.nextInt(other.length)];
  }

  // Every distractor face shows up at least twice: a face seen once would be
  // a second odd one out, and the board would have two right answers to a
  // child's eye.
  final items = <String>[
    ...distractors,
    ...distractors,
    for (var i = distractors.length * 2; i < boxCount - 1; i++)
      distractors[random.nextInt(distractors.length)],
  ]..shuffle(random);

  final differentIndex = random.nextInt(boxCount);
  items.insert(differentIndex, target);

  return AttentionBoard(items: items, differentIndex: differentIndex);
}
