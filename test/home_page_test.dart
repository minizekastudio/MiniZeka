import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/home_page.dart';
import 'package:mini_zeka/storage_keys.dart';

Future<void> _open(
  WidgetTester tester, {
  Map<GameId, bool> enabled = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.childAge: 6,
    for (final entry in enabled.entries)
      StorageKeys.gameEnabled(entry.key): entry.value,
  });

  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: HomePage(
        onAchievementsTap: () {},
        onMemoryTap: () {},
        onAttentionTap: () {},
        onMathTap: () {},
        onShapeTap: () {},
        onLogicTap: () {},
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('bütün oyunlar açıkken ekran çizilir', (tester) async {
    // The card entrance animations were seven hand-written fields indexed by
    // card position; the eighth game turned the home screen red.
    await _open(tester);

    expect(tester.takeException(), isNull);

    for (final game in GameId.values) {
      expect(find.text(game.shortTitle), findsOneWidget, reason: game.title);
    }
  });

  testWidgets('kapatılan oyun karttan düşer', (tester) async {
    await _open(tester, enabled: {GameId.logic: false});

    expect(tester.takeException(), isNull);
    expect(find.text(GameId.logic.shortTitle), findsNothing);
    expect(find.text(GameId.memory.shortTitle), findsOneWidget);
  });

  testWidgets('hepsi kapalıyken çocuk boş ekranla kalmaz', (tester) async {
    await _open(
      tester,
      enabled: {for (final game in GameId.values) game: false},
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Şimdilik oyun yok'), findsOneWidget);
  });
}
