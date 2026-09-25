import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/math_game.dart';
import 'package:mini_zeka/games/math_round.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';

const _seed = 6;

/// The round the screen will build, so a test knows the right answers.
List<MathQuestion> _expectedRound(int rung) =>
    buildMathRound(rung: rung, random: Random(_seed));

Future<void> _open(
  WidgetTester tester, {
  int rung = 0,
  int playedSecondsToday = 0,
}) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.childAge: 4,
    StorageKeys.soundEnabled: false,
    StorageKeys.gameLimitMinutes(GameId.math): 30,
    StorageKeys.gamePlayedSeconds(
      GameId.math,
      StorageKeys.isoDate(DateTime.now()),
    ): playedSecondsToday,
    StorageKeys.gameLevel(GameId.math): rung,
  });
  await SoundManager.loadSoundSetting();

  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: MathGame(random: Random(_seed))),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _tapValue(WidgetTester tester, int value) async {
  await tester.tap(find.bySemanticsLabel('$value').first);
  await tester.pump();
}

/// Answers correctly and waits for the next question.
Future<void> _answerRight(WidgetTester tester, MathQuestion question) async {
  await _tapValue(tester, question.answer);
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump();
}

int _wrongValue(MathQuestion question) =>
    question.options.firstWhere((o) => o != question.answer);

String _infoValue(WidgetTester tester, String title) {
  final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^$title: ')));
  return node.label.substring(title.length + 2);
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

void main() {
  testWidgets('yanlış şık soruyu bitirmez, kilitlenir, puan vermez',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(0);
    await _open(tester);

    expect(_infoValue(tester, 'Soru'), '1 / 5');

    await _tapValue(tester, _wrongValue(round.first));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(Dialog), findsNothing);
    expect(_infoValue(tester, 'Soru'), '1 / 5', reason: 'soru durmalı');

    await _answerRight(tester, round.first);

    expect(_infoValue(tester, 'Soru'), '2 / 5');
    expect(_infoValue(tester, 'Puan'), '0');

    semantics.dispose();
  });

  testWidgets('ilk denemede doğru puan verir ve ilerler', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(0);
    await _open(tester);

    await _answerRight(tester, round.first);

    expect(_infoValue(tester, 'Soru'), '2 / 5');
    expect(_infoValue(tester, 'Puan'), '10');

    semantics.dispose();
  });

  testWidgets('ilk bölümde sayılacak nesneler görünür', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(0);
    await _open(tester);

    final question = round.first;
    expect(question.hasObjects, isTrue);
    expect(find.text(question.object), findsNWidgets(question.left));
    expect(find.text('?'), findsOneWidget, reason: 'sayma sorusu');

    semantics.dispose();
  });

  testWidgets('üst bölümde nesne yok, iki yanlıştan sonra ipucu olarak gelir',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(4);
    await _open(tester, rung: 4);

    final question = round.first;
    expect(question.hasObjects, isFalse);
    expect(find.text(question.object), findsNothing);
    expect(
      find.text('${question.left} + ${question.right} = ?'),
      findsOneWidget,
    );

    final wrong = question.options.where((o) => o != question.answer).toList();
    await _tapValue(tester, wrong[0]);
    await tester.pump(const Duration(milliseconds: 400));
    await _tapValue(tester, wrong[1]);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(question.object), findsNWidgets(question.answer),
        reason: 'takılan çocuk sayabilsin');

    semantics.dispose();
  });

  testWidgets('çıkarma bölümünde giden nesneler üstü çizili gösterilir',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(3);
    await _open(tester, rung: 3);

    final question = round.first;
    expect(question.task, MathTask.subtract);
    expect(find.text(question.object), findsNWidgets(question.left));
    expect(find.byIcon(Icons.close_rounded), findsNWidgets(question.right));

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
      (await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.math)),
      1,
    );

    semantics.dispose();
  });

  testWidgets('iki soruda ilk dokunuş yanlışsa tur sayılmaz', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(0);
    await _open(tester);

    for (var i = 0; i < round.length; i++) {
      if (i < 2) {
        await _tapValue(tester, _wrongValue(round[i]));
        await tester.pump(const Duration(milliseconds: 400));
      }
      await _answerRight(tester, round[i]);
    }
    await tester.pumpAndSettle();

    expect(find.text('💪'), findsOneWidget);
    expect(find.text('🎉'), findsNothing);
    expect(
      (await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.math)),
      isNull,
    );

    semantics.dispose();
  });

  testWidgets('süre bitmişken oyun uyarıyla açılır', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, playedSecondsToday: 30 * 60);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bugünkü Süren Doldu'), findsOneWidget);

    semantics.dispose();
  });
}
