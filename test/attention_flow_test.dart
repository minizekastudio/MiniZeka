import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/attention_game.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';

Future<void> _open(
  WidgetTester tester, {
  int? savedLevel,
  int playedSecondsToday = 0,
}) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.childAge: 4,
    StorageKeys.soundEnabled: false,
    StorageKeys.gameLimitMinutes(GameId.attention): 30,
    StorageKeys.gamePlayedSeconds(
      GameId.attention,
      StorageKeys.isoDate(DateTime.now()),
    ): playedSecondsToday,
    StorageKeys.gameLevel(GameId.attention): ?savedLevel,
  });
  await SoundManager.loadSoundSetting();

  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttentionGame(random: Random(5)),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Every box's face, in order.
List<String> _faces(WidgetTester tester) => tester
    .widgetList<Semantics>(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.excludeSemantics &&
            (w.properties.button ?? false),
      ),
    )
    .map((s) => s.properties.label ?? '')
    .toList();

/// The odd one out is the only face on the board that shows up once.
String _oddFace(WidgetTester tester) {
  final counts = <String, int>{};
  for (final face in _faces(tester)) {
    counts[face] = (counts[face] ?? 0) + 1;
  }

  return counts.entries.singleWhere((e) => e.value == 1).key;
}

String _commonFace(WidgetTester tester) {
  final odd = _oddFace(tester);
  return _faces(tester).firstWhere((face) => face != odd);
}

Future<void> _tapFace(WidgetTester tester, String face) async {
  await tester.tap(find.bySemanticsLabel(face).first);
  await tester.pump();
}

/// Finds the odd one out and waits for the next board.
Future<void> _answerRight(WidgetTester tester) async {
  await _tapFace(tester, _oddFace(tester));
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump();
}

String _infoValue(WidgetTester tester, String title) {
  final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^$title: ')));
  return node.label.substring(title.length + 2);
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

void main() {
  testWidgets('yanlış dokunuş tahtayı bitirmez, kutu kilitlenir',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);

    expect(_infoValue(tester, 'Soru'), '1 / 5');

    await _tapFace(tester, _commonFace(tester));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(Dialog), findsNothing);
    expect(_infoValue(tester, 'Soru'), '1 / 5', reason: 'tahta durmalı');

    // The board is still there and the odd one out still works.
    await _answerRight(tester);
    expect(_infoValue(tester, 'Soru'), '2 / 5');
    expect(_infoValue(tester, 'Puan'), '0', reason: 'hatadan sonra puan yok');

    semantics.dispose();
  });

  testWidgets('ilk dokunuşta doğru puan verir ve sıradaki tahtaya geçer',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);

    await _answerRight(tester);

    expect(_infoValue(tester, 'Soru'), '2 / 5');
    expect(_infoValue(tester, 'Puan'), '10');

    semantics.dispose();
  });

  testWidgets('beş temiz tahta turu kaydeder ve 🎉 gösterir', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);

    for (var i = 0; i < 5; i++) {
      await _answerRight(tester);
    }
    await tester.pumpAndSettle();

    expect(find.text('🎉'), findsOneWidget);
    expect(
      (await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.attention)),
      1,
    );

    semantics.dispose();
  });

  testWidgets('iki tahtada ilk dokunuş yanlışsa tur sayılmaz', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);

    for (var i = 0; i < 5; i++) {
      if (i < 2) {
        await _tapFace(tester, _commonFace(tester));
        await tester.pump(const Duration(milliseconds: 400));
      }
      await _answerRight(tester);
    }
    await tester.pumpAndSettle();

    expect(find.text('💪'), findsOneWidget);
    expect(find.text('🎉'), findsNothing);
    expect(
      (await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.attention)),
      isNull,
    );

    semantics.dispose();
  });

  testWidgets('ilk bölümde iki temiz tur bölüm atlatır', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);

    for (var i = 0; i < 5; i++) {
      await _answerRight(tester);
    }
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yeni Tur'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    for (var i = 0; i < 5; i++) {
      await _answerRight(tester);
    }
    await tester.pumpAndSettle();

    expect(find.text('🚀'), findsOneWidget);
    expect((await _prefs()).getInt(StorageKeys.gameLevel(GameId.attention)), 1);

    semantics.dispose();
  });

  testWidgets('ilk tahtada boş beklenince el gösterilir, sonra gösterilmez',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);

    expect(find.text('👆'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.text('👆'), findsOneWidget);

    await _answerRight(tester);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();

    expect(find.text('👆'), findsNothing, reason: 'yalnızca ilk tahtada');

    semantics.dispose();
  });

  testWidgets('süre bitmişken oyun uyarıyla açılır, tahta oynanmaz',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, playedSecondsToday: 30 * 60);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bugünkü Süren Doldu'), findsOneWidget);
    expect(find.text('1 / 5'), findsOneWidget);

    semantics.dispose();
  });
}
