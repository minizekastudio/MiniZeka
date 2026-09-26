import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/game_kit.dart';

const _ladder = [
  GameLevel(cards: 4, roundsToAdvance: 2),
  GameLevel(cards: 6, roundsToAdvance: 3),
  GameLevel(cards: 8, roundsToAdvance: 3),
];

/// Opens the celebration and records whether the next round was started.
Future<List<bool>> _show(
  WidgetTester tester, {
  required RoundOutcome outcome,
  int levelIndex = 1,
  int roundsCleared = 1,
  int seed = 4,
  Size phone = const Size(360, 640),
}) async {
  final started = <bool>[];

  tester.view.physicalSize = phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showRoundCelebration(
              context: context,
              palette: GameId.memory.palette,
              outcome: outcome,
              ladder: _ladder,
              levelIndex: levelIndex,
              roundsCleared: roundsCleared,
              levelUpMessage: 'Artık daha çok kart! 🧠',
              masteredMessage: 'Hepsini bitirdin! ✨',
              random: Random(seed),
              onNextRound: () => started.add(true),
            ),
            child: const Text('bitir'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('bitir'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  return started;
}

void main() {
  testWidgets('kutlama dokunuş beklemeden kendi kapanır ve turu başlatır', (
    tester,
  ) async {
    // The old screen stopped to ask a four year old to confirm that yes,
    // they would like to keep playing.
    final started = await _show(tester, outcome: RoundOutcome.progress);

    expect(find.text('🎉'), findsOneWidget);
    expect(started, isEmpty, reason: 'kutlama sürerken tur başlamaz');

    await tester.pumpAndSettle();

    expect(find.text('🎉'), findsNothing);
    expect(started, [true]);
  });

  testWidgets('hiçbir düğme yok', (tester) async {
    await _show(tester, outcome: RoundOutcome.progress);

    expect(find.text('Yeni Tur'), findsNothing);
    expect(find.text('Sonraki Bölüm'), findsNothing);
    expect(find.text('Oyundan Çık'), findsNothing);

    await tester.pumpAndSettle();
  });

  testWidgets('övgü rastgele, ama tohum sabitse aynı', (tester) async {
    final first = await _show(tester, outcome: RoundOutcome.progress, seed: 1);
    final shown = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    await tester.pumpAndSettle();
    expect(first, [true]);

    final praise = shown.firstWhere(
      (text) => text != null && text.endsWith('!'),
      orElse: () => null,
    );
    expect(praise, isNotNull, reason: 'bir övgü sözü çıkmalı');

    await _show(tester, outcome: RoundOutcome.progress, seed: 1);
    expect(find.text(praise!), findsOneWidget);
    await tester.pumpAndSettle();

    // A different seed is free to say something else; what matters is that
    // it is drawn rather than always the same word.
    final words = <String?>{};
    for (var seed = 0; seed < 12; seed++) {
      await _show(tester, outcome: RoundOutcome.progress, seed: seed);
      words.addAll(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .where((text) => text != null && text.endsWith('!')),
      );
      await tester.pumpAndSettle();
    }

    expect(words.length, greaterThan(1), reason: 'hep aynı söz gelmemeli');
  });

  testWidgets('bölüm atlayınca roket ve yeni bölüm rozeti', (tester) async {
    await _show(tester, outcome: RoundOutcome.levelUp, levelIndex: 2);

    expect(find.text('🚀'), findsOneWidget);
    expect(find.text('Artık daha çok kart! 🧠'), findsOneWidget);
    expect(find.text('2. Bölüm'), findsOneWidget);
    expect(find.text('3. Bölüm'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('kutlama yazısı Material altında', (tester) async {
    await _show(tester, outcome: RoundOutcome.levelUp, levelIndex: 2);

    final note = find.text('Artık daha çok kart! 🧠');
    expect(note, findsOneWidget);

    // The celebration is a route of its own, so it does not inherit the
    // game screen's Material. Text without one is drawn in a fallback font
    // under a yellow double underline — only the device showed it.
    expect(
      find.ancestor(of: note, matching: find.byType(Material)),
      findsWidgets,
    );

    await tester.pumpAndSettle();
  });

  testWidgets('merdiven bitince kupa', (tester) async {
    await _show(tester, outcome: RoundOutcome.mastered, levelIndex: 2);

    expect(find.text('🏆'), findsOneWidget);
    expect(find.text('Hepsini bitirdin! ✨'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('temiz olmayan tur kutlanmaz ama yine de devam eder', (
    tester,
  ) async {
    // Encouragement, never a scolding: the round still ends and the child
    // still moves on, just without the fireworks.
    final started = await _show(tester, outcome: RoundOutcome.retry);

    expect(find.text('💪'), findsOneWidget);
    expect(find.text('🎉'), findsNothing);

    await tester.pumpAndSettle();
    expect(started, [true]);
  });

  group('her sonuç her telefona sığar', () {
    final phones = <String, Size>{
      'dar telefon': const Size(320, 568),
      'orta telefon': const Size(360, 640),
    };

    for (final outcome in RoundOutcome.values) {
      for (final phone in phones.entries) {
        testWidgets('${outcome.name} ${phone.key}', (tester) async {
          await _show(
            tester,
            outcome: outcome,
            levelIndex: 2,
            phone: phone.value,
          );
          await tester.pump(const Duration(milliseconds: 900));

          expect(tester.takeException(), isNull);

          await tester.pumpAndSettle();
        });
      }
    }
  });
}
