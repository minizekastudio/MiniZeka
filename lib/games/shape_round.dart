import 'dart:math';

import '../difficulty.dart';
import 'shape_figure.dart';

/// What the matching card may look different in, by rung of [shapeLadder].
///
/// Declaration order is rung order. Each rung keeps the variations of the
/// rungs below it and adds one.
enum ShapeVariation {
  /// The matching card is an exact copy; every card has the same colour, so
  /// shape is the only thing to look at.
  identical,

  /// Different colour.
  color,

  /// Different size.
  size,

  /// Turned.
  orientation,

  /// Unusual proportions: a thin, squat or lopsided triangle, a long
  /// rectangle, a turned square.
  proportion,

  /// A look-alike sits among the wrong cards: an oval next to a circle, a
  /// rectangle next to a square.
  nearMiss;

  static ShapeVariation forRung(int rung) =>
      values[rung.clamp(0, values.length - 1)];
}

/// Questions in one round.
const int shapeQuestionsPerRound = 5;

/// A round is clean — and counts towards the next rung — with at most this
/// many questions answered wrong on the first tap.
///
/// Needed because a wrong tap does not end a question here: without it a
/// child could tap cards at random and still climb.
const int maxFirstTryMistakesInCleanRound = 1;

bool isCleanShapeRound(int firstTryMistakes) =>
    firstTryMistakes <= maxFirstTryMistakesInCleanRound;

/// One target and the cards to choose from; exactly one card is the same
/// kind of shape as the target.
class ShapeQuestion {
  const ShapeQuestion({required this.target, required this.options});

  final ShapeFigure target;
  final List<ShapeFigure> options;

  int get correctIndex => options.indexWhere((o) => o.kind == target.kind);
}

/// Builds a round for [rung]. [random] is injected so tests can pin it.
List<ShapeQuestion> buildShapeRound({
  required int rung,
  required Random random,
  int questionCount = shapeQuestionsPerRound,
}) {
  final safeRung = rung.clamp(0, shapeLadder.length - 1);
  final builder = _QuestionBuilder(
    variation: ShapeVariation.forRung(safeRung),
    cardCount: shapeLadder[safeRung].cards,
    random: random,
  );

  final targets = _targetSequence(
    pool: _targetPool(ShapeVariation.forRung(safeRung)),
    count: questionCount,
    random: random,
  );

  return [for (final kind in targets) builder.build(kind)];
}

/// Which kinds can be the target on a rung.
List<ShapeKind> _targetPool(ShapeVariation variation) => switch (variation) {
      ShapeVariation.identical => const [
          ShapeKind.circle,
          ShapeKind.square,
          ShapeKind.triangle,
        ],
      // Turning a circle changes nothing; it cannot be the target of a rung
      // that is about turning. Nor can a circle be drawn "unusually".
      ShapeVariation.orientation || ShapeVariation.proportion => const [
          ShapeKind.square,
          ShapeKind.triangle,
          ShapeKind.rectangle,
        ],
      ShapeVariation.color ||
      ShapeVariation.size ||
      ShapeVariation.nearMiss =>
        const [
          ShapeKind.circle,
          ShapeKind.square,
          ShapeKind.triangle,
          ShapeKind.rectangle,
        ],
    };

/// Draws targets from a shuffled bag so every kind comes up, and never the
/// same kind twice in a row.
List<ShapeKind> _targetSequence({
  required List<ShapeKind> pool,
  required int count,
  required Random random,
}) {
  final sequence = <ShapeKind>[];
  var bag = <ShapeKind>[];

  while (sequence.length < count) {
    if (bag.isEmpty) {
      bag = [...pool]..shuffle(random);

      // Refilling can put the last kind first again; move it along.
      if (sequence.isNotEmpty && bag.first == sequence.last && bag.length > 1) {
        bag.add(bag.removeAt(0));
      }
    }

    sequence.add(bag.removeAt(0));
  }

  return sequence;
}

class _QuestionBuilder {
  _QuestionBuilder({
    required this.variation,
    required this.cardCount,
    required this.random,
  });

  final ShapeVariation variation;
  final int cardCount;
  final Random random;

  bool _isAtLeast(ShapeVariation other) => variation.index >= other.index;

  ShapeQuestion build(ShapeKind targetKind) {
    final target = _target(targetKind);
    final correct = _correct(target);
    final distractors = _distractors(target, correct);

    final options = [correct, ...distractors]..shuffle(random);

    return ShapeQuestion(target: target, options: options);
  }

  // ---- target -----------------------------------------------------------

  ShapeFigure _target(ShapeKind kind) {
    // The target is always the textbook example, so the child compares the
    // disguised card against a reference that does not move.
    final figure = ShapeFigure.prototype(kind, colorIndex: _anyColor());

    // From the size rung on the target's own size varies too; otherwise
    // "the small one" would always be the answer.
    if (_isAtLeast(ShapeVariation.size)) {
      return figure.copyWith(scale: _anyScale());
    }

    return figure;
  }

  // ---- matching card ----------------------------------------------------

  ShapeFigure _correct(ShapeFigure target) {
    var figure = ShapeFigure.prototype(
      target.kind,
      colorIndex: target.colorIndex,
    ).copyWith(scale: target.scale);

    switch (variation) {
      case ShapeVariation.identical:
        return figure;

      case ShapeVariation.color:
        return figure.copyWith(colorIndex: _otherColor(target.colorIndex));

      case ShapeVariation.size:
        return figure.copyWith(
          colorIndex: _anyColor(),
          scale: _otherScale(target.scale),
        );

      case ShapeVariation.orientation:
        return figure.copyWith(
          colorIndex: _anyColor(),
          scale: _anyScale(),
          rotation: _visibleTurn(target.kind),
        );

      case ShapeVariation.proportion:
        figure = figure.copyWith(colorIndex: _anyColor(), scale: _anyScale());
        return _unusual(figure);

      case ShapeVariation.nearMiss:
        figure = figure.copyWith(colorIndex: _anyColor(), scale: _anyScale());
        return random.nextBool() ? _unusual(figure) : _maybeTurned(figure);
    }
  }

  // ---- wrong cards ------------------------------------------------------

  List<ShapeFigure> _distractors(ShapeFigure target, ShapeFigure correct) {
    final count = cardCount - 1;
    final kinds = _distractorKinds(target.kind, count);

    if (_isAtLeast(ShapeVariation.orientation)) _putTurnableSecond(kinds);

    final figures = [
      for (final kind in kinds)
        ShapeFigure.prototype(kind, colorIndex: target.colorIndex),
    ];

    switch (variation) {
      case ShapeVariation.identical:
        // Same colour as everything else: shape is the only cue.
        return figures;

      case ShapeVariation.color:
        // One wrong card wears the target's colour, one wears another, so
        // colour alone never picks out the answer.
        return [
          for (var i = 0; i < figures.length; i++)
            figures[i].copyWith(
              colorIndex: i == 0
                  ? target.colorIndex
                  : i == 1
                      ? _otherColor(target.colorIndex)
                      : _anyColor(),
            ),
        ];

      case ShapeVariation.size:
        // One wrong card copies the target's size and colour, one has the
        // matching card's size, so size alone never picks out the answer.
        return [
          for (var i = 0; i < figures.length; i++)
            switch (i) {
              0 => figures[i].copyWith(
                  colorIndex: target.colorIndex,
                  scale: target.scale,
                ),
              1 => figures[i].copyWith(
                  colorIndex: _anyColor(),
                  scale: correct.scale,
                ),
              _ => figures[i].copyWith(
                  colorIndex: _anyColor(),
                  scale: _anyScale(),
                ),
            },
        ];

      case ShapeVariation.orientation:
        // One wrong card is upright in the target's colour, one is turned
        // like the matching card, so turning alone never picks it out.
        return [
          for (var i = 0; i < figures.length; i++)
            switch (i) {
              0 => figures[i].copyWith(
                  colorIndex: target.colorIndex,
                  scale: target.scale,
                ),
              1 => figures[i].copyWith(
                  colorIndex: _anyColor(),
                  scale: _anyScale(),
                  rotation: _turnLike(correct, figures[i].kind),
                ),
              _ => _maybeTurned(
                  figures[i].copyWith(
                    colorIndex: _anyColor(),
                    scale: _anyScale(),
                  ),
                ),
            },
        ];

      case ShapeVariation.proportion:
      case ShapeVariation.nearMiss:
        // Slot 0 wears the target's colour and size. Slot 1 is unusual too,
        // and slanted when the matching card is, so neither an odd
        // proportion nor a slant alone picks out the answer.
        return [
          for (var i = 0; i < figures.length; i++)
            switch (i) {
              0 => figures[i].copyWith(
                  colorIndex: target.colorIndex,
                  scale: target.scale,
                ),
              1 => _slantedLike(
                  correct,
                  _unusual(
                    figures[i].copyWith(
                      colorIndex: _anyColor(),
                      scale: _anyScale(),
                    ),
                  ),
                ),
              _ => _mixed(figures[i]),
            },
        ];
    }
  }

  /// Wrong kinds, as varied as the count allows.
  List<ShapeKind> _distractorKinds(ShapeKind target, int count) {
    final allowed = <ShapeKind>[
      for (final kind in _distractorPool)
        if (kind != target &&
            // A square is a rectangle: it cannot be a wrong answer to one.
            !(target == ShapeKind.rectangle && kind == ShapeKind.square))
          kind,
    ];

    final forced = <ShapeKind>[
      if (variation == ShapeVariation.nearMiss && target == ShapeKind.circle)
        ShapeKind.oval,
      if (variation == ShapeVariation.nearMiss && target == ShapeKind.square)
        ShapeKind.rectangle,
    ];

    final kinds = <ShapeKind>[...forced];
    var cycle = <ShapeKind>[];

    while (kinds.length < count) {
      if (cycle.isEmpty) cycle = [...allowed]..shuffle(random);
      kinds.add(cycle.removeAt(0));
    }

    // Keep the look-alike, if any, in slot 0 where the trap styling goes.
    return kinds.take(count).toList();
  }

  /// Slot 1 is the wrong card turned like the matching one. A circle there
  /// would "turn" invisibly and quietly break that rule.
  static void _putTurnableSecond(List<ShapeKind> kinds) {
    bool isTurnable(ShapeKind kind) =>
        kind != ShapeKind.circle && kind != ShapeKind.oval;

    if (kinds.length < 2 || isTurnable(kinds[1])) return;

    var swapWith = kinds.indexWhere(isTurnable, 2);
    if (swapWith == -1 && isTurnable(kinds[0])) swapWith = 0;
    if (swapWith == -1) return;

    final second = kinds[1];
    kinds[1] = kinds[swapWith];
    kinds[swapWith] = second;
  }

  List<ShapeKind> get _distractorPool =>
      variation == ShapeVariation.identical
          ? const [ShapeKind.circle, ShapeKind.square, ShapeKind.triangle]
          : const [
              ShapeKind.circle,
              ShapeKind.square,
              ShapeKind.triangle,
              ShapeKind.rectangle,
            ];

  // ---- dress-up helpers -------------------------------------------------

  int _anyColor() => random.nextInt(shapeFillColors.length);

  int _otherColor(int color) =>
      (color + 1 + random.nextInt(shapeFillColors.length - 1)) %
      shapeFillColors.length;

  double _anyScale() =>
      random.nextBool() ? ShapeFigure.fullScale : ShapeFigure.smallScale;

  double _otherScale(double scale) => scale == ShapeFigure.fullScale
      ? ShapeFigure.smallScale
      : ShapeFigure.fullScale;

  /// A turn that visibly changes the figure. A square turned by 90° looks
  /// the same, so it turns by 45°.
  double _visibleTurn(ShapeKind kind) => switch (kind) {
        ShapeKind.square => pi / 4,
        ShapeKind.triangle => random.nextBool() ? pi / 2 : pi,
        ShapeKind.rectangle => pi / 2,
        ShapeKind.circle || ShapeKind.oval => 0,
      };

  ShapeFigure _maybeTurned(ShapeFigure figure) => random.nextBool()
      ? figure.copyWith(rotation: _visibleTurn(figure.kind))
      : figure;

  static bool _isSlanted(double rotation) {
    final rest = rotation % (pi / 2);
    return rest > 1e-9 && pi / 2 - rest > 1e-9;
  }

  /// A turn for a wrong card of [kind] that looks like the matching card's.
  ///
  /// A square's answer is turned 45°, and nothing else ever sat at a slant,
  /// so the slant alone gave it away. When the matching card is slanted, the
  /// wrong card is slanted too.
  double _turnLike(ShapeFigure correct, ShapeKind kind) =>
      _isSlanted(correct.rotation) ? pi / 4 : _visibleTurn(kind);

  ShapeFigure _slantedLike(ShapeFigure correct, ShapeFigure figure) =>
      _isSlanted(correct.rotation) && figure.kind != ShapeKind.circle
          ? figure.copyWith(rotation: pi / 4)
          : figure;

  /// A non-textbook example of the same kind.
  ShapeFigure _unusual(ShapeFigure figure) {
    switch (figure.kind) {
      case ShapeKind.triangle:
        final shaped = switch (random.nextInt(3)) {
          0 => figure.copyWith(proportion: 1.8), // thin and tall
          1 => figure.copyWith(proportion: 0.45), // squat
          _ => figure.copyWith(
              proportion: 0.8,
              skew: random.nextBool() ? 0.4 : -0.4,
            ), // lopsided
        };
        return _maybeTurned(shaped);
      case ShapeKind.rectangle:
        return _maybeTurned(figure.copyWith(proportion: 2.4));
      case ShapeKind.square:
        return figure.copyWith(rotation: pi / 4);
      case ShapeKind.circle:
      case ShapeKind.oval:
        return figure;
    }
  }

  ShapeFigure _mixed(ShapeFigure figure) {
    final dressed = figure.copyWith(colorIndex: _anyColor(), scale: _anyScale());
    return random.nextBool() ? _unusual(dressed) : _maybeTurned(dressed);
  }
}
