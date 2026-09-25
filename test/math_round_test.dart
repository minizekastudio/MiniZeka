import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/games/math_round.dart';

const _seeds = 300;

Iterable<MathQuestion> _questions(int rung) sync* {
  for (var seed = 0; seed < _seeds; seed++) {
    yield* buildMathRound(rung: rung, random: Random(seed));
  }
}

void main() {
  test('her bölümün bir kuralı var', () {
    expect(mathRules, hasLength(mathLadder.length));
  });

  group('her bölümde, her soruda', () {
    for (var rung = 0; rung < mathLadder.length; rung++) {
      final rule = mathRuleFor(rung);

      test('bölüm ${rung + 1}: sayılar aralıkta, cevap doğru', () {
        for (final q in _questions(rung)) {
          expect(q.task, rule.task);
          expect(q.hasObjects, rule.hasObjects);

          expect(q.left, greaterThan(0));
          expect(q.left, lessThanOrEqualTo(rule.largest));
          expect(q.answer, greaterThanOrEqualTo(0));
          expect(q.answer, lessThanOrEqualTo(rule.largest),
              reason: '${q.left} ${q.task.name} ${q.right}');

          switch (q.task) {
            case MathTask.count:
              expect(q.right, 0);
            case MathTask.add:
              expect(q.right, greaterThan(0));
              expect(q.answer, q.left + q.right);
            case MathTask.subtract:
              expect(q.right, greaterThan(0));
              expect(q.right, lessThan(q.left), reason: 'hepsi gitmesin');
              expect(q.answer, q.left - q.right);
          }
        }
      });

      test('bölüm ${rung + 1}: dört farklı şık, biri doğru, hiçbiri eksi', () {
        for (final q in _questions(rung)) {
          expect(q.options, hasLength(mathLadder[rung].cards));
          expect(q.options.toSet(), hasLength(q.options.length));
          expect(q.options, contains(q.answer));
          expect(q.options.every((o) => o >= 0), isTrue, reason: '${q.options}');
          expect(q.correctIndex, isNot(-1));
        }
      });

      test('bölüm ${rung + 1}: doğru şık her konuma düşebiliyor', () {
        final positions = {for (final q in _questions(rung)) q.correctIndex};

        expect(positions, hasLength(mathLadder[rung].cards));
      });

      test('bölüm ${rung + 1}: bir tur içinde aynı soru iki kez sorulmaz', () {
        for (var seed = 0; seed < _seeds; seed++) {
          final round = buildMathRound(rung: rung, random: Random(seed));

          expect(round, hasLength(questionsPerRound));
          expect(round.map((q) => q.key).toSet(), hasLength(round.length),
              reason: '${round.map((q) => q.key).toList()}');
        }
      });
    }
  });

  test('merdiven somuttan soyuta gider: nesneler üst bölümlerde kalkar', () {
    expect(mathRules.first.task, MathTask.count);
    expect(mathRules.first.hasObjects, isTrue);
    expect(mathRules.last.hasObjects, isFalse);

    // Objects never come back once they are gone.
    var objectsGone = false;
    for (final rule in mathRules) {
      if (!rule.hasObjects) objectsGone = true;
      if (objectsGone) expect(rule.hasObjects, isFalse);
    }

    // Numbers never shrink from one rung to the next.
    for (var i = 1; i < mathRules.length; i++) {
      expect(mathRules[i].largest,
          greaterThanOrEqualTo(mathRules[i - 1].largest));
    }
  });

  test('çıkarma yalnızca toplama görüldükten sonra gelir', () {
    final firstSubtract =
        mathRules.indexWhere((r) => r.task == MathTask.subtract);
    final firstAdd = mathRules.indexWhere((r) => r.task == MathTask.add);

    expect(firstAdd, lessThan(firstSubtract));
  });

  test('aynı tohum aynı turu üretir', () {
    for (var rung = 0; rung < mathLadder.length; rung++) {
      final a = buildMathRound(rung: rung, random: Random(4));
      final b = buildMathRound(rung: rung, random: Random(4));

      for (var i = 0; i < a.length; i++) {
        expect(a[i].key, b[i].key);
        expect(a[i].options, b[i].options);
      }
    }
  });
}
