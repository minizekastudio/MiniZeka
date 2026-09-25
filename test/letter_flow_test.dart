import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/app_theme.dart';
import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/letter_round.dart';
import 'package:mini_zeka/letter_game.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';

const _seed = 9;

List<LetterQuestion> _expectedRound(int rung) =>
    buildLetterRound(rung: rung, random: Random(_seed));

Future<void> _open(
  WidgetTester tester, {
  int rung = 0,
  int playedSecondsToday = 0,
  Size size = const Size(412, 915),
}) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.childAge: 4,
    StorageKeys.soundEnabled: false,
    StorageKeys.gameLimitMinutes(GameId.letter): 30,
    StorageKeys.gamePlayedSeconds(
      GameId.letter,
      StorageKeys.isoDate(DateTime.now()),
    ): playedSecondsToday,
    StorageKeys.gameLevel(GameId.letter): rung,
  });
  await SoundManager.loadSoundSetting();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: LetterGame(random: Random(_seed))));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The letter choices, in the order they are laid out.
final Finder _options = find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      w.excludeSemantics &&
      (w.properties.button ?? false) &&
      w.properties.label != null,
);

Future<void> _tapChoice(WidgetTester tester, String letter) async {
  final index = tester
      .widgetList<Semantics>(_options)
      .toList()
      .indexWhere((w) => w.properties.label == letter);

  expect(index, isNonNegative, reason: '$letter şıklarda yok');

  await tester.tap(_options.at(index));
  await tester.pump();
}

Future<void> _answerRight(WidgetTester tester, LetterQuestion question) async {
  await _tapChoice(tester, question.answer);
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump();
}

String _wrongChoice(LetterQuestion question) =>
    question.choices.firstWhere((c) => c != question.answer);

String _infoValue(WidgetTester tester, String title) {
  final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^$title: ')));
  return node.label.substring(title.length + 2);
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

void main() {
  testWidgets('ilk bölüm: gösterilen harfi bul', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(0);
    await _open(tester);

    final question = round.first;
    expect(question.task, LetterTask.sameLetter);

    // The letter to find is shown big; the choices are below it.
    expect(find.text(question.letter), findsWidgets);
    expect(_options, findsNWidgets(4));

    await _answerRight(tester, question);

    expect(_infoValue(tester, 'Soru'), '2 / 5');
    expect(_infoValue(tester, 'Puan'), '10');

    semantics.dispose();
  });

  testWidgets('yanlış şık soruyu bitirmez, kilitlenir, puan vermez', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(0);
    await _open(tester);

    await _tapChoice(tester, _wrongChoice(round.first));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(Dialog), findsNothing);
    expect(_infoValue(tester, 'Soru'), '1 / 5');

    await _answerRight(tester, round.first);

    expect(_infoValue(tester, 'Soru'), '2 / 5');
    expect(_infoValue(tester, 'Puan'), '0');

    semantics.dispose();
  });

  testWidgets('küçük harf bölümünde şıklar küçük harf', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(2);
    await _open(tester, rung: 2);

    final question = round.first;
    expect(question.task, LetterTask.lowerCase);

    for (final choice in question.choices) {
      expect(lowerCaseLetters.values, contains(choice));
    }

    // The big letter is the capital; its small form is what to find.
    expect(find.text(question.letter), findsOneWidget);

    await _answerRight(tester, question);
    expect(_infoValue(tester, 'Soru'), '2 / 5');

    semantics.dispose();
  });

  testWidgets('resim bölümünde resim var, kelime yazmaz', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(4);
    await _open(tester, rung: 4);

    final question = round.first;
    expect(question.task, LetterTask.firstSound);

    expect(find.text(question.item!.emoji), findsOneWidget);
    expect(find.text(question.item!.word), findsNothing);

    await _answerRight(tester, question);
    expect(_infoValue(tester, 'Soru'), '2 / 5');

    semantics.dispose();
  });

  testWidgets('alfabe bölümünde satır ve boşluk ekranda', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(5);
    await _open(tester, rung: 5);

    final question = round.first;
    expect(question.task, LetterTask.alphabetOrder);

    expect(find.text('?'), findsOneWidget);
    for (final slot in question.sequence) {
      if (slot.isNotEmpty) expect(find.text(slot), findsWidgets);
    }

    await _answerRight(tester, question);
    expect(_infoValue(tester, 'Soru'), '2 / 5');

    semantics.dispose();
  });

  testWidgets('beş temiz soru turu kaydeder', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(0);
    await _open(tester);

    for (final question in round) {
      await _answerRight(tester, question);
    }
    await tester.pumpAndSettle();

    expect(find.text('🎉'), findsOneWidget);
    expect(
      (await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.letter)),
      1,
    );

    semantics.dispose();
  });

  testWidgets('iki soruda ilk dokunuş yanlışsa 💪 gelir, tur kaydedilmez', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(0);
    await _open(tester);

    for (var i = 0; i < round.length; i++) {
      if (i < 2) {
        await _tapChoice(tester, _wrongChoice(round[i]));
        await tester.pump(const Duration(milliseconds: 400));
      }
      await _answerRight(tester, round[i]);
    }
    await tester.pumpAndSettle();

    expect(find.text('💪'), findsOneWidget);
    expect(
      (await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.letter)),
      isNull,
    );

    semantics.dispose();
  });

  testWidgets('iki yanlıştan sonra doğru harf belirir', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(1);
    await _open(tester, rung: 1);

    final question = round.first;
    final wrong = question.choices.where((c) => c != question.answer).toList();

    final answerIndex = question.choices.indexOf(question.answer);
    final restingWidth = tester.getRect(_options.at(answerIndex)).width;

    for (var i = 0; i < 2; i++) {
      await _tapChoice(tester, wrong[i]);
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pump(const Duration(milliseconds: 325));

    expect(
      tester.getRect(_options.at(answerIndex)).width,
      greaterThan(restingWidth),
    );

    semantics.dispose();
  });

  group('her bölüm her telefona sığar', () {
    final phones = <String, Size>{
      'dar telefon': const Size(320, 568),
      'orta telefon': const Size(360, 640),
      'geniş telefon': const Size(412, 915),
    };

    for (var rung = 0; rung < letterLadder.length; rung++) {
      for (final phone in phones.entries) {
        testWidgets('bölüm ${rung + 1} ${phone.key}', (tester) async {
          final semantics = tester.ensureSemantics();
          await _open(tester, rung: rung, size: phone.value);

          expect(tester.takeException(), isNull);
          expect(_options, findsNWidgets(letterLadder[rung].cards));

          final screen = Offset.zero & phone.value;

          for (var i = 0; i < letterLadder[rung].cards; i++) {
            final rect = tester.getRect(_options.at(i));

            expect(screen.contains(rect.topLeft), isTrue, reason: '$rect');
            expect(
              screen.contains(rect.bottomRight - const Offset(1, 1)),
              isTrue,
              reason: 'şık ekran dışında: $rect',
            );
            expect(
              rect.shortestSide,
              greaterThanOrEqualTo(Brand.minTouchTarget),
              reason: 'şık çok küçük: $rect',
            );
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
