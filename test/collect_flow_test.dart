import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/collect_game.dart';
import 'package:mini_zeka/games/collect_round.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';

const _seed = 3;

CollectWorld _expectedBoard(int rung) =>
    buildCollectBoard(rung: rung, random: Random(_seed));

Future<void> _open(
  WidgetTester tester, {
  int rung = 0,
  int playedSecondsToday = 0,
  Size size = const Size(412, 915),
}) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.childAge: 4,
    StorageKeys.soundEnabled: false,
    StorageKeys.gameLimitMinutes(GameId.collect): 30,
    StorageKeys.gamePlayedSeconds(
      GameId.collect,
      StorageKeys.isoDate(DateTime.now()),
    ): playedSecondsToday,
    StorageKeys.gameLevel(GameId.collect): rung,
  });
  await SoundManager.loadSoundSetting();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: CollectGame(random: Random(_seed))),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Rect _board(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey('collect-board')));

/// Steers to a board point and lets the squirrel walk there.
Future<void> _walkTo(
  WidgetTester tester,
  BoardPoint point, {
  int frames = 130,
}) async {
  final board = _board(tester);

  await tester.tapAt(
    Offset(
      board.left + point.x * board.width,
      board.top + point.y * board.height,
    ),
  );

  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

String _infoValue(WidgetTester tester, String title) {
  final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^$title: ')));
  return node.label.substring(title.length + 2);
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

void main() {
  testWidgets('tahta ve toplanacak yüz ekranda', (tester) async {
    final semantics = tester.ensureSemantics();
    final world = _expectedBoard(0);
    await _open(tester);

    expect(find.byKey(const ValueKey('collect-board')), findsOneWidget);
    expect(
      find.bySemanticsLabel('Toplanacak: ${world.targetFace}'),
      findsOneWidget,
    );
    expect(_infoValue(tester, 'Toplanan'), '0 / ${world.targetTotal}');

    semantics.dispose();
  });

  testWidgets('tahta kare ve ekranın içinde', (tester) async {
    await _open(tester);

    final board = _board(tester);
    const screen = Rect.fromLTWH(0, 0, 412, 915);

    expect(board.width, closeTo(board.height, 0.5));
    expect(screen.contains(board.topLeft), isTrue);
    expect(screen.contains(board.bottomRight - const Offset(1, 1)), isTrue);
  });

  testWidgets('doğru yüze gidince toplanır ve puan artar', (tester) async {
    final semantics = tester.ensureSemantics();
    final world = _expectedBoard(0);
    await _open(tester);

    final target = world.items.firstWhere(
      (item) => item.face == world.targetFace,
    );

    await _walkTo(tester, target.position);

    expect(_infoValue(tester, 'Puan'), isNot('0'));
    expect(_infoValue(tester, 'Toplanan'), isNot('0 / ${world.targetTotal}'));

    semantics.dispose();
  });

  testWidgets('bütün yüzler toplanınca tur kaydedilir', (tester) async {
    final world = _expectedBoard(0);
    await _open(tester);

    for (final item in world.items) {
      if (item.face != world.targetFace) continue;
      await _walkTo(tester, item.position);
    }
    await tester.pumpAndSettle();

    expect(find.text('🎉'), findsOneWidget);
    expect(
      (await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.collect)),
      1,
    );
  });

  group('her bölüm her telefona sığar', () {
    final phones = <String, Size>{
      'dar telefon': const Size(320, 568),
      'orta telefon': const Size(360, 640),
      'geniş telefon': const Size(412, 915),
    };

    for (var rung = 0; rung < collectLadder.length; rung++) {
      for (final phone in phones.entries) {
        testWidgets('bölüm ${rung + 1} ${phone.key}', (tester) async {
          await _open(tester, rung: rung, size: phone.value);

          expect(tester.takeException(), isNull);

          final board = _board(tester);
          final screen = Offset.zero & phone.value;

          expect(screen.contains(board.topLeft), isTrue, reason: '$board');
          expect(
            screen.contains(board.bottomRight - const Offset(1, 1)),
            isTrue,
            reason: 'tahta ekran dışında: $board',
          );
          expect(
            board.width,
            greaterThanOrEqualTo(240),
            reason: 'tahta çok küçük: $board',
          );
        });
      }
    }
  });

  testWidgets('süre bitmişken oyun uyarıyla açılır', (tester) async {
    await _open(tester, playedSecondsToday: 30 * 60);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bugünkü Süren Doldu'), findsOneWidget);
  });
}
