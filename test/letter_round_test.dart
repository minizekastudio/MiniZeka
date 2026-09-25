import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/games/letter_round.dart';
import 'package:mini_zeka/games/word_round.dart';

const _seeds = 200;

Iterable<LetterQuestion> _questions(int rung) sync* {
  for (var seed = 0; seed < _seeds; seed++) {
    yield* buildLetterRound(rung: rung, random: Random(seed));
  }
}

void main() {
  group('alfabe', () {
    test('yirmi dokuz harf, sırasıyla', () {
      expect(turkishAlphabet, hasLength(29));
      expect(turkishAlphabet.toSet(), hasLength(29));

      expect(turkishAlphabet.first, 'A');
      expect(turkishAlphabet.last, 'Z');
      expect(turkishAlphabet[turkishAlphabet.indexOf('I') + 1], 'İ');
      expect(turkishAlphabet[turkishAlphabet.indexOf('O') + 1], 'Ö');
    });

    test('küçük harfler elle yazılmış, çünkü toLowerCase yanlış', () {
      for (final letter in turkishAlphabet) {
        expect(lowerCaseLetters[letter], isNotNull, reason: '$letter eksik');
      }

      expect(lowerCaseLetters['I'], 'ı');
      expect(lowerCaseLetters['İ'], 'i');

      // Dart lower-cases "I" to "i"; Turkish wants "ı". The same mapping
      // upper-cases "i" to "I" instead of "İ" — that is the bug that left
      // KEDI and CICEK in the word pool.
      expect('I'.toLowerCase(), 'i');
      expect('I'.toLowerCase(), isNot(lowerCaseLetters['I']));
      expect('i'.toUpperCase(), 'I');
      expect('i'.toUpperCase(), isNot('İ'));

      expect(lowerCaseLetters.values.toSet(), hasLength(29));
    });

    test('bir harf en fazla bir benzeşme kümesinde', () {
      final seen = <String>{};

      for (final group in letterConfusions) {
        expect(group.length, greaterThanOrEqualTo(2));

        for (final letter in group) {
          expect(turkishAlphabet, contains(letter));
          expect(seen.add(letter), isTrue, reason: '$letter iki kümede');
        }
      }

      // The Turkish pairs that differ by a dot, cedilla or breve must be in.
      for (final pair in [
        ['I', 'İ'],
        ['O', 'Ö'],
        ['U', 'Ü'],
        ['S', 'Ş'],
        ['C', 'Ç'],
        ['G', 'Ğ'],
      ]) {
        expect(confusionGroupOf(pair.first), contains(pair.last));
      }
    });
  });

  group('her bölümde, her soruda', () {
    for (var rung = 0; rung < letterLadder.length; rung++) {
      final rule = letterRuleFor(rung);

      test('bölüm ${rung + 1}: dört ayrı şık, biri doğru', () {
        for (final q in _questions(rung)) {
          expect(q.task, rule.task);
          expect(q.choices, hasLength(rule.choices));
          expect(q.choices.toSet(), hasLength(rule.choices));
          expect(q.choices, contains(q.answer));
        }
      });

      test('bölüm ${rung + 1}: bir turda aynı harf iki kez sorulmaz', () {
        for (var seed = 0; seed < _seeds; seed++) {
          final round = buildLetterRound(rung: rung, random: Random(seed));

          expect(round, hasLength(questionsPerRound));
          expect(round.map((q) => q.letter).toSet(), hasLength(round.length));
        }
      });

      test('bölüm ${rung + 1}: çeldiriciler kurala uyuyor', () {
        // Alphabet order picks its wrong choices by position, not by shape;
        // O and Ö being neighbours there is the point, not a slip.
        if (rule.task == LetterTask.alphabetOrder) return;

        for (final q in _questions(rung)) {
          final group = confusionGroupOf(q.letter);
          if (group == null) continue;

          final wrong = q.choices.where((c) => c != q.answer);

          // Choices are shown in the case the question asks for.
          final lookAlikes = rule.task == LetterTask.lowerCase
              ? group.map((l) => lowerCaseLetters[l]!)
              : group;

          if (rule.hasLookAlikeChoices) {
            expect(
              wrong.any(lookAlikes.contains),
              isTrue,
              reason: '${q.letter}: ${q.choices}',
            );
          } else {
            expect(
              wrong.any(lookAlikes.contains),
              isFalse,
              reason: '${q.letter}: ${q.choices}',
            );
          }
        }
      });
    }
  });

  test('benzeyen çeldiricili bölümlerde hedefin benzeri vardır', () {
    for (var rung = 0; rung < letterLadder.length; rung++) {
      if (!letterRuleFor(rung).hasLookAlikeChoices) continue;

      for (final q in _questions(rung)) {
        expect(confusionGroupOf(q.letter), isNotNull, reason: q.letter);
      }
    }
  });

  test('aynı harfi bul: şıklar büyük harf', () {
    for (final q in _questions(0)) {
      expect(q.answer, q.letter);

      for (final choice in q.choices) {
        expect(turkishAlphabet, contains(choice));
      }
    }
  });

  test('küçük harfi bul: şıklar küçük harf, cevap doğru eşi', () {
    for (final q in _questions(2)) {
      expect(q.answer, lowerCaseLetters[q.letter]);

      for (final choice in q.choices) {
        expect(lowerCaseLetters.values, contains(choice));
        expect(turkishAlphabet, isNot(contains(choice)));
      }
    }
  });

  test('resim hangi harfle başlıyor: resim var, cevap ilk harf', () {
    for (final q in _questions(4)) {
      expect(q.item, isNotNull);
      expect(wordPool, contains(q.item));
      expect(q.answer, q.item!.word.split('').first);
      expect(q.letter, q.answer);
    }
  });

  group('alfabe sırası', () {
    test('satırda tek boşluk var ve başta değil', () {
      for (final q in _questions(5)) {
        expect(q.sequence, hasLength(4));
        expect(q.sequence.where((s) => s.isEmpty), hasLength(1));
        expect(q.sequence.first, isNotEmpty);
      }
    });

    test('satır alfabenin ardışık parçası, cevap boşluğu doldurur', () {
      for (final q in _questions(5)) {
        final filled = [
          for (final slot in q.sequence) slot.isEmpty ? q.answer : slot,
        ];

        final start = turkishAlphabet.indexOf(filled.first);

        expect(
          filled,
          turkishAlphabet.sublist(start, start + filled.length),
          reason: '$filled',
        );
      }
    });

    test('şıkların hiçbiri satırda görünmez', () {
      // Otherwise "pick the one you have not seen" would answer it.
      for (final q in _questions(5)) {
        for (final choice in q.choices) {
          expect(q.sequence, isNot(contains(choice)));
        }
      }
    });
  });

  test('aynı tohum aynı turu üretir', () {
    for (var rung = 0; rung < letterLadder.length; rung++) {
      final a = buildLetterRound(rung: rung, random: Random(5));
      final b = buildLetterRound(rung: rung, random: Random(5));

      for (var i = 0; i < a.length; i++) {
        expect(a[i].letter, b[i].letter);
        expect(a[i].choices, b[i].choices);
        expect(a[i].sequence, b[i].sequence);
      }
    }
  });
}
