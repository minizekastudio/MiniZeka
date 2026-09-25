import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/games/word_round.dart';

const _seeds = 200;

Iterable<WordQuestion> _questions(int rung) sync* {
  for (var seed = 0; seed < _seeds; seed++) {
    yield* buildWordRound(rung: rung, random: Random(seed));
  }
}

/// Counts each letter, so tiles can be compared with a word.
Map<String, int> _letterCounts(Iterable<String> letters) {
  final counts = <String, int>{};
  for (final letter in letters) {
    counts[letter] = (counts[letter] ?? 0) + 1;
  }
  return counts;
}

void main() {
  group('kelime havuzu', () {
    test('kelimeler doğru Türkçe yazılmış', () {
      // The pool used to be stripped to ASCII: KEDI, CICEK, GUNES.
      for (final ascii in ['KEDI', 'CICEK', 'GUNES', 'KITAP', 'KUS', 'FIL']) {
        expect(
          wordPool.map((w) => w.word),
          isNot(contains(ascii)),
          reason: '$ascii yanlış yazım',
        );
      }

      for (final correct in ['KEDİ', 'ÇİÇEK', 'GÜNEŞ', 'KİTAP', 'KUŞ']) {
        expect(wordPool.map((w) => w.word), contains(correct));
      }
    });

    test('hepsi büyük harf ve resimli', () {
      for (final item in wordPool) {
        expect(item.word, isNotEmpty);
        expect(item.emoji, isNotEmpty);
        expect(
          item.word,
          isNot(matches(RegExp('[a-zçğıöşü]'))),
          reason: '${item.word} küçük harf içeriyor',
        );
      }
    });

    test('aynı kelime iki kez yok', () {
      final words = wordPool.map((w) => w.word).toList();

      expect(words.toSet(), hasLength(words.length));
    });

    test('her bölümün bir tur dolduracak kadar kelimesi var', () {
      for (var rung = 0; rung < wordLadder.length; rung++) {
        final rule = wordRuleFor(rung);
        final fitting = wordPool.where(
          (item) =>
              item.word.length >= rule.minLength &&
              item.word.length <= rule.maxLength,
        );

        expect(
          fitting.length,
          greaterThanOrEqualTo(questionsPerRound),
          reason: 'bölüm ${rung + 1}: ${fitting.length} kelime',
        );
      }
    });
  });

  group('her bölümde, her soruda', () {
    for (var rung = 0; rung < wordLadder.length; rung++) {
      final rule = wordRuleFor(rung);

      test('bölüm ${rung + 1}: kelime uzunluğu kuralın içinde', () {
        for (final q in _questions(rung)) {
          expect(q.task, rule.task);
          expect(q.word.length, greaterThanOrEqualTo(rule.minLength));
          expect(q.word.length, lessThanOrEqualTo(rule.maxLength));
        }
      });

      test('bölüm ${rung + 1}: bir turda aynı kelime iki kez sorulmaz', () {
        for (var seed = 0; seed < _seeds; seed++) {
          final round = buildWordRound(rung: rung, random: Random(seed));

          expect(round, hasLength(questionsPerRound));
          expect(round.map((q) => q.word).toSet(), hasLength(round.length));
        }
      });
    }
  });

  test('ilk bölüm: dört harf şıkkı, biri kelimenin ilk harfi', () {
    for (final q in _questions(0)) {
      expect(q.task, WordTask.firstLetter);
      expect(q.letters, hasLength(wordRules.first.tiles));
      expect(q.letters.toSet(), hasLength(4));
      expect(q.letters, contains(q.spelling.first));
      expect(q.answer, q.spelling.first);
    }
  });

  test('harf dizme bölümlerinde taşlar kelimeyi kurmaya yeter', () {
    for (var rung = 1; rung < wordLadder.length; rung++) {
      final rule = wordRuleFor(rung);

      for (final q in _questions(rung)) {
        expect(q.task, WordTask.spell);
        expect(q.letters, hasLength(rule.tiles));
        expect(q.word.length, lessThanOrEqualTo(rule.tiles));

        final tiles = _letterCounts(q.letters);
        _letterCounts(q.spelling).forEach((letter, needed) {
          expect(
            tiles[letter] ?? 0,
            greaterThanOrEqualTo(needed),
            reason: '${q.word}: ${q.letters}',
          );
        });

        expect(q.letters.join(), isNot(q.word), reason: 'hazır dizilmesin');
      }
    }
  });

  test('taş sayısı yukarı bölümlerde artar ve hep ızgaraya oturur', () {
    // Only these counts fill every row of the grid and still leave a 64 px
    // tile on a 320 px phone; ten tiles, say, would be five 50 px columns,
    // and twelve would need a third row of 54 px.
    const tidyCounts = [4, 6, 8];

    for (var i = 0; i < wordRules.length; i++) {
      expect(
        tidyCounts,
        contains(wordRules[i].tiles),
        reason: 'bölüm ${i + 1}: ${wordRules[i].tiles} taş',
      );

      if (i > 0) {
        expect(
          wordRules[i].tiles,
          greaterThanOrEqualTo(wordRules[i - 1].tiles),
        );
      }
    }

    expect(wordRules.last.tiles, greaterThan(wordRules[1].tiles));
  });

  test('her bölümde taşların bir kısmı fazladan harf olabilir', () {
    // The tiles are a fixed count, so a short word gets spare letters mixed
    // in and the board never gives the answer away by its width.
    expect(wordRules[1].extraLettersFor('EV'), 2);
    expect(wordRules[2].extraLettersFor('KEDİ'), 0);
    expect(wordRules[4].extraLettersFor('KARPUZ'), 2);
    expect(wordRules.last.extraLettersFor('DONDURMA'), 0);
  });

  test('aynı tohum aynı turu üretir', () {
    for (var rung = 0; rung < wordLadder.length; rung++) {
      final a = buildWordRound(rung: rung, random: Random(3));
      final b = buildWordRound(rung: rung, random: Random(3));

      for (var i = 0; i < a.length; i++) {
        expect(a[i].word, b[i].word);
        expect(a[i].letters, b[i].letters);
      }
    }
  });
}
