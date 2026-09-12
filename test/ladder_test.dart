import 'package:flutter_test/flutter_test.dart';
import 'package:mini_zeka/difficulty.dart';

void main() {
  group('advanceLadder', () {
    test('ayni bolumde kalinca bir yildiz eklenir', () {
      final next = advanceLadder(
        ladder: memoryLadder,
        levelIndex: 1,
        roundsCleared: 0,
      );

      expect(next.outcome, RoundOutcome.progress);
      expect(next.levelIndex, 1);
      expect(next.roundsCleared, 1);
    });

    test('gereken tur dolunca bir ust bolum acilir ve yildizlar sifirlanir',
        () {
      final level = memoryLadder[1];
      final next = advanceLadder(
        ladder: memoryLadder,
        levelIndex: 1,
        roundsCleared: level.roundsToAdvance - 1,
      );

      expect(next.outcome, RoundOutcome.levelUp);
      expect(next.levelIndex, 2);
      expect(next.roundsCleared, 0);
    });

    test('son bolumde seviye artmaz, yildizlar dolu kalir', () {
      final last = memoryLadder.length - 1;
      final next = advanceLadder(
        ladder: memoryLadder,
        levelIndex: last,
        roundsCleared: memoryLadder[last].roundsToAdvance - 1,
      );

      expect(next.outcome, RoundOutcome.mastered);
      expect(next.levelIndex, last);
      expect(next.roundsCleared, memoryLadder[last].roundsToAdvance);
    });

    test('son bolumde tekrar bitirince yine mastered doner', () {
      final last = memoryLadder.length - 1;
      final next = advanceLadder(
        ladder: memoryLadder,
        levelIndex: last,
        roundsCleared: memoryLadder[last].roundsToAdvance,
      );

      expect(next.outcome, RoundOutcome.mastered);
      expect(next.roundsCleared, memoryLadder[last].roundsToAdvance);
    });

    test('bozuk kayitli seviye merdivene sigdirilir', () {
      final next = advanceLadder(
        ladder: memoryLadder,
        levelIndex: 99,
        roundsCleared: 0,
      );

      expect(next.levelIndex, memoryLadder.length - 1);
    });

    test('merdiven bastan sona tirmanilinca kart sayisi hep artar', () {
      var levelIndex = 0;
      var roundsCleared = 0;
      final seen = <int>[memoryLadder[0].cards];

      // En fazla makul sayida tur oyna; merdiven tepeye varmali.
      for (var round = 0; round < 40; round++) {
        final next = advanceLadder(
          ladder: memoryLadder,
          levelIndex: levelIndex,
          roundsCleared: roundsCleared,
        );

        levelIndex = next.levelIndex;
        roundsCleared = next.roundsCleared;

        if (next.outcome == RoundOutcome.levelUp) {
          seen.add(memoryLadder[levelIndex].cards);
        }
      }

      expect(levelIndex, memoryLadder.length - 1);
      expect(seen, [4, 6, 8, 12, 16, 20]);
    });
  });
}
