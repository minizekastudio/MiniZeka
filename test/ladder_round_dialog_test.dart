import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/game_kit.dart';

Future<void> _show(
  WidgetTester tester, {
  required RoundOutcome outcome,
  required int levelIndex,
  required int roundsCleared,
  VoidCallback? onNextRound,
}) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showLadderRoundDialog(
              context: context,
              palette: GamePalette.memory,
              outcome: outcome,
              ladder: memoryLadder,
              levelIndex: levelIndex,
              roundsCleared: roundsCleared,
              levelUpMessage: 'yeni bölüm mesajı',
              masteredMessage: 'son bölüm mesajı',
              flair: '✨',
              results: const [
                GameResultBox(
                  palette: GamePalette.memory,
                  emoji: '⭐',
                  title: 'Puan',
                  value: '120',
                ),
                GameResultBox(
                  palette: GamePalette.memory,
                  emoji: '⏱️',
                  title: 'Süre',
                  value: '10:05',
                ),
              ],
              onNextRound: onNextRound ?? () {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('bölüm sonu diyaloğu', () {
    testWidgets('aynı bölümde kalınca yıldız ve kalan tur gösterir',
        (tester) async {
      await _show(
        tester,
        outcome: RoundOutcome.progress,
        levelIndex: 1,
        roundsCleared: 1,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('🎉'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(2));
      expect(find.text('Yeni bölüme 2 tur kaldı! ✨'), findsOneWidget);
      expect(find.text('Yeni Tur'), findsOneWidget);
    });

    testWidgets('bölüm atlayınca eski ve yeni bölümü gösterir, tekrar oyna demez',
        (tester) async {
      var nextRounds = 0;

      await _show(
        tester,
        outcome: RoundOutcome.levelUp,
        levelIndex: 2,
        roundsCleared: 0,
        onNextRound: () => nextRounds++,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('🚀'), findsOneWidget);
      expect(find.text('2. Bölüm'), findsOneWidget);
      expect(find.text('3. Bölüm'), findsOneWidget);
      expect(find.text('Sonraki Bölüm'), findsOneWidget);
      expect(find.textContaining('Tekrar'), findsNothing);

      await tester.tap(find.text('Sonraki Bölüm'));
      await tester.pumpAndSettle();

      expect(nextRounds, 1);
      expect(find.text('🚀'), findsNothing);
    });

    testWidgets('son bölümde kupa gösterir', (tester) async {
      final top = memoryLadder.length - 1;

      await _show(
        tester,
        outcome: RoundOutcome.mastered,
        levelIndex: top,
        roundsCleared: memoryLadder[top].roundsToAdvance,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('🏆'), findsOneWidget);
      expect(find.text('son bölüm mesajı'), findsOneWidget);
    });
  });
}
