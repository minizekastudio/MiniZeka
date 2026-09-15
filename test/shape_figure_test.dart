import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:mini_zeka/games/shape_figure.dart';


/// Area enclosed by a drawn outline, from points sampled along it.
double _areaOf(Path path) {
  final points = <Offset>[];
  for (final metric in path.computeMetrics()) {
    for (var d = 0.0; d < metric.length; d += 0.5) {
      points.add(metric.getTangentForOffset(d)!.position);
    }
  }

  var twice = 0.0;
  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];
    twice += a.dx * b.dy - b.dx * a.dy;
  }
  return twice.abs() / 2;
}

void main() {
  group('ShapeFigure çizimi', () {
    const box = Size(120, 90);
    final inside = (Offset.zero & box).inflate(0.5);

    test('her tür, her boy ve her dönüşte kutunun içinde kalır', () {
      final variants = <ShapeFigure>[
        for (final kind in ShapeKind.values)
          for (final scale in [ShapeFigure.fullScale, ShapeFigure.smallScale])
            for (final rotation in [0.0, pi / 4, pi / 2, pi])
              ShapeFigure.prototype(kind, colorIndex: 0)
                  .copyWith(scale: scale, rotation: rotation),
        // The unusual ones the ladder uses.
        const ShapeFigure.prototype(ShapeKind.triangle, colorIndex: 1)
            .copyWith(proportion: 1.8),
        const ShapeFigure.prototype(ShapeKind.triangle, colorIndex: 1)
            .copyWith(proportion: 0.45, rotation: pi / 2),
        const ShapeFigure.prototype(ShapeKind.triangle, colorIndex: 1)
            .copyWith(proportion: 0.8, skew: 0.4, rotation: pi),
        const ShapeFigure.prototype(ShapeKind.rectangle, colorIndex: 2)
            .copyWith(proportion: 2.4, rotation: pi / 2),
      ];

      for (final figure in variants) {
        // Sample the drawn outline itself. Path.getBounds() covers curve
        // control points, which stick out of a turned circle it draws fine.
        for (final metric in figure.outlineIn(box).computeMetrics()) {
          for (var d = 0.0; d <= metric.length; d += 1) {
            final point = metric.getTangentForOffset(d)!.position;

            expect(inside.contains(point), isTrue, reason: '$figure @ $point');
          }
        }
      }
    });

    test('ders kitabı şekilleri aynı boyda yaklaşık aynı alanı kaplar', () {
      // Sized by the circle around them, a triangle covered a third of a
      // circle's area and was always visibly the smallest card: size gave
      // the answer away.
      const square = Size(120, 120);
      final areas = {
        for (final kind in ShapeKind.values)
          kind: _areaOf(
            ShapeFigure.prototype(kind, colorIndex: 0).outlineIn(square),
          ),
      };

      final largest = areas.values.reduce(max);
      final smallest = areas.values.reduce(min);

      expect(largest / smallest, lessThanOrEqualTo(1.25), reason: '$areas');
    });

    test('alışılmadık oranlı şekiller de çok küçük kalmaz', () {
      const square = Size(120, 120);
      final reference = _areaOf(
        const ShapeFigure.prototype(ShapeKind.square, colorIndex: 0)
            .outlineIn(square),
      );

      final unusual = [
        const ShapeFigure.prototype(ShapeKind.triangle, colorIndex: 0)
            .copyWith(proportion: 1.8),
        const ShapeFigure.prototype(ShapeKind.triangle, colorIndex: 0)
            .copyWith(proportion: 0.45),
        const ShapeFigure.prototype(ShapeKind.triangle, colorIndex: 0)
            .copyWith(proportion: 0.8, skew: 0.4),
        const ShapeFigure.prototype(ShapeKind.rectangle, colorIndex: 0)
            .copyWith(proportion: 2.4),
      ];

      for (final figure in unusual) {
        expect(_areaOf(figure.outlineIn(square)) / reference,
            greaterThanOrEqualTo(0.6),
            reason: '$figure');
      }
    });

    test('küçük boy gerçekten küçük çizilir', () {
      for (final kind in ShapeKind.values) {
        final full = ShapeFigure.prototype(kind, colorIndex: 0);
        final small = full.copyWith(scale: ShapeFigure.smallScale);

        expect(
          small.outlineIn(box).getBounds().width,
          lessThan(full.outlineIn(box).getBounds().width * 0.7),
          reason: kind.name,
        );
      }
    });

    test('dönmüş kare dik kareden küçük görünmez', () {
      const square = ShapeFigure.prototype(ShapeKind.square, colorIndex: 0);
      final upright = square.outlineIn(box).getBounds();
      final turned = square.copyWith(rotation: pi / 4).outlineIn(box).getBounds();

      // Turned 45°, its bounding box is the diagonal: larger, not smaller.
      expect(turned.width, greaterThan(upright.width));
    });

    test('lerp uçlarda kendi figürlerini verir, ortada arada kalır', () {
      const a = ShapeFigure.prototype(ShapeKind.square, colorIndex: 0);
      final b = a.copyWith(colorIndex: 3, scale: 0.6, rotation: pi / 4);

      expect(ShapeFigure.lerp(a, b, 0), a);
      expect(ShapeFigure.lerp(a, b, 1), b);

      final middle = ShapeFigure.lerp(a, b, 0.5);
      expect(middle.kind, ShapeKind.square);
      expect(middle.scale, closeTo(0.8, 1e-9));
      expect(middle.rotation, closeTo(pi / 8, 1e-9));
    });
  });

  test('türlerin ekran okuyucu adları dolu ve birbirinden farklı', () {
    final labels = ShapeKind.values.map((k) => k.label).toList();

    expect(labels.every((l) => l.isNotEmpty), isTrue);
    expect(labels.toSet(), hasLength(labels.length));
    expect(ShapeKind.oval.canBeTarget, isFalse);
  });

  test('dolgu renklerinde yeşil ve kırmızı yok', () {
    const green = Color(0xFF3BA84A);
    const red = Color(0xFFE24B3F);

    expect(shapeFillColors, isNot(contains(green)));
    expect(shapeFillColors, isNot(contains(red)));
  });
}
