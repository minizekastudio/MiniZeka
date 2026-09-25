import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/app_theme.dart';
import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/logic_game.dart';
import 'package:mini_zeka/games/logic_round.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';

const _seed = 11;

List<LogicQuestion> _expectedRound(int rung) =>
    buildLogicRound(rung: rung, random: Random(_seed));

Future<void> _open(
  WidgetTester tester, {
  int rung = 0,
  int playedSecondsToday = 0,
  Size size = const Size(412, 915),
}) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.childAge: 4,
    StorageKeys.soundEnabled: false,
    StorageKeys.gameLimitMinutes(GameId.logic): 30,
    StorageKeys.gamePlayedSeconds(
      GameId.logic,
      StorageKeys.isoDate(DateTime.now()),
    ): playedSecondsToday,
    StorageKeys.gameLevel(GameId.logic): rung,
  });
  await SoundManager.loadSoundSetting();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: LogicGame(random: Random(_seed))),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Finder _optionFinder(String symbol) => find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          w.excludeSemantics &&
          (w.properties.button ?? false) &&
          w.properties.label == symbol,
    );

Future<void> _tapOption(WidgetTester tester, String symbol) async {
  await tester.tap(_optionFinder(symbol).first);
  await tester.pump();
}

Future<void> _answerRight(WidgetTester tester, LogicQuestion question) async {
  await _tapOption(tester, question.answer);
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump();
}

String _wrongOption(LogicQuestion question) =>
    question.options.firstWhere((o) => o != question.answer);

String _infoValue(WidgetTester tester, String title) {
  final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^$title: ')));
  return node.label.substring(title.length + 2);
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

void main() {
  testWidgets('örüntü satırı ve boşluk ekranda, cevap dizideki parçadır',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(0);
    await _open(tester);

    final question = round.first;

    // The gap is shown as a question mark, the rest of the row is drawn.
    expect(find.text('?'), findsOneWidget);
    for (final symbol in question.sequence.toSet()) {
      expect(find.text(symbol), findsWidgets);
    }

    await _answerRight(tester, question);
    expect(_infoValue(tester, 'Soru'), '2 / 5');
    expect(_infoValue(tester, 'Puan'), '10');

    semantics.dispose();
  });

  testWidgets('yanlış şık soruyu bitirmez, kilitlenir, puan vermez',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(0);
    await _open(tester);

    await _tapOption(tester, _wrongOption(round.first));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(Dialog), findsNothing);
    expect(_infoValue(tester, 'Soru'), '1 / 5');

    await _answerRight(tester, round.first);

    expect(_infoValue(tester, 'Soru'), '2 / 5');
    expect(_infoValue(tester, 'Puan'), '0');

    semantics.dispose();
  });

  testWidgets('beş temiz soru turu kaydeder, iki hata kaydetmez',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(0);
    await _open(tester);

    for (final question in round) {
      await _answerRight(tester, question);
    }
    await tester.pumpAndSettle();

    expect(find.text('🎉'), findsOneWidget);
    expect(
      (await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.logic)),
      1,
    );

    semantics.dispose();
  });

  testWidgets('iki soruda ilk dokunuş yanlışsa 💪 gelir', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(0);
    await _open(tester);

    for (var i = 0; i < round.length; i++) {
      if (i < 2) {
        await _tapOption(tester, _wrongOption(round[i]));
        await tester.pump(const Duration(milliseconds: 400));
      }
      await _answerRight(tester, round[i]);
    }
    await tester.pumpAndSettle();

    expect(find.text('💪'), findsOneWidget);
    expect(
      (await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.logic)),
      isNull,
    );

    semantics.dispose();
  });

  testWidgets('üst bölümde boşluk satırın ortasında olur', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(4);
    await _open(tester, rung: 4);

    expect(round.first.isGapAtEnd, isFalse);
    expect(find.text('?'), findsOneWidget);

    await _answerRight(tester, round.first);
    expect(_infoValue(tester, 'Soru'), '2 / 5');

    semantics.dispose();
  });

  group('her bölüm her telefona sığar', () {
    final phones = <String, Size>{
      'dar telefon': const Size(320, 568),
      'orta telefon': const Size(360, 640),
      'geniş telefon': const Size(412, 915),
    };

    for (var rung = 0; rung < logicLadder.length; rung++) {
      for (final phone in phones.entries) {
        testWidgets('bölüm ${rung + 1} ${phone.key}', (tester) async {
          final semantics = tester.ensureSemantics();
          await _open(tester, rung: rung, size: phone.value);

          expect(tester.takeException(), isNull);

          final options = find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.excludeSemantics &&
                (w.properties.button ?? false),
          );

          expect(options, findsNWidgets(logicLadder[rung].cards));

          final screen = Offset.zero & phone.value;

          for (var i = 0; i < logicLadder[rung].cards; i++) {
            final rect = tester.getRect(options.at(i));

            expect(screen.contains(rect.topLeft), isTrue, reason: '$rect');
            expect(
              screen.contains(rect.bottomRight - const Offset(1, 1)),
              isTrue,
              reason: 'şık ekran dışında: $rect',
            );
            expect(rect.shortestSide,
                greaterThanOrEqualTo(Brand.minTouchTarget));
          }

          semantics.dispose();
        });
      }
    }
  });

  testWidgets('süre bitmişken oyun uyarıyla açılır', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, playedSecondsToday: 30 * 60);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bugünkü Süren Doldu'), findsOneWidget);

    semantics.dispose();
  });
}
