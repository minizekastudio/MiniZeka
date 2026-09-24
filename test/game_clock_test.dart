import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/game_kit.dart';
import 'package:mini_zeka/games/memory_game.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';

const _limitMinutes = 10;

/// Opens the memory game on top of a plain home route, the way the app does,
/// so tests can see whether the game screen itself gets popped.
Future<void> _openMemoryGame(
  WidgetTester tester, {
  int playedSecondsToday = 0,
}) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.childAge: 5,
    // Keeps the audio plugin out of the test; SoundManager returns early.
    StorageKeys.soundEnabled: false,
    StorageKeys.gameLimitMinutes(GameId.memory): _limitMinutes,
    StorageKeys.gamePlayedSeconds(
      GameId.memory,
      StorageKeys.isoDate(DateTime.now()),
    ): playedSecondsToday,
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
                MaterialPageRoute(builder: (_) => const MemoryGame()),
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

GameSessionMixin _session(WidgetTester tester) =>
    tester.state(find.byType(MemoryGame)) as GameSessionMixin;

void main() {
  group('günlük saat yalnızca oynanırken işler', () {
    testWidgets('üstüne diyalog açılınca durur, kapanınca devam eder',
        (tester) async {
      await _openMemoryGame(tester);
      await tester.pump(const Duration(milliseconds: 500));

      final timer = _session(tester).gameTimer;
      expect(timer.isRunning, isTrue);

      await tester.tap(find.byTooltip('Nasıl oynanır?'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(timer.isRunning, isFalse);

      final usedWhileCovered = timer.usedSeconds;
      await tester.pump(const Duration(seconds: 5));
      expect(timer.usedSeconds, usedWhileCovered);

      await tester.tap(find.text('Anladım'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(timer.isRunning, isTrue);

      await tester.pump(const Duration(seconds: 2));
      expect(timer.usedSeconds, greaterThan(usedWhileCovered));
    });

    testWidgets('uygulama arka plana geçince durur, öne gelince devam eder',
        (tester) async {
      await _openMemoryGame(tester);
      await tester.pump(const Duration(milliseconds: 500));

      final timer = _session(tester).gameTimer;
      expect(timer.isRunning, isTrue);

      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(timer.isRunning, isFalse);

      final usedInBackground = timer.usedSeconds;
      await tester.pump(const Duration(seconds: 5));
      expect(timer.usedSeconds, usedInBackground);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(timer.isRunning, isFalse, reason: 'henüz öne gelmedi');

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(timer.isRunning, isTrue);
    });
  });

  group('süre bitince çocuk ölü ekranda kalmaz', () {
    testWidgets('süre doldu diyaloğundan geri tuşu oyundan da çıkarır',
        (tester) async {
      await _openMemoryGame(
        tester,
        playedSecondsToday: _limitMinutes * 60,
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Bugünkü Süren Doldu'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(MemoryGame), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('süre bitmişken dokunuş uyarıyı geri getirir, çift açmaz',
        (tester) async {
      await _openMemoryGame(
        tester,
        playedSecondsToday: _limitMinutes * 60,
      );

      final session = _session(tester);
      expect(session.gameTimer.timeIsOver, isTrue);

      // Before the screen's own delayed warning fires.
      expect(session.ensurePlayTimeLeft(), isFalse);
      await tester.pump();
      expect(find.text('Bugünkü Süren Doldu'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Bugünkü Süren Doldu'), findsOneWidget);
    });
  });

  testWidgets('kartlar dönmeyi beklerken tahta yenilenirse çökmez',
      (tester) async {
    final cardCount = memoryLadder[0].cards;

    Future<void> settleFlip() async {
      // Frames: start the flip, finish it, drop the old face.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
    }

    await _openMemoryGame(tester);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('?').at(0));
    await tester.pump();
    await tester.tap(find.text('?').at(1));
    await settleFlip();

    // Both cards are face up and still inside the wait, even for a match.
    expect(find.text('?'), findsNWidgets(cardCount - 2));
    expect(250 < matchHold.inMilliseconds, isTrue);

    // Deal a new board underneath the pair being checked, the way the round
    // dialog's "Yeni Tur" does.
    final dynamic state = tester.state(find.byType(MemoryGame));
    // ignore: invalid_use_of_protected_member
    state.setState(state.startGame);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('?'), findsNWidgets(cardCount));

    // The new board takes taps.
    await tester.tap(find.text('?').at(0));
    await settleFlip();
    expect(find.text('?'), findsNWidgets(cardCount - 1));
  });

  group('kartların açık kalma süresi', () {
    test('küçük çocuk hiçbir zaman daha büyüğünden kısa süre görmez', () {
      final holds = AgeBand.values.map(mismatchHoldFor).toList();

      for (var i = 1; i < holds.length; i++) {
        expect(holds[i] <= holds[i - 1], isTrue,
            reason: '${AgeBand.values[i]} ${AgeBand.values[i - 1]}');
      }
    });

    test('en büyük yaş eskisinden yavaş değil, en küçük belirgin uzun', () {
      const previous = Duration(milliseconds: 550);

      expect(mismatchHoldFor(AgeBand.older) <= previous, isTrue);
      expect(mismatchHoldFor(AgeBand.preschool) >= previous * 2, isTrue);
    });

    test('doğru eşleşme yanlıştan uzun bekletmez', () {
      for (final band in AgeBand.values) {
        expect(matchHold < mismatchHoldFor(band), isTrue);
      }
    });
  });
}
