import 'dart:math';

/// Card faces for the memory game, grouped by what they can be mistaken for.
///
/// A board used to be filled from one flat list, so 🍎 and 🍓 — two small red
/// round fruit — regularly sat on the same board. At 38pt on a phone a child
/// who remembered "the red one" was then wrong through no fault of their own,
/// and the game punished a memory that had worked.
///
/// One face per group per board. Groups with a single face carry no risk.
///
/// The attention game reads the same groups the other way round: it needs two
/// faces a child could mix up, so its harder rungs draw both the odd one out
/// and the rest of the board from a single group.
const List<List<String>> symbolClusters = [
  ['🍎', '🍓', '🍉', '🍒'], // small red round fruit
  ['⭐', '🌟', '🌞'], // yellow, radiating
  ['🐱', '🐶', '🐼', '🐷'], // animal faces
  ['🚗', '🚕', '🚙', '🚌'], // vehicles
  ['🌸', '🌺', '🌷'], // flowers
  ['⚽', '🏀', '🏐', '🎾'], // balls
  ['🦋'],
  ['🎈'],
  ['🍌'],
  ['🐟'],
  ['🎁'],
  ['🌵'],
  ['🌈'],
];

/// The most pairs a board can ask for.
int get maxSymbolPairs => symbolClusters.length;

/// Picks [pairCount] faces that cannot be mistaken for one another.
///
/// [random] is injected so a board can be reproduced in tests.
List<String> dealPairSymbols({
  required int pairCount,
  required Random random,
}) {
  assert(
    pairCount <= maxSymbolPairs,
    'board asks for $pairCount pairs, only $maxSymbolPairs groups exist',
  );

  final groups = [...symbolClusters]..shuffle(random);

  return [
    for (final group in groups.take(pairCount))
      group[random.nextInt(group.length)],
  ];
}
