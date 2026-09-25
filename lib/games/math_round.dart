import 'dart:math';

import '../difficulty.dart';

/// What a question asks the child to do.
enum MathTask {
  /// How many things are there?
  count,

  /// How many are there altogether?
  add,

  /// How many are left?
  subtract,
}

/// What each rung of [mathLadder] asks for.
///
/// Declaration order is rung order: counting first, then adding within five,
/// then within ten, then taking away, and only after that the same sums
/// without anything to count.
class MathRule {
  const MathRule({
    required this.task,
    required this.largest,
    required this.hasObjects,
  });

  final MathTask task;

  /// Biggest number a question may reach, answer included.
  final int largest;

  /// Whether the question also shows things to count. The bridge from
  /// counting to symbols: the digits are always there, the objects are not.
  final bool hasObjects;
}

const List<MathRule> mathRules = [
  MathRule(task: MathTask.count, largest: 5, hasObjects: true),
  MathRule(task: MathTask.add, largest: 5, hasObjects: true),
  MathRule(task: MathTask.add, largest: 10, hasObjects: true),
  MathRule(task: MathTask.subtract, largest: 10, hasObjects: true),
  MathRule(task: MathTask.add, largest: 20, hasObjects: false),
  MathRule(task: MathTask.subtract, largest: 20, hasObjects: false),
];

MathRule mathRuleFor(int rung) =>
    mathRules[rung.clamp(0, mathRules.length - 1)];

/// Things to count. One kind per question: counting a mixed pile is a
/// different, harder task.
const List<String> mathObjects = [
  '🍎',
  '🍓',
  '🐟',
  '🎈',
  '⚽',
  '🌻',
  '🚗',
  '🐥',
];

class MathQuestion {
  const MathQuestion({
    required this.task,
    required this.left,
    required this.right,
    required this.options,
    required this.hasObjects,
    required this.object,
  });

  final MathTask task;

  /// The only number for [MathTask.count], otherwise the first one.
  final int left;

  /// The second number; 0 when counting.
  final int right;

  final List<int> options;
  final bool hasObjects;

  /// Which thing is drawn, when the question shows things.
  final String object;

  int get answer => switch (task) {
        MathTask.count => left,
        MathTask.add => left + right,
        MathTask.subtract => left - right,
      };

  int get correctIndex => options.indexOf(answer);

  /// Identifies the question, so a round does not ask it twice.
  String get key => '${task.name}:$left:$right';
}

/// Builds a round of [questionsPerRound] questions for [rung].
///
/// [random] is injected so a round can be reproduced in tests.
List<MathQuestion> buildMathRound({
  required int rung,
  required Random random,
  int questionCount = questionsPerRound,
}) {
  final rule = mathRuleFor(rung.clamp(0, mathLadder.length - 1));
  final optionCount = mathLadder[rung.clamp(0, mathLadder.length - 1)].cards;

  final questions = <MathQuestion>[];
  final asked = <String>{};

  // Small ranges hold few distinct questions, so stop hunting after a while
  // rather than spinning: a repeat is better than a frozen screen.
  var attempts = 0;

  while (questions.length < questionCount) {
    final question = _buildQuestion(
      rule: rule,
      optionCount: optionCount,
      random: random,
    );

    attempts++;

    if (asked.add(question.key) || attempts > questionCount * 20) {
      questions.add(question);
    }
  }

  return questions;
}

MathQuestion _buildQuestion({
  required MathRule rule,
  required int optionCount,
  required Random random,
}) {
  final int left;
  final int right;

  switch (rule.task) {
    case MathTask.count:
      left = 1 + random.nextInt(rule.largest);
      right = 0;

    case MathTask.add:
      // Both sides at least one, and the total within the rung's range.
      left = 1 + random.nextInt(rule.largest - 1);
      right = 1 + random.nextInt(rule.largest - left);

    case MathTask.subtract:
      // Never below zero, and something is always taken away.
      left = 2 + random.nextInt(rule.largest - 1);
      right = 1 + random.nextInt(left - 1);
  }

  final answer = switch (rule.task) {
    MathTask.count => left,
    MathTask.add => left + right,
    MathTask.subtract => left - right,
  };

  return MathQuestion(
    task: rule.task,
    left: left,
    right: right,
    options: _buildOptions(
      answer: answer,
      count: optionCount,
      random: random,
    ),
    hasObjects: rule.hasObjects,
    object: mathObjects[random.nextInt(mathObjects.length)],
  );
}

/// Four choices around [answer].
///
/// They used to be exactly the answer plus 1, minus 1 and plus 2 every time,
/// which made the shape of the board a hint of its own.
List<int> _buildOptions({
  required int answer,
  required int count,
  required Random random,
}) {
  final candidates = <int>[
    for (final step in [-3, -2, -1, 1, 2, 3])
      if (answer + step >= 0) answer + step,
  ]..shuffle(random);

  final options = <int>{answer};

  for (final candidate in candidates) {
    if (options.length == count) break;
    options.add(candidate);
  }

  // Tiny answers can run out of neighbours below zero.
  var above = answer + 4;
  while (options.length < count) {
    options.add(above++);
  }

  return options.toList()..shuffle(random);
}
