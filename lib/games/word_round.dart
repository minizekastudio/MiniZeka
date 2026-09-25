import 'dart:math';

import '../difficulty.dart';

/// A word the child can see a picture of.
class WordItem {
  const WordItem({required this.word, required this.emoji});

  /// Already upper case, and spelled properly.
  ///
  /// They used to be stored without Turkish letters — KEDI, CICEK, GUNES —
  /// and built by `toUpperCase()`, which turns "i" into "I" rather than "İ".
  /// A game that teaches spelling cannot teach it wrong.
  final String word;

  final String emoji;
}

/// Words a four year old can recognise from the picture alone.
const List<WordItem> wordPool = [
  // 2-3 harf
  WordItem(word: 'EV', emoji: '🏠'),
  WordItem(word: 'AY', emoji: '🌙'),
  WordItem(word: 'EL', emoji: '✋'),
  WordItem(word: 'KUŞ', emoji: '🐦'),
  WordItem(word: 'ARI', emoji: '🐝'),
  WordItem(word: 'TOP', emoji: '⚽'),
  WordItem(word: 'GÜL', emoji: '🌹'),
  WordItem(word: 'SÜT', emoji: '🥛'),
  WordItem(word: 'BAL', emoji: '🍯'),
  WordItem(word: 'AYI', emoji: '🐻'),
  WordItem(word: 'GÖZ', emoji: '👁️'),
  WordItem(word: 'MUZ', emoji: '🍌'),

  // 4 harf
  WordItem(word: 'KEDİ', emoji: '🐱'),
  WordItem(word: 'ELMA', emoji: '🍎'),
  WordItem(word: 'MASA', emoji: '🪑'),
  WordItem(word: 'KUZU', emoji: '🐑'),
  WordItem(word: 'ATEŞ', emoji: '🔥'),
  WordItem(word: 'KAPI', emoji: '🚪'),
  WordItem(word: 'SAAT', emoji: '⌚'),
  WordItem(word: 'TREN', emoji: '🚆'),
  WordItem(word: 'AĞAÇ', emoji: '🌳'),
  WordItem(word: 'KALP', emoji: '❤️'),

  // 5 harf
  WordItem(word: 'KALEM', emoji: '✏️'),
  WordItem(word: 'KİTAP', emoji: '📕'),
  WordItem(word: 'BALIK', emoji: '🐟'),
  WordItem(word: 'ÇİÇEK', emoji: '🌸'),
  WordItem(word: 'ARABA', emoji: '🚗'),
  WordItem(word: 'GÜNEŞ', emoji: '☀️'),
  WordItem(word: 'ÖRDEK', emoji: '🦆'),
  WordItem(word: 'BALON', emoji: '🎈'),
  WordItem(word: 'ARMUT', emoji: '🍐'),
  WordItem(word: 'LİMON', emoji: '🍋'),
  WordItem(word: 'BULUT', emoji: '☁️'),

  // 6-7 harf
  WordItem(word: 'YILDIZ', emoji: '⭐'),
  WordItem(word: 'KARPUZ', emoji: '🍉'),
  WordItem(word: 'TAVŞAN', emoji: '🐰'),
  WordItem(word: 'BALİNA', emoji: '🐳'),
  WordItem(word: 'ZÜRAFA', emoji: '🦒'),
  WordItem(word: 'TİMSAH', emoji: '🐊'),
  WordItem(word: 'KAPLAN', emoji: '🐅'),
  WordItem(word: 'KELEBEK', emoji: '🦋'),
  WordItem(word: 'ŞEMSİYE', emoji: '☂️'),
  WordItem(word: 'PENGUEN', emoji: '🐧'),
  WordItem(word: 'DOMATES', emoji: '🍅'),
  WordItem(word: 'ANAHTAR', emoji: '🔑'),
  WordItem(word: 'DİNOZOR', emoji: '🦕'),
  WordItem(word: 'MAKARNA', emoji: '🍝'),
  WordItem(word: 'OTOBÜS', emoji: '🚌'),
  WordItem(word: 'TELEFON', emoji: '📞'),

  // 8+ harf
  WordItem(word: 'DONDURMA', emoji: '🍦'),
  WordItem(word: 'GÖKKUŞAĞI', emoji: '🌈'),
  WordItem(word: 'KAPLUMBAĞA', emoji: '🐢'),
  WordItem(word: 'HELİKOPTER', emoji: '🚁'),
  WordItem(word: 'BİSİKLET', emoji: '🚲'),
  WordItem(word: 'PORTAKAL', emoji: '🍊'),
  WordItem(word: 'ÇİKOLATA', emoji: '🍫'),
  WordItem(word: 'PATLICAN', emoji: '🍆'),
  WordItem(word: 'MİKROFON', emoji: '🎤'),
  WordItem(word: 'AYÇİÇEĞİ', emoji: '🌻'),
  WordItem(word: 'BİLGİSAYAR', emoji: '💻'),
];

/// What each rung of [wordLadder] asks for.
class WordRule {
  const WordRule({
    required this.minLength,
    required this.maxLength,
    required this.tiles,
  });

  final int minLength;
  final int maxLength;

  /// How many letter tiles are laid out, however long the word is.
  ///
  /// Spare letters fill the gap, so the tiles are not simply "everything you
  /// see, in some order". A fixed count is also what keeps the board tidy:
  /// the tile half of a 320 px phone is about 178 px tall, which is two rows
  /// of 64 px targets and no more. Only 4, 6 and 8 tiles fill every row of
  /// such a grid and stay above 64 px; ten would be five columns of 50 px,
  /// twelve would need a third row of 54 px — both too small for a four year
  /// old's finger.
  final int tiles;

  /// Spare letters mixed in beside the word's own.
  int extraLettersFor(String word) => max(0, tiles - word.length);
}

/// Naming the letter a picture starts with belongs to the letter game; this
/// one only builds words, so its first rung is the shortest of them.
const List<WordRule> wordRules = [
  WordRule(minLength: 2, maxLength: 3, tiles: 4),
  WordRule(minLength: 4, maxLength: 4, tiles: 4),
  WordRule(minLength: 5, maxLength: 5, tiles: 6),
  WordRule(minLength: 6, maxLength: 6, tiles: 8),
  WordRule(minLength: 7, maxLength: 7, tiles: 8),
  // The last rung drops the spare letters and spells the longest word that
  // still fits eight tiles.
  WordRule(minLength: 8, maxLength: 8, tiles: 8),
];

WordRule wordRuleFor(int rung) =>
    wordRules[rung.clamp(0, wordRules.length - 1)];

/// Letters that can join the tiles without looking out of place.
const List<String> _spareLetters = [
  'A', 'E', 'İ', 'I', 'O', 'Ö', 'U', 'Ü', //
  'K', 'L', 'M', 'N', 'R', 'S', 'T', 'Y',
];

class WordQuestion {
  const WordQuestion({required this.item, required this.letters});

  final WordItem item;

  /// The tiles, in the order they are laid out.
  final List<String> letters;

  String get word => item.word;

  /// Letters of the word, in order.
  List<String> get spelling => word.split('');

  String get answer => word;
}

/// Builds a round of [questionsPerRound] words for [rung].
///
/// [random] is injected so a round can be reproduced in tests.
List<WordQuestion> buildWordRound({
  required int rung,
  required Random random,
  int questionCount = questionsPerRound,
}) {
  final rule = wordRuleFor(rung.clamp(0, wordLadder.length - 1));

  final choices = [
    for (final item in wordPool)
      if (item.word.length >= rule.minLength &&
          item.word.length <= rule.maxLength)
        item,
  ]..shuffle(random);

  final questions = <WordQuestion>[];

  for (var i = 0; i < questionCount; i++) {
    // The pool per rung is bigger than a round, so a round never repeats a
    // word; the modulo is only a guard.
    final item = choices[i % choices.length];

    questions.add(
      WordQuestion(item: item, letters: _tilesFor(item, rule, random)),
    );
  }

  return questions;
}

List<String> _tilesFor(WordItem item, WordRule rule, Random random) {
  final letters = item.word.split('');

  final spares = [
    for (final letter in _spareLetters)
      if (!letters.contains(letter)) letter,
  ]..shuffle(random);

  final tiles = [...letters, ...spares.take(rule.extraLettersFor(item.word))];

  // Laid out in some order other than the answer itself.
  do {
    tiles.shuffle(random);
  } while (tiles.length > 1 && tiles.join() == item.word);

  return tiles;
}
