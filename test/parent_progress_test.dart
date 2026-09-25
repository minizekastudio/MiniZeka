import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/parent_panel.dart';
import 'package:mini_zeka/storage_keys.dart';

Future<void> _open(
  WidgetTester tester, {
  int childAge = 9,
  Map<GameId, (int level, int rounds)> progress = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.childAge: childAge,
    for (final entry in progress.entries) ...{
      StorageKeys.gameLevel(entry.key): entry.value.$1,
      StorageKeys.gameRoundsCleared(entry.key): entry.value.$2,
    },
  });

  tester.view.physicalSize = const Size(412, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: ParentPanel()));
  await tester.pumpAndSettle();
}

Future<void> _scrollToProgressCard(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('🪜 Bölüm İlerlemesi'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

void main() {
  test('her oyunun bir merdiveni var', () {
    // The switch is exhaustive, so this mostly guards the wiring: a ladder
    // pointing at the wrong game would be silent otherwise.
    for (final game in GameId.values) {
      expect(ladderFor(game), isNotEmpty);
      expect(ladderFor(game), hasLength(6));
    }

    expect(ladderFor(GameId.memory).last.cards, 20);
    expect(ladderFor(GameId.attention).last.cards, 16);
  });

  testWidgets('panel her oyunun bölümünü gösterir', (tester) async {
    await _open(tester, childAge: 4, progress: {GameId.memory: (3, 2)});
    await _scrollToProgressCard(tester);

    // The saved rung wins over the age floor; the others sit on the floor.
    expect(find.text('4. Bölüm'), findsOneWidget);
    expect(find.text('1. Bölüm'), findsNWidgets(GameId.values.length - 1));
  });

  testWidgets('hiç oynanmamış oyunun sıfırlama düğmesi kapalı', (tester) async {
    await _open(tester, progress: {GameId.memory: (2, 1)});
    await _scrollToProgressCard(tester);

    IconButton button(GameId game) => tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('${game.title} ilerlemesini sıfırla'),
        matching: find.byType(IconButton),
      ),
    );

    expect(button(GameId.memory).onPressed, isNotNull);
    expect(button(GameId.logic).onPressed, isNull);
  });

  testWidgets('tek oyunu sıfırlamak yalnızca onu siler', (tester) async {
    await _open(
      tester,
      childAge: 4,
      progress: {GameId.memory: (3, 2), GameId.math: (2, 1)},
    );
    await _scrollToProgressCard(tester);

    await tester.tap(
      find.byTooltip('${GameId.memory.title} ilerlemesini sıfırla'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sıfırla'));
    await tester.pumpAndSettle();

    final prefs = await _prefs();

    expect(prefs.getInt(StorageKeys.gameLevel(GameId.memory)), isNull);
    expect(prefs.getInt(StorageKeys.gameRoundsCleared(GameId.memory)), isNull);
    expect(prefs.getInt(StorageKeys.gameLevel(GameId.math)), 2);
  });

  testWidgets('vazgeçilen sıfırlama hiçbir şey silmez', (tester) async {
    await _open(tester, progress: {GameId.memory: (3, 2)});
    await _scrollToProgressCard(tester);

    await tester.tap(
      find.byTooltip('${GameId.memory.title} ilerlemesini sıfırla'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    expect((await _prefs()).getInt(StorageKeys.gameLevel(GameId.memory)), 3);
  });

  testWidgets('tümünü sıfırlamak yedi oyunu da siler', (tester) async {
    await _open(
      tester,
      progress: {for (final game in GameId.values) game: (4, 1)},
    );
    await _scrollToProgressCard(tester);

    await tester.tap(find.text('Tüm ilerlemeyi sıfırla'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sıfırla'));
    await tester.pumpAndSettle();

    final prefs = await _prefs();

    for (final game in GameId.values) {
      expect(
        prefs.getInt(StorageKeys.gameLevel(game)),
        isNull,
        reason: game.title,
      );
    }
  });

  testWidgets('yaş düşünce mahsur kalan oyunlar için sıfırlama önerilir', (
    tester,
  ) async {
    // The trap: the age is only a floor, so lowering it on its own leaves a
    // four year old on the rung a mis-typed age put them on.
    await _open(
      tester,
      childAge: 10,
      progress: {GameId.memory: (5, 1), GameId.word: (4, 0)},
    );

    await tester.tap(find.text('👧 Çocuk Yaşı'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🧸 4 – 5 Yaş'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Kayıtlı bölümler daha yukarıda'), findsOneWidget);

    await tester.tap(find.text('Sıfırla'));
    await tester.pumpAndSettle();

    final prefs = await _prefs();

    expect(prefs.getInt(StorageKeys.gameLevel(GameId.memory)), isNull);
    expect(prefs.getInt(StorageKeys.gameLevel(GameId.word)), isNull);
  });
}
