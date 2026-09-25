import 'dart:math';

import '../difficulty.dart';
import 'word_round.dart';

/// The Turkish alphabet, in order.
const List<String> turkishAlphabet = [
  'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H', //
  'I', 'İ', 'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P',
  'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z',
];

/// Lower case forms, written out rather than computed.
///
/// `toLowerCase()` is wrong for Turkish in both directions: it turns "I" into
/// "i" when the Turkish lower case is "ı", and "İ" into an "i" followed by a
/// combining dot. A game that teaches letters cannot get their shapes wrong.
const Map<String, String> lowerCaseLetters = {
  'A': 'a', 'B': 'b', 'C': 'c', 'Ç': 'ç', 'D': 'd', //
  'E': 'e', 'F': 'f', 'G': 'g', 'Ğ': 'ğ', 'H': 'h',
  'I': 'ı', 'İ': 'i', 'J': 'j', 'K': 'k', 'L': 'l',
  'M': 'm', 'N': 'n', 'O': 'o', 'Ö': 'ö', 'P': 'p',
  'R': 'r', 'S': 's', 'Ş': 'ş', 'T': 't', 'U': 'u',
  'Ü': 'ü', 'V': 'v', 'Y': 'y', 'Z': 'z',
};

/// Letters a child mixes up, grouped.
///
/// The Turkish pairs that differ only by a dot, a cedilla or a breve are the
/// heart of it — I/İ, O/Ö, U/Ü, S/Ş, C/Ç, G/Ğ — and they survive into lower
/// case. The rest are the shapes that face the same way. A letter belongs to
/// at most one group, so the lookup has one answer.
const List<List<String>> letterConfusions = [
  ['I', 'İ'],
  ['O', 'Ö'],
  ['U', 'Ü'],
  ['S', 'Ş'],
  ['C', 'Ç'],
  ['G', 'Ğ'],
  ['B', 'D', 'P', 'R'],
  ['M', 'N'],
  ['E', 'F'],
  ['V', 'Y'],
  ['H', 'K'],
];

/// The group [letter] belongs to, or null when it has no look-alikes.
List<String>? confusionGroupOf(String letter) {
  for (final group in letterConfusions) {
    if (group.contains(letter)) return group;
  }

  return null;
}

/// Letters with look-alikes, which the harder rungs draw their targets from.
final List<String> confusableLetters = [
  for (final letter in turkishAlphabet)
    if (confusionGroupOf(letter) != null) letter,
];

/// What a question asks for.
enum LetterTask {
  /// Find the same letter again.
  sameLetter,

  /// Find the small form of the letter shown.
  lowerCase,

  /// Which letter does the pictured word start with?
  firstSound,

  /// Which letter comes next in the alphabet?
  alphabetOrder,
}

/// What each rung of [letterLadder] asks for.
class LetterRule {
  const LetterRule({
    required this.task,
    required this.hasLookAlikeChoices,
    this.choices = 4,
  });

  final LetterTask task;

  /// Whether the wrong choices are the letters this one is mixed up with.
  ///
  /// Telling A from M is seeing that two shapes differ; telling O from Ö is
  /// reading the letter. The second is the skill, so it is where the ladder
  /// goes — but not before the child can do the first.
  final bool hasLookAlikeChoices;

  final int choices;
}

const List<LetterRule> letterRules = [
  LetterRule(task: LetterTask.sameLetter, hasLookAlikeChoices: false),
  LetterRule(task: LetterTask.sameLetter, hasLookAlikeChoices: true),
  LetterRule(task: LetterTask.lowerCase, hasLookAlikeChoices: false),
  LetterRule(task: LetterTask.lowerCase, hasLookAlikeChoices: true),
  LetterRule(task: LetterTask.firstSound, hasLookAlikeChoices: true),
  LetterRule(task: LetterTask.alphabetOrder, hasLookAlikeChoices: false),
];

LetterRule letterRuleFor(int rung) =>
    letterRules[rung.clamp(0, letterRules.length - 1)];

class LetterQuestion {
  const LetterQuestion({
    required this.task,
    required this.letter,
    required this.choices,
    required this.answer,
    this.item,
    this.sequence = const [],
  });

  final LetterTask task;

  /// The upper case letter the question is about.
  final String letter;

  /// The four tiles, in the order they are laid out.
  final List<String> choices;

  /// Which of [choices] is right.
  final String answer;

  /// The picture, for [LetterTask.firstSound].
  final WordItem? item;

  /// The row shown for [LetterTask.alphabetOrder], with '' for the gap.
  final List<String> sequence;
}

/// Builds a round of [questionsPerRound] questions for [rung].
///
/// [random] is injected so a round can be reproduced in tests.
List<LetterQuestion> buildLetterRound({
  required int rung,
  required Random random,
  int questionCount = questionsPerRound,
}) {
  final rule = letterRuleFor(rung.clamp(0, letterLadder.length - 1));

  final questions = <LetterQuestion>[];
  final asked = <String>{};

  while (questions.length < questionCount) {
    final question = _buildQuestion(rule, random);

    // A round never asks about the same letter twice.
    if (!asked.add(question.letter)) continue;

    questions.add(question);
  }

  return questions;
}

LetterQuestion _buildQuestion(LetterRule rule, Random random) {
  return switch (rule.task) {
    LetterTask.sameLetter => _buildMatch(rule, random, isLowerCase: false),
    LetterTask.lowerCase => _buildMatch(rule, random, isLowerCase: true),
    LetterTask.firstSound => _buildFirstSound(rule, random),
    LetterTask.alphabetOrder => _buildAlphabetOrder(rule, random),
  };
}

/// "Here is a letter — find it again", in the same case or the small one.
LetterQuestion _buildMatch(
  LetterRule rule,
  Random random, {
  required bool isLowerCase,
}) {
  final letter = _pickTarget(rule, random);

  String shown(String upper) => isLowerCase ? lowerCaseLetters[upper]! : upper;

  final answer = shown(letter);

  return LetterQuestion(
    task: isLowerCase ? LetterTask.lowerCase : LetterTask.sameLetter,
    letter: letter,
    answer: answer,
    choices: [answer, ..._distractors(rule, letter, random).map(shown)]
      ..shuffle(random),
  );
}

/// "What does this picture start with?"
LetterQuestion _buildFirstSound(LetterRule rule, Random random) {
  // Only words whose first letter has look-alikes can carry the harder
  // rung, so the choices are a real question rather than four odd shapes.
  final candidates = [
    for (final item in wordPool)
      if (!rule.hasLookAlikeChoices ||
          confusionGroupOf(item.word.split('').first) != null)
        item,
  ];

  final item = candidates[random.nextInt(candidates.length)];
  final letter = item.word.split('').first;

  return LetterQuestion(
    task: LetterTask.firstSound,
    letter: letter,
    item: item,
    answer: letter,
    choices: [letter, ..._distractors(rule, letter, random)]..shuffle(random),
  );
}

/// "A B ? D" — which letter fills the gap?
LetterQuestion _buildAlphabetOrder(LetterRule rule, Random random) {
  const length = 4;

  final start = random.nextInt(turkishAlphabet.length - length + 1);
  final run = turkishAlphabet.sublist(start, start + length);

  // The gap is never first: the child has to see the run before it counts.
  final gap = 1 + random.nextInt(length - 1);
  final letter = run[gap];

  // Neighbours make the wrong choices, so "pick the one you have not seen"
  // does not answer the question. They are taken by distance rather than a
  // fixed window: at the end of the alphabet a window runs out of letters.
  final neighbours =
      [
        for (final other in turkishAlphabet)
          if (!run.contains(other)) other,
      ]..sort((a, b) {
        int distance(String letter) =>
            (turkishAlphabet.indexOf(letter) - (start + gap)).abs();

        return distance(a).compareTo(distance(b));
      });

  final nearest = neighbours.take(rule.choices + 1).toList()..shuffle(random);

  return LetterQuestion(
    task: LetterTask.alphabetOrder,
    letter: letter,
    answer: letter,
    sequence: [
      for (var i = 0; i < length; i++)
        if (i == gap) '' else run[i],
    ],
    choices: [letter, ...nearest.take(rule.choices - 1)]..shuffle(random),
  );
}

String _pickTarget(LetterRule rule, Random random) {
  final pool = rule.hasLookAlikeChoices ? confusableLetters : turkishAlphabet;

  return pool[random.nextInt(pool.length)];
}

/// The wrong choices: look-alikes on the harder rungs, anything else below.
List<String> _distractors(LetterRule rule, String letter, Random random) {
  final wanted = rule.choices - 1;
  final group = confusionGroupOf(letter);

  final lookAlikes = [
    if (rule.hasLookAlikeChoices && group != null)
      for (final other in group)
        if (other != letter) other,
  ]..shuffle(random);

  // Away from the look-alikes, anything but the answer and its group: a
  // letter that merely resembles it would make the easy rung the hard one.
  final rest = [
    for (final other in turkishAlphabet)
      if (other != letter && !lookAlikes.contains(other))
        if (rule.hasLookAlikeChoices || group == null || !group.contains(other))
          other,
  ]..shuffle(random);

  return [...lookAlikes, ...rest].take(wanted).toList();
}
