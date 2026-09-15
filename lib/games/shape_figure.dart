import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../app_theme.dart';

/// The shape categories the matching game asks about.
enum ShapeKind {
  circle('Daire'),
  square('Kare'),
  triangle('Üçgen'),
  rectangle('Dikdörtgen'),
  oval('Oval');

  const ShapeKind(this.label);

  /// Turkish name for screen readers. Never drawn as text: the players
  /// mostly cannot read.
  final String label;

  /// An oval only ever appears as the near miss next to a circle.
  bool get canBeTarget => this != ShapeKind.oval;
}

/// Fill colours for figures, all from the brand palette.
///
/// Green and red are left out on purpose: next to a right or wrong answer
/// they would read as "correct" and "wrong" (the same call as the math
/// game's answer buttons).
const List<Color> shapeFillColors = [
  Brand.gameMemory,
  Brand.gameAttention,
  Brand.gameMath,
  Brand.gameWord,
  Brand.gameLetter,
];

/// One drawn example of a [ShapeKind]: which kind, and how this particular
/// example is dressed up — colour, size, turn and proportion.
///
/// The game is about seeing that a turned, stretched or recoloured square is
/// still a square, so these are data rather than baked into a picture. An
/// emoji could not be recoloured, stretched or turned.
@immutable
class ShapeFigure {
  const ShapeFigure({
    required this.kind,
    required this.colorIndex,
    required this.scale,
    required this.rotation,
    required this.proportion,
    required this.skew,
  });

  /// The textbook example of [kind]: upright, full size, usual proportions.
  const ShapeFigure.prototype(this.kind, {required this.colorIndex})
      : scale = fullScale,
        rotation = 0,
        proportion = kind == ShapeKind.triangle
            ? 0.87
            : kind == ShapeKind.rectangle
                ? 1.6
                : kind == ShapeKind.oval
                    ? 1.45
                    : 1,
        skew = 0;

  static const double fullScale = 1;
  static const double smallScale = 0.6;

  final ShapeKind kind;

  /// Index into [shapeFillColors].
  final int colorIndex;

  /// 1 fills the box; [smallScale] is visibly smaller.
  final double scale;

  /// Radians, clockwise.
  final double rotation;

  /// Width to height for rectangles and ovals; height to base for
  /// triangles. Ignored for circles and squares.
  final double proportion;

  /// Where a triangle's apex sits over its base, from -0.5 (above the left
  /// corner) to 0.5 (above the right). 0 is the usual isosceles triangle.
  final double skew;

  Color get color => shapeFillColors[colorIndex % shapeFillColors.length];

  ShapeFigure copyWith({
    int? colorIndex,
    double? scale,
    double? rotation,
    double? proportion,
    double? skew,
  }) {
    return ShapeFigure(
      kind: kind,
      colorIndex: colorIndex ?? this.colorIndex,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      proportion: proportion ?? this.proportion,
      skew: skew ?? this.skew,
    );
  }

  /// Geometry part-way from [a] to [b]. Kind and colour index come from [b];
  /// the painter blends the colour itself.
  static ShapeFigure lerp(ShapeFigure a, ShapeFigure b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;

    return ShapeFigure(
      kind: b.kind,
      colorIndex: b.colorIndex,
      scale: lerpDouble(a.scale, b.scale, t)!,
      rotation: lerpDouble(a.rotation, b.rotation, t)!,
      proportion: lerpDouble(a.proportion, b.proportion, t)!,
      skew: lerpDouble(a.skew, b.skew, t)!,
    );
  }

  /// How far from the centre a figure may reach at full scale, as a share
  /// of half the box's shorter side. Only turned or stretched figures come
  /// near it; the card's padding holds the outline stroke.
  static const double _fill = 1.0;

  /// Area every figure aims for, as a multiple of its squared reach.
  ///
  /// Figures used to fill the circle around them, which left a triangle
  /// with a third of a circle's area: on every board it was visibly the
  /// smallest card, so size gave the answer away. Aiming for one shared area
  /// makes a circle, a square and a triangle look the same size; a figure
  /// that cannot reach that area without leaving the box (a squat triangle)
  /// is simply as large as it can be.
  static const double _areaFactor = 1.15;

  /// The outline centred in [box], scaled and turned.
  ///
  /// The reach limit is a circle, so a figure stays inside the box however
  /// it is turned, and turning a square does not shrink it.
  Path outlineIn(Size box) {
    final reach = box.shortestSide / 2 * _fill * scale;
    final area = _areaFactor * reach * reach;

    final Path shape = switch (kind) {
      ShapeKind.circle => Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset.zero,
            radius: min(sqrt(area / pi), reach),
          ),
        ),
      ShapeKind.oval => _oval(area, reach),
      ShapeKind.square ||
      ShapeKind.triangle ||
      ShapeKind.rectangle =>
        _polygon(_unitVertices(), area, reach),
    };

    final placement = Matrix4.translationValues(
      box.width / 2,
      box.height / 2,
      0,
    )..rotateZ(rotation);

    return shape.transform(placement.storage);
  }

  List<Offset> _unitVertices() {
    switch (kind) {
      case ShapeKind.square:
        return const [
          Offset(-1, -1),
          Offset(1, -1),
          Offset(1, 1),
          Offset(-1, 1),
        ];
      case ShapeKind.rectangle:
        return [
          Offset(-proportion, -1),
          Offset(proportion, -1),
          Offset(proportion, 1),
          Offset(-proportion, 1),
        ];
      case ShapeKind.triangle:
        final halfHeight = proportion;
        return [
          Offset(-1, halfHeight),
          Offset(1, halfHeight),
          Offset(skew * 2, -halfHeight),
        ];
      case ShapeKind.circle:
      case ShapeKind.oval:
        return const [];
    }
  }

  Path _oval(double area, double reach) {
    // Area of an ellipse: pi * halfWidth * halfHeight, halfHeight being
    // halfWidth / proportion.
    final halfWidth = min(sqrt(area * proportion / pi), reach);

    return Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: halfWidth * 2,
          height: halfWidth * 2 / proportion,
        ),
      );
  }

  static Path _polygon(List<Offset> vertices, double area, double reach) {
    final unitReach = vertices.map((v) => v.distance).reduce(max);
    final factor = min(sqrt(area / _polygonArea(vertices)), reach / unitReach);

    return Path()
      ..addPolygon([for (final v in vertices) v * factor], true);
  }

  static double _polygonArea(List<Offset> vertices) {
    var twice = 0.0;
    for (var i = 0; i < vertices.length; i++) {
      final a = vertices[i];
      final b = vertices[(i + 1) % vertices.length];
      twice += a.dx * b.dy - b.dx * a.dy;
    }
    return twice.abs() / 2;
  }

  @override
  bool operator ==(Object other) =>
      other is ShapeFigure &&
      other.kind == kind &&
      other.colorIndex == colorIndex &&
      other.scale == scale &&
      other.rotation == rotation &&
      other.proportion == proportion &&
      other.skew == skew;

  @override
  int get hashCode =>
      Object.hash(kind, colorIndex, scale, rotation, proportion, skew);

  @override
  String toString() =>
      'ShapeFigure(${kind.name}, color $colorIndex, scale $scale, '
      'rotation ${rotation.toStringAsFixed(2)}, proportion $proportion, '
      'skew $skew)';
}

/// Draws a [ShapeFigure], optionally part-way through turning into
/// [morphTarget] — the target changing into the card the child picked, which
/// shows without words that the shape stayed the same.
class ShapePainter extends CustomPainter {
  const ShapePainter({
    required this.figure,
    this.morphTarget,
    this.morph = 0,
  });

  final ShapeFigure figure;
  final ShapeFigure? morphTarget;
  final double morph;

  @override
  void paint(Canvas canvas, Size size) {
    final target = morphTarget;

    final shown =
        target == null ? figure : ShapeFigure.lerp(figure, target, morph);
    final fill = target == null
        ? figure.color
        : Color.lerp(figure.color, target.color, morph)!;

    final outline = shown.outlineIn(size);

    canvas.drawPath(
      outline,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );

    // A darker edge keeps light fills (yellow, sky) visible on a white card.
    canvas.drawPath(
      outline,
      Paint()
        ..color = Color.lerp(fill, Brand.textOnLight, 0.3)!
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = max(2, size.shortestSide * 0.025),
    );
  }

  @override
  bool shouldRepaint(ShapePainter oldDelegate) =>
      oldDelegate.figure != figure ||
      oldDelegate.morphTarget != morphTarget ||
      oldDelegate.morph != morph;
}
