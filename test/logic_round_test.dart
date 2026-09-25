import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/games/logic_round.dart';
import 'package:mini_zeka/games/memory_symbols.dart';

const _seeds = 300;

Iterable<LogicQuestion> _questions(int rung) sync* {
  for (var seed = 0; seed < _seeds; seed++) {
    yield* buildLogicRound(rung: rung, random: Random(seed));
  }
}

int _groupOf(String symbol) =>
    symbolClusters.indexWhere((group) => group.contains(symbol));

void main() {
  test('her bölümün bir kuralı var', () {
    expect(logicRules, hasLength(logicLadder.length));
  });

  group('her bölümde, her soruda', () {
    for (var rung = 0; rung < logicLadder.length; rung++) {
      final rule = logicRuleFor(rung);

      test('bölüm ${rung + 1}: dizi gerçekten örüntü, boşluk kuralı tutuyor',
          () {
        for (final q in _questions(rung)) {
          expect(rule.units, contains(q.unit));

          // Every position matches the repeating unit.
          final unitLength = q.unit.slots.length;
          expect(q.sequence.length % unitLength, 0);

          // The row repeats with the unit's length, all the way through.
          for (var i = unitLength; i < q.sequence.length; i++) {
            expect(q.sequence[i], q.sequence[i - unitLength],
                reason: '${q.sequence}');
          }

          // And the unit really has the shape its name says.
          final firstUnit = q.sequence.take(unitLength).toList();
          for (var i = 0; i < unitLength; i++) {
            for (var j = 0; j < unitLength; j++) {
              expect(firstUnit[i] == firstUnit[j],
                  q.unit.slots[i] == q.unit.slots[j],
                  reason: '${q.unit.name}: $firstUnit');
            }
          }

          expect(q.isGapAtEnd, rule.isGapAtEnd);
          if (!rule.isGapAtEnd) {
            expect(q.gapIndex, greaterThanOrEqualTo(unitLength),
                reason: 'ilk tekrar görünmeli');
            expect(q.gapIndex, lessThan(q.sequence.length - 1));
          }
        }
      });

      test('bölüm ${rung + 1}: dört farklı şık, biri doğru', () {
        for (final q in _questions(rung)) {
          expect(q.options, hasLength(logicLadder[rung].cards));
          expect(q.options.toSet(), hasLength(q.options.length));
          expect(q.options, contains(q.answer));
          expect(q.correctIndex, isNot(-1));
        }
      });

      test('bölüm ${rung + 1}: şıklar kestirme vermiyor', () {
        for (final q in _questions(rung)) {
          final inPattern =
              q.options.where(q.sequence.contains).toSet();
          final outside =
              q.options.where((o) => !q.sequence.contains(o)).toSet();

          expect(inPattern.length, greaterThan(1),
              reason: '"dizide geçen" tek şık cevap olmamalı: ${q.options}');
          expect(outside, isNotEmpty, reason: '${q.options}');
        }
      });

      test('bölüm ${rung + 1}: örüntü yüzleri birbirine benzemiyor', () {
        for (final q in _questions(rung)) {
          final groups = q.sequence.toSet().map(_groupOf).toList();

          expect(groups.toSet(), hasLength(groups.length),
              reason: '${q.sequence}');
        }
      });

      test('bölüm ${rung + 1}: doğru şık her konuma düşebiliyor', () {
        final positions = {for (final q in _questions(rung)) q.correctIndex};

        expect(positions, hasLength(logicLadder[rung].cards));
      });
    }
  });

  test('merdiven uzayan birimden gizli boşluğa gider', () {
    expect(logicRules.first.units, [PatternUnit.ab]);
    expect(logicRules.first.isGapAtEnd, isTrue);
    expect(logicRules.last.isGapAtEnd, isFalse);

    // Once the gap moves inside, it stays inside.
    var gapMoved = false;
    for (final rule in logicRules) {
      if (!rule.isGapAtEnd) gapMoved = true;
      if (gapMoved) expect(rule.isGapAtEnd, isFalse);
    }
  });

  test('aynı tohum aynı turu üretir', () {
    for (var rung = 0; rung < logicLadder.length; rung++) {
      final a = buildLogicRound(rung: rung, random: Random(8));
      final b = buildLogicRound(rung: rung, random: Random(8));

      for (var i = 0; i < a.length; i++) {
        expect(a[i].sequence, b[i].sequence);
        expect(a[i].options, b[i].options);
        expect(a[i].gapIndex, b[i].gapIndex);
      }
    }
  });
}
