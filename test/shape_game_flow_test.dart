import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/shape_figure.dart';
import 'package:mini_zeka/games/shape_game.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';

const _targetPrefix = 'Hedef şekil: ';

/// Opens the game on top of a home route, rung and time set through prefs.
Future<void> _open(
  WidgetTester tester, {
  int? savedLevel,
  int childAge = 5,
  int playedSecondsToday = 0,
}) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.childAge: childAge,
    StorageKeys.soundEnabled: false,
    StorageKeys.gameLimitMinutes(GameId.shape): 30,
    StorageKeys.gamePlayedSeconds(
      GameId.shape,
      StorageKeys.isoDate(DateTime.now()),
    ): playedSecondsToday,
    StorageKeys.gameLevel(GameId.shape): ?savedLevel,
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
                  builder: (_) => ShapeGame(random: Random(7)),
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
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

String _targetLabel(WidgetTester tester) {
  final node = tester.getSemantics(
    find.bySemanticsLabel(RegExp('^$_targetPrefix')),
  );
  return node.label.substring(_targetPrefix.length);
}

Finder _correctCard(WidgetTester tester) =>
    find.bySemanticsLabel(_targetLabel(tester));

Finder _wrongCard(WidgetTester tester) {
  final target = _targetLabel(tester);

  for (final kind in ShapeKind.values) {
    if (kind.label == target) continue;
    final finder = find.bySemanticsLabel(kind.label);
    if (finder.evaluate().isNotEmpty) return finder.first;
  }

  throw StateError('no wrong card on the board');
}

String _infoValue(WidgetTester tester, String title) {
  final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^$title: ')));
  return node.label.substring(title.length + 2);
}

/// Taps the matching card and waits for the next question to come in.
Future<void> _answerRight(WidgetTester tester) async {
  await tester.tap(_correctCard(tester));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1000));
  await tester.pump();
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

void main() {
  testWidgets('yanlış dokunuş diyalog açmaz, soru değişmez, kart kilitlenir',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    await _settle(tester);

    final wrong = _wrongCard(tester);
    await tester.tap(wrong);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(Dialog), findsNothing);
    expect(_infoValue(tester, 'Soru'), '1 / 5');

    // Tapping the locked card again changes nothing.
    await tester.tap(wrong, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_infoValue(tester, 'Soru'), '1 / 5');
    expect(find.byType(Dialog), findsNothing);

    semantics.dispose();
  });

  testWidgets('ilk dokunuşta doğru puan verir ve sıradaki soruya geçer',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    await _settle(tester);

    await _answerRight(tester);

    expect(_infoValue(tester, 'Soru'), '2 / 5');
    expect(_infoValue(tester, 'Puan'), '10');

    semantics.dispose();
  });

  testWidgets('hatadan sonra bulunan doğru cevap ilerletir ama puan vermez',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    await _settle(tester);

    await tester.tap(_wrongCard(tester));
    await tester.pump(const Duration(milliseconds: 400));
    await _answerRight(tester);

    expect(_infoValue(tester, 'Soru'), '2 / 5');
    expect(_infoValue(tester, 'Puan'), '0');

    semantics.dispose();
  });

  testWidgets('beş temiz cevap turu kaydeder ve 🎉 gösterir', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    await _settle(tester);

    for (var i = 0; i < 5; i++) {
      await _answerRight(tester);
    }
    await tester.pumpAndSettle();

    expect(find.text('🎉'), findsOneWidget);
    expect((await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.shape)),
        1);

    semantics.dispose();
  });

  testWidgets('ilk dokunuşta iki hata yapılan tur yıldız kazandırmaz',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    await _settle(tester);

    for (var i = 0; i < 5; i++) {
      if (i < 2) {
        await tester.tap(_wrongCard(tester));
        await tester.pump(const Duration(milliseconds: 400));
      }
      await _answerRight(tester);
    }
    await tester.pumpAndSettle();

    expect(find.text('💪'), findsOneWidget);
    expect(find.text('🎉'), findsNothing,
        reason: 'rastgele dokunmak kutlanmamalı');
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(
      (await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.shape)),
      isNull,
    );

    semantics.dispose();
  });

  testWidgets('ilk bölümde iki temiz tur bölüm atlatır ve 🚀 gösterir',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    await _settle(tester);

    for (var i = 0; i < 5; i++) {
      await _answerRight(tester);
    }
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yeni Tur'));
    await _settle(tester);

    for (var i = 0; i < 5; i++) {
      await _answerRight(tester);
    }
    await tester.pumpAndSettle();

    expect(find.text('🚀'), findsOneWidget);
    expect(find.text('Sonraki Bölüm'), findsOneWidget);
    expect((await _prefs()).getInt(StorageKeys.gameLevel(GameId.shape)), 1);

    semantics.dispose();
  });

  testWidgets('bölüm sonunda geri tuşu oyundan çıkarır, ölü tahta bırakmaz',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    await _settle(tester);

    for (var i = 0; i < 5; i++) {
      await _answerRight(tester);
    }
    await tester.pumpAndSettle();
    expect(find.text('🎉'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(ShapeGame), findsNothing);
    expect(find.text('open'), findsOneWidget);

    semantics.dispose();
  });

  group('son doğru cevaptan sonraki kısa beklemede', () {
    /// Answers four questions, then finds the fifth and stops right inside
    /// the pause before the round ends.
    Future<void> reachLastPause(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await _answerRight(tester);
      }
      await tester.tap(_correctCard(tester));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('oyundan çıkılsa da kazanılan yıldız kaydedilir',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await _open(tester);
      await _settle(tester);

      await reachLastPause(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(ShapeGame), findsNothing);
      expect(
        (await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.shape)),
        1,
      );

      semantics.dispose();
    });

    testWidgets('süre dolarsa tur sonu süre uyarısının üstüne açılmaz',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await _open(tester);
      await _settle(tester);

      await reachLastPause(tester);

      // What the clock's tick does when the allowance runs out right now.
      final dynamic state = tester.state(find.byType(ShapeGame));
      state.gameTimer.usedSeconds = state.gameTimer.allowedSeconds;
      state.timeUpDialogShown = true;
      state.showGameTimeUpDialog();
      await tester.pumpAndSettle();

      expect(find.text('Bugünkü Süren Doldu'), findsOneWidget);
      expect(find.text('🎉'), findsNothing);
      expect(
        (await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.shape)),
        1,
      );

      await tester.tap(find.text('Tamam'));
      await tester.pumpAndSettle();
      expect(find.byType(ShapeGame), findsNothing);

      semantics.dispose();
    });

    testWidgets('"?" açılmışsa tur sonundan çıkış yine oyundan çıkarır',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await _open(tester);
      await _settle(tester);

      await reachLastPause(tester);
      await tester.tap(find.byTooltip('Nasıl oynanır?'));
      await tester.pumpAndSettle();

      expect(find.text('🎉'), findsOneWidget);

      await tester.tap(find.text('Oyundan Çık'));
      await tester.pumpAndSettle();

      expect(find.byType(ShapeGame), findsNothing);
      expect(find.text('open'), findsOneWidget);

      semantics.dispose();
    });
  });

  testWidgets('ilk soruda boş beklenince el gösterilir, sonra gösterilmez',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    await _settle(tester);

    expect(find.text('👆'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.text('👆'), findsOneWidget);

    await _answerRight(tester);
    expect(find.text('👆'), findsNothing);

    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(find.text('👆'), findsNothing, reason: 'yalnızca ilk soruda');

    semantics.dispose();
  });

  testWidgets('üst bölümde el gösterimi hiç çıkmaz', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, savedLevel: 2);
    await _settle(tester);

    await tester.pump(const Duration(seconds: 6));
    await tester.pump();

    expect(find.text('👆'), findsNothing);

    semantics.dispose();
  });

  testWidgets('süre bitmişken açılan oyunda uyarı bir kez çıkar, tahta oynanmaz',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, playedSecondsToday: 30 * 60);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bugünkü Süren Doldu'), findsOneWidget);

    // The warning's barrier sits over the board: a tap reaches no card.
    await tester.tapAt(const Offset(206, 800));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bugünkü Süren Doldu'), findsOneWidget);
    // The modal hides the board from semantics, so read the drawn counter.
    expect(find.text('1 / 5'), findsOneWidget);

    semantics.dispose();
  });
}
