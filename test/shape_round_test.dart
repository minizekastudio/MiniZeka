import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/games/shape_figure.dart';
import 'package:mini_zeka/games/shape_round.dart';

const _seeds = 300;

/// Every question of every round built for [rung] across [_seeds] seeds.
Iterable<ShapeQuestion> _questions(int rung) sync* {
  for (var seed = 0; seed < _seeds; seed++) {
    yield* buildShapeRound(rung: rung, random: Random(seed));
  }
}

List<ShapeFigure> _wrong(ShapeQuestion q) => [
      for (var i = 0; i < q.options.length; i++)
        if (i != q.correctIndex) q.options[i],
    ];

int _rungOf(ShapeVariation variation) => variation.index;

bool _isAxisAligned(double rotation) {
  final quarter = pi / 2;
  final rest = rotation % quarter;
  return rest < 1e-9 || quarter - rest < 1e-9;
}

bool _isTextbook(ShapeFigure figure) {
  final prototype =
      ShapeFigure.prototype(figure.kind, colorIndex: figure.colorIndex);
  return figure.proportion == prototype.proportion &&
      figure.skew == 0 &&
      figure.rotation == 0;
}

void main() {
  test('her bölümün bir kuralı var', () {
    expect(ShapeVariation.values.length, shapeLadder.length);
  });

  group('her bölümde, her soruda', () {
    for (var rung = 0; rung < shapeLadder.length; rung++) {
      test('bölüm ${rung + 1}: tam bir doğru kart, doğru kart sayısı', () {
        for (final q in _questions(rung)) {
          final matching =
              q.options.where((o) => o.kind == q.target.kind).length;

          expect(matching, 1, reason: '$q');
          expect(q.options.length, shapeLadder[rung].cards);
          expect(q.target.kind.canBeTarget, isTrue);
        }
      });

      test('bölüm ${rung + 1}: dikdörtgen hedefinde kare yok, oranlar net',
          () {
        for (final q in _questions(rung)) {
          if (q.target.kind == ShapeKind.rectangle) {
            expect(q.options.any((o) => o.kind == ShapeKind.square), isFalse,
                reason: 'kare de bir dikdörtgendir');
          }

          for (final figure in [q.target, ...q.options]) {
            if (figure.kind == ShapeKind.rectangle) {
              expect(figure.proportion, greaterThanOrEqualTo(1.5),
                  reason: 'kareye benzememeli');
            }
            if (figure.kind == ShapeKind.oval) {
              expect(figure.proportion, greaterThanOrEqualTo(1.3),
                  reason: 'daireye benzememeli');
            }
          }
        }
      });

      test('bölüm ${rung + 1}: aynı hedef art arda gelmez', () {
        for (var seed = 0; seed < _seeds; seed++) {
          final round = buildShapeRound(rung: rung, random: Random(seed));

          expect(round.length, shapeQuestionsPerRound);
          for (var i = 1; i < round.length; i++) {
            expect(round[i].target.kind, isNot(round[i - 1].target.kind));
          }
        }
      });

      test('bölüm ${rung + 1}: doğru kart her konuma düşebiliyor', () {
        final positions = {for (final q in _questions(rung)) q.correctIndex};

        expect(positions, hasLength(shapeLadder[rung].cards));
      });
    }
  });

  test('oval yalnızca son bölümde ve yalnızca çeldirici olarak çıkar', () {
    for (var rung = 0; rung < shapeLadder.length; rung++) {
      for (final q in _questions(rung)) {
        expect(q.target.kind, isNot(ShapeKind.oval));

        final hasOval = q.options.any((o) => o.kind == ShapeKind.oval);
        if (rung != _rungOf(ShapeVariation.nearMiss)) {
          expect(hasOval, isFalse, reason: 'bölüm ${rung + 1}');
        }
      }
    }
  });

  test('ilk bölüm: dikdörtgen yok, her şey aynı renk, doğru kart kopya', () {
    for (final q in _questions(_rungOf(ShapeVariation.identical))) {
      expect(q.target.kind, isNot(ShapeKind.rectangle));

      for (final option in q.options) {
        expect(option.kind, isNot(ShapeKind.rectangle));
        expect(option.colorIndex, q.target.colorIndex);
      }

      expect(q.options[q.correctIndex], q.target);
    }
  });

  test('renk bölümü: renk tek başına cevabı ele vermez', () {
    for (final q in _questions(_rungOf(ShapeVariation.color))) {
      final correct = q.options[q.correctIndex];
      final wrong = _wrong(q);

      expect(correct.colorIndex, isNot(q.target.colorIndex));
      expect(wrong.any((w) => w.colorIndex == q.target.colorIndex), isTrue,
          reason: 'hedefin renginde bir tuzak olmalı');
      expect(wrong.any((w) => w.colorIndex != q.target.colorIndex), isTrue,
          reason: 'farklı renkli tek kart doğru kart olmamalı');
    }
  });

  test('boy bölümü: boy tek başına cevabı ele vermez', () {
    final targetScales = <double>{};

    for (final q in _questions(_rungOf(ShapeVariation.size))) {
      final correct = q.options[q.correctIndex];
      final wrong = _wrong(q);
      targetScales.add(q.target.scale);

      expect(correct.scale, isNot(q.target.scale));
      expect(
        wrong.any((w) =>
            w.scale == q.target.scale && w.colorIndex == q.target.colorIndex),
        isTrue,
        reason: 'hedefin boyunda ve renginde bir tuzak olmalı',
      );
      expect(wrong.any((w) => w.scale == correct.scale), isTrue,
          reason: 'doğru kartın boyundaki tek kart o olmamalı');
    }

    expect(targetScales, hasLength(2),
        reason: 'doğru kart hep "küçük olan" olmamalı');
  });

  test('yön bölümü: daire hedef olmaz, dönmek tek başına ele vermez', () {
    for (final q in _questions(_rungOf(ShapeVariation.orientation))) {
      final correct = q.options[q.correctIndex];
      final wrong = _wrong(q);

      expect(q.target.kind, isNot(ShapeKind.circle));
      expect(q.target.rotation, 0);
      expect(correct.rotation, isNot(0));
      expect(
        wrong.any((w) =>
            w.rotation == 0 && w.colorIndex == q.target.colorIndex),
        isTrue,
        reason: 'hedefin renginde dik duran bir tuzak olmalı',
      );
      expect(wrong.any((w) => w.rotation != 0), isTrue,
          reason: 'dönmüş tek kart doğru kart olmamalı');
    }
  });

  test('oran bölümü: doğru kart hiçbir zaman ders kitabı örneği değil', () {
    for (final q in _questions(_rungOf(ShapeVariation.proportion))) {
      final correct = q.options[q.correctIndex];
      final prototype = ShapeFigure.prototype(
        correct.kind,
        colorIndex: correct.colorIndex,
      );

      final isTextbook = correct.proportion == prototype.proportion &&
          correct.skew == 0 &&
          correct.rotation == 0;

      expect(isTextbook, isFalse, reason: '$correct');
    }
  });

  test('kare hedefinde çapraz duran tek kart doğru kart olmaz', () {
    // The answer to a square is a square turned 45°. If nothing else on the
    // board sits at a slant, the slant alone gives it away.
    for (final variation in [
      ShapeVariation.orientation,
      ShapeVariation.proportion,
    ]) {
      for (final q in _questions(_rungOf(variation))) {
        if (q.target.kind != ShapeKind.square) continue;

        final correct = q.options[q.correctIndex];
        if (_isAxisAligned(correct.rotation)) continue;

        expect(
          _wrong(q).any((w) =>
              w.kind != ShapeKind.circle && !_isAxisAligned(w.rotation)),
          isTrue,
          reason: '${variation.name}: $q',
        );
      }
    }
  });

  test('oran bölümü: ders kitabı dışı tek kart doğru kart olmaz', () {
    for (final q in _questions(_rungOf(ShapeVariation.proportion))) {
      expect(_wrong(q).any((w) => !_isTextbook(w)), isTrue, reason: '$q');
    }
  });

  test('yakın çeldirici bölümü: daireye oval, kareye dikdörtgen eşlik eder',
      () {
    for (final q in _questions(_rungOf(ShapeVariation.nearMiss))) {
      if (q.target.kind == ShapeKind.circle) {
        expect(q.options.any((o) => o.kind == ShapeKind.oval), isTrue);
      }
      if (q.target.kind == ShapeKind.square) {
        expect(q.options.any((o) => o.kind == ShapeKind.rectangle), isTrue);
      }
    }
  });

  test('aynı tohum aynı turu üretir', () {
    for (var rung = 0; rung < shapeLadder.length; rung++) {
      final a = buildShapeRound(rung: rung, random: Random(42));
      final b = buildShapeRound(rung: rung, random: Random(42));

      for (var i = 0; i < a.length; i++) {
        expect(a[i].target, b[i].target);
        expect(a[i].options, b[i].options);
      }
    }
  });

  test('temiz tur: ilk dokunuşta en fazla bir hata', () {
    expect(isCleanShapeRound(0), isTrue);
    expect(isCleanShapeRound(1), isTrue);
    expect(isCleanShapeRound(2), isFalse);
  });
}
