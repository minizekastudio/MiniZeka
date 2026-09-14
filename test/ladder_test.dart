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

  group('resumeLadder', () {
    ({int levelIndex, int roundsCleared}) resume({
      required int startingLevel,
      int? savedLevel,
      int savedRounds = 0,
    }) =>
        resumeLadder(
          ladder: memoryLadder,
          startingLevel: startingLevel,
          savedLevel: savedLevel,
          savedRounds: savedRounds,
        );

    test('kayıt yoksa yaşın basamağından sıfır yıldızla başlar', () {
      final r = resume(startingLevel: 2);

      expect(r.levelIndex, 2);
      expect(r.roundsCleared, 0);
    });

    test('seviye asla geri gitmez: kayıt yaştan yüksekse kayıt kazanır', () {
      final r = resume(startingLevel: 0, savedLevel: 3, savedRounds: 2);

      expect(r.levelIndex, 3);
      expect(r.roundsCleared, 2);
    });

    test('yaş kayıttan yüksekse eski basamağın yıldızları taşınmaz', () {
      final r = resume(startingLevel: 2, savedLevel: 0, savedRounds: 1);

      expect(r.levelIndex, 2);
      expect(r.roundsCleared, 0);
    });

    test('aynı basamakta devam edince yıldızlar korunur', () {
      final r = resume(startingLevel: 2, savedLevel: 2, savedRounds: 2);

      expect(r.levelIndex, 2);
      expect(r.roundsCleared, 2);
    });

    test('bozuk kayıt merdivene ve basamağın yıldız sayısına sığdırılır', () {
      final top = memoryLadder.length - 1;
      final r = resume(startingLevel: 0, savedLevel: 99, savedRounds: 50);

      expect(r.levelIndex, top);
      expect(r.roundsCleared, memoryLadder[top].roundsToAdvance);

      final negative = resume(startingLevel: 1, savedLevel: -4, savedRounds: -1);
      expect(negative.levelIndex, 1);
      expect(negative.roundsCleared, 0);
    });
  });
}
