/// How hard a game should be, in one place.
///
/// Before this, "difficulty" meant three unrelated things:
///   * `childAge` if-chains copied into five games, with four age bands
///   * `levelForAge`, which used only three bands, so a 4 and a 7 year old
///     were treated the same in one game but differently in another
///   * a `level` field that in two games was recomputed from the question
///     index and never touched the questions at all — it only multiplied the
///     score while the screen claimed "Zor Seviye"
///
/// Now there is one concept: the child's [AgeBand] picks the rung a game
/// starts on, and the child climbs from there by playing clean rounds. The
/// progress is saved and never goes backwards.
library;

import 'game_id.dart';

/// The four age bands the games are tuned for.
enum AgeBand {
  /// 4-5
  preschool,

  /// 6-7
  early,

  /// 8-9
  mid,

  /// 10-12
  older;

  static AgeBand forAge(int age) {
    if (age <= 5) return AgeBand.preschool;
    if (age <= 7) return AgeBand.early;
    if (age <= 9) return AgeBand.mid;
    return AgeBand.older;
  }

  /// 0..3 — index into a per-game table of four values.
  int get step => index;

  /// Parent-facing label for this band.
  String get label => switch (this) {
    AgeBand.preschool => '4 – 5 Yaş',
    AgeBand.early => '6 – 7 Yaş',
    AgeBand.mid => '8 – 9 Yaş',
    AgeBand.older => '10 – 12 Yaş',
  };
}

/// Every game now climbs its own saved ladder, so the old in-game
/// `DifficultyTracker` — level 1-3, three correct answers in a row, a
/// "Kolay / Orta / Zor" chip — is gone. It could not survive a session,
/// which is exactly what a child needs it to do, and its last two users
/// (the word and letter games) were rewritten onto ladders.

/// One rung of a game's level ladder.
class GameLevel {
  const GameLevel({required this.cards, required this.roundsToAdvance});

  /// How many cards are on the board at this level.
  final int cards;

  /// Clean rounds needed here before the next rung opens.
  final int roundsToAdvance;
}

/// The memory game's ladder.
///
/// Shaped from developmental evidence rather than round numbers:
///
///   * Visual working memory is roughly 1.5 items at age 5, 3 at 7 and
///     adult-like (3-4) around 10 (Riggs et al. 2006; Ross-Sheehy et al.
///     2021). A matching grid is easier than a span test — it is sequential,
///     self-paced, and the board itself is an external memory aid — so grid
///     size can exceed that span, but not by an unlimited factor.
///   * Ross-Sheehy et al. (2021) found 4-7 year olds' measured capacity
///     DROPS on larger arrays: they disengage and start guessing. An
///     oversized board does not just slow a child down, it teaches the wrong
///     behaviour. Hence the conservative bottom of this ladder.
///   * 4 -> 8 would double the cards in one step, the largest proportional
///     jump anywhere, landing exactly on the 4-5 year old ceiling. A 6-card
///     rung sits in between.
///   * 10 cards is skipped: it has no layout that fills a phone screen
///     without a ragged last row.
///
/// The rung counts are a calibration, not a measured constant. What the
/// evidence settles is the shape: start low, grow slowly at the bottom.
const List<GameLevel> memoryLadder = [
  // Teaches the rule without words; a non-reader cannot really fail it.
  GameLevel(cards: 4, roundsToAdvance: 2),
  GameLevel(cards: 6, roundsToAdvance: 3),
  GameLevel(cards: 8, roundsToAdvance: 3),
  GameLevel(cards: 12, roundsToAdvance: 3),
  GameLevel(cards: 16, roundsToAdvance: 3),
  GameLevel(cards: 20, roundsToAdvance: 3),
];

/// The shape matching game's ladder.
///
/// Each rung changes one more thing about the card that matches, while its
/// shape stays the same: nothing at first, then colour, size, orientation,
/// proportion, and finally a look-alike shape placed next to it
/// (see `ShapeVariation` in lib/games/shape_round.dart).
///
/// The order follows how young children's shape concepts develop. They
/// accept upright, textbook examples and reject turned or skinny ones —
/// a turned square is "not a square" and a thin triangle "not a triangle"
/// (Clements, Swaminathan, Hannibal & Sarama 1999). Ignoring colour while
/// sorting by shape is its own step: switching which dimension counts is
/// what the Dimensional Change Card Sort measures (Zelazo 2006).
///
/// Card counts, round counts and what makes a round clean are calibration,
/// not measured constants. The evidence settles the order of the steps.
const List<GameLevel> shapeLadder = [
  GameLevel(cards: 3, roundsToAdvance: 2),
  GameLevel(cards: 3, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 6, roundsToAdvance: 3),
  GameLevel(cards: 6, roundsToAdvance: 3),
];

/// Where a child of this age starts the ladder.
///
/// Nobody is locked out of the lower rungs and nobody is dropped back down:
/// helplessness responses are already present at 4-7 (Burhans & Dweck 1995),
/// so the level never visibly goes backwards.
int startingLevelFor(AgeBand band) => switch (band) {
  AgeBand.preschool => 0,
  AgeBand.early => 1,
  AgeBand.mid => 2,
  AgeBand.older => 3,
};

/// How long a mismatched pair stays face up before turning back over.
///
/// It used to be 550 ms for every age. Processing speed rises steeply through
/// childhood (Kail 1991), so for a 4-5 year old the pair closed before the
/// second card had really been looked at, and the game drifted into guessing
/// — the behaviour the ladder is shaped to avoid.
///
/// The values are a calibration, not a measured constant: the evidence
/// settles the direction (younger means longer), not the milliseconds.
Duration mismatchHoldFor(AgeBand band) => switch (band) {
  AgeBand.preschool => const Duration(milliseconds: 1100),
  AgeBand.early => const Duration(milliseconds: 900),
  AgeBand.mid => const Duration(milliseconds: 700),
  AgeBand.older => const Duration(milliseconds: 550),
};

/// A matched pair stays on the board anyway, so this only needs to be long
/// enough to see the second card land. Waiting the full mismatch hold here
/// would make a correct guess feel slower than a wrong one.
const Duration matchHold = Duration(milliseconds: 350);

/// The attention game's ladder.
///
/// Difficulty used to come from the number of boxes, with the odd one out
/// drawn at random from a flat list: one board asked to spot a 🚗 among
/// apples (free), the next a 🍏 among 🍎 (impossible at that size). What
/// actually decides how hard a visual search is, is how much the target
/// resembles the rest — a target that differs in an obvious way pops out
/// however many boxes there are, while a similar one forces a box-by-box
/// search (Treisman & Gelade 1980; Duncan & Humphreys 1989).
///
/// So the rungs raise similarity first and count second, and what changes on
/// each is written in `attentionRules` (lib/games/attention_round.dart).
///
/// The counts stop at 16: a 20-box board cannot give 64 px touch targets on
/// the narrowest phone. Counts and round counts are calibration.
const List<GameLevel> attentionLadder = [
  GameLevel(cards: 6, roundsToAdvance: 2),
  GameLevel(cards: 9, roundsToAdvance: 3),
  GameLevel(cards: 9, roundsToAdvance: 3),
  GameLevel(cards: 12, roundsToAdvance: 3),
  GameLevel(cards: 12, roundsToAdvance: 3),
  GameLevel(cards: 16, roundsToAdvance: 3),
];

/// The math game's ladder.
///
/// It only ever asked "4 + 1 = ?" in digits. Most of the target age is still
/// learning what the digit means; early number sense is built by counting
/// things and seeing quantities, and symbols come after that. So the rungs
/// start from objects a child can count and take the objects away later,
/// and the ladder also brings in taking away, not just adding.
///
/// `cards` is the number of answer choices, four on every rung.
const List<GameLevel> mathLadder = [
  GameLevel(cards: 4, roundsToAdvance: 2),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
];

/// The logic game's ladder.
///
/// The game used to hold twenty hand-written questions, five per age band —
/// and a round is five questions, so a child saw the whole band in one
/// sitting and the same five again next time. Most of them were sentences
/// ("Hangisi bir hayvandır?") the target age cannot read, or number
/// sequences, which is reading of another kind.
///
/// Now it is repeating patterns, which are wordless, endless to generate and
/// the usual first step into algebraic thinking at this age: read the unit
/// that repeats, then say what belongs in the gap. The rungs lengthen the
/// unit and then move the gap off the end (see `logicRules`).
///
/// `cards` is the number of answer choices.
const List<GameLevel> logicLadder = [
  GameLevel(cards: 4, roundsToAdvance: 2),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
];

/// The word game's ladder.
///
/// The game held eighteen words in three tiers, and a round was ten
/// questions: the youngest band drew from six words, so words came round
/// again inside a single sitting. It also ran a two minute countdown and
/// took a life for every wrong answer — a stopwatch and a way to lose, in a
/// game for four year olds, in an app that has neither anywhere else.
///
/// The rungs now go from "which letter does it start with" to spelling
/// longer and longer words, with spare letters mixed in higher up.
///
/// `cards` is unused here; the board is the word's letters.
const List<GameLevel> wordLadder = [
  GameLevel(cards: 4, roundsToAdvance: 2),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
];

/// The letter game's ladder.
///
/// The game was a second spelling game: show a picture, build its name out
/// of letters — sixteen of its seventeen words were also in the word game's
/// pool. Two of seven games asked for exactly the same thing. It also ran a
/// two and a half minute countdown, took a life for every miss, and the only
/// way to place a letter was to press and hold it and drag it onto a 58 px
/// target, which is a demanding piece of motor control at four.
///
/// Building words now belongs to the word game alone. This one teaches the
/// letter itself — the same letter in another form, the sound a picture
/// starts with, where a letter sits in the alphabet — which is the step
/// before spelling and was missing from the app entirely.
const List<GameLevel> letterLadder = [
  GameLevel(cards: 4, roundsToAdvance: 2),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
  GameLevel(cards: 4, roundsToAdvance: 3),
];

/// The ladder a game climbs.
///
/// Every game has one, so the switch is exhaustive: adding a game to
/// [GameId] will not compile until it is given a ladder here. The parent
/// panel reads progress through this, which is why it cannot disagree with
/// the games about how many rungs there are.
List<GameLevel> ladderFor(GameId game) => switch (game) {
  GameId.memory => memoryLadder,
  GameId.shape => shapeLadder,
  GameId.attention => attentionLadder,
  GameId.letter => letterLadder,
  GameId.word => wordLadder,
  GameId.math => mathLadder,
  GameId.logic => logicLadder,
};

/// Questions in one round, for every game that climbs a ladder.
const int questionsPerRound = 5;

/// A round counts towards the next rung with at most this many questions
/// answered wrong on the first tap.
///
/// Needed wherever a wrong tap does not end the question: without it a child
/// could tap at random and still climb.
const int maxFirstTryMistakesInCleanRound = 1;

bool isCleanRound(int firstTryMistakes) =>
    firstTryMistakes <= maxFirstTryMistakesInCleanRound;

/// Where a child resumes the ladder when a game opens.
///
/// Age sets the floor and saved progress can only lift it, so the level never
/// visibly goes backwards. Stars belong to the rung they were earned on: they
/// carry over only when the child resumes on that same rung. Before, a parent
/// raising the age moved the child up to a bigger board with the stars from
/// the smaller one, and a single round then skipped another rung.
///
/// The age-derived rung is deliberately not saved here. If a parent corrects
/// a mistyped age downwards, the child should go back to the right board.
({int levelIndex, int roundsCleared}) resumeLadder({
  required List<GameLevel> ladder,
  required int startingLevel,
  required int? savedLevel,
  required int savedRounds,
}) {
  final top = ladder.length - 1;
  final floor = startingLevel.clamp(0, top);
  final saved = savedLevel?.clamp(0, top);

  if (saved == null || saved < floor) {
    return (levelIndex: floor, roundsCleared: 0);
  }

  return (
    levelIndex: saved,
    roundsCleared: savedRounds.clamp(0, ladder[saved].roundsToAdvance),
  );
}

/// Where a ladder stands after a clean round.
///
/// The rule lives here, not inside a game's State, so every game that gets a
/// ladder climbs it the same way and the rule can be tested on its own.
({int levelIndex, int roundsCleared, RoundOutcome outcome}) advanceLadder({
  required List<GameLevel> ladder,
  required int levelIndex,
  required int roundsCleared,
}) {
  final index = levelIndex.clamp(0, ladder.length - 1);
  final needed = ladder[index].roundsToAdvance;
  final cleared = roundsCleared + 1;

  if (cleared < needed) {
    return (
      levelIndex: index,
      roundsCleared: cleared,
      outcome: RoundOutcome.progress,
    );
  }

  // Merdivenin sonu: yildizlar dolu kalir, geri sayim bastan baslamaz.
  if (index >= ladder.length - 1) {
    return (
      levelIndex: index,
      roundsCleared: needed,
      outcome: RoundOutcome.mastered,
    );
  }

  return (
    levelIndex: index + 1,
    roundsCleared: 0,
    outcome: RoundOutcome.levelUp,
  );
}

/// What finishing a clean round meant for the ladder.
///
/// The child is told this with an emoji, a colour and stars before any text,
/// so "you moved up" reads for someone who cannot read yet.
enum RoundOutcome {
  /// Still on the same rung; one more star earned.
  progress,

  /// Enough clean rounds — the next rung just opened.
  levelUp,

  /// Already on the top rung and it is full.
  mastered,

  /// A round that did not count, in a game that grades rounds: nothing
  /// earned, nothing lost. Shown as "one more round", not as a celebration —
  /// otherwise tapping at random would be cheered exactly like careful play.
  /// [advanceLadder] never returns it; the game decides.
  retry,
}
