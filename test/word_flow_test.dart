import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/app_theme.dart';
import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/word_round.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';
import 'package:mini_zeka/word_game.dart';

const _seed = 7;

List<WordQuestion> _expectedRound(int rung) =>
    buildWordRound(rung: rung, random: Random(_seed));

Future<void> _open(
  WidgetTester tester, {
  int rung = 0,
  int playedSecondsToday = 0,
  Size size = const Size(412, 915),
}) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.childAge: 4,
    StorageKeys.soundEnabled: false,
    StorageKeys.gameLimitMinutes(GameId.word): 30,
    StorageKeys.gamePlayedSeconds(
      GameId.word,
      StorageKeys.isoDate(DateTime.now()),
    ): playedSecondsToday,
    StorageKeys.gameLevel(GameId.word): rung,
  });
  await SoundManager.loadSoundSetting();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: WordGame(random: Random(_seed))));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The letter tiles, in the order they are laid out.
final Finder _tiles = find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      w.excludeSemantics &&
      (w.properties.button ?? false) &&
      w.properties.label != null,
);

Future<void> _tapTile(WidgetTester tester, int index) async {
  await tester.tap(_tiles.at(index));
  await tester.pump();
}

/// The letters currently sitting in the slots, in order.
List<String> _slotted(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: find.byType(Wrap), matching: find.byType(Text)),
    )
    .map((text) => text.data ?? '')
    .where((letter) => letter.isNotEmpty)
    .toList();

Future<void> _tapSlot(WidgetTester tester, int slot) async {
  await tester.tap(
    find
        .descendant(of: find.byType(Wrap), matching: find.byType(Text))
        .at(slot),
  );
  await tester.pump();
}

/// Indexes of the tiles that spell [question], in order.
List<int> _solution(WordQuestion question) {
  final wanted = question.task == WordTask.firstLetter
      ? [question.spelling.first]
      : question.spelling;

  final used = <int>[];

  for (final letter in wanted) {
    for (var i = 0; i < question.letters.length; i++) {
      if (question.letters[i] == letter && !used.contains(i)) {
        used.add(i);
        break;
      }
    }
  }

  return used;
}

/// A tap that cannot be right: a tile holding some other letter.
int _wrongTile(WordQuestion question) {
  final first = question.spelling.first;

  return question.letters.indexWhere((letter) => letter != first);
}

/// Tile indexes that fill every slot but spell something else.
List<int> _wrongOrder(WordQuestion question) {
  final solution = _solution(question);

  final spare = List.generate(
    question.letters.length,
    (i) => i,
  ).where((i) => !solution.contains(i));

  if (spare.isNotEmpty) return [spare.first, ...solution.skip(1)];

  for (var i = 1; i < solution.length; i++) {
    if (question.letters[solution[i]] != question.letters[solution.first]) {
      final order = [...solution];
      order[0] = solution[i];
      order[i] = solution.first;
      return order;
    }
  }

  return solution;
}

Future<void> _wrongAttempt(WidgetTester tester, WordQuestion question) async {
  for (final index in _wrongOrder(question)) {
    await _tapTile(tester, index);
  }
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _answerRight(WidgetTester tester, WordQuestion question) async {
  for (final index in _solution(question)) {
    await _tapTile(tester, index);
  }
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump();
}

String _infoValue(WidgetTester tester, String title) {
  final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^$title: ')));
  return node.label.substring(title.length + 2);
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

void main() {
  testWidgets('ilk bölüm kelimenin ilk harfini sorar', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(0);
    await _open(tester);

    final question = round.first;
    expect(question.task, WordTask.firstLetter);

    // The picture is what the child reads; the word itself is not written.
    expect(find.text(question.item.emoji), findsOneWidget);
    expect(find.text(question.word), findsNothing);
    expect(_tiles, findsNWidgets(4));

    await _answerRight(tester, question);

    expect(_infoValue(tester, 'Soru'), '2 / 5');
    expect(_infoValue(tester, 'Puan'), '10');

    semantics.dispose();
  });

  testWidgets('harfler sırayla yuvalara dizilir', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(1);
    await _open(tester, rung: 1);

    final question = round.first;
    expect(question.task, WordTask.spell);

    final solution = _solution(question);
    await _tapTile(tester, solution.first);

    expect(find.text(question.spelling.first), findsWidgets);

    for (final index in solution.skip(1)) {
      await _tapTile(tester, index);
    }
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();

    expect(_infoValue(tester, 'Soru'), '2 / 5');

    semantics.dispose();
  });

  testWidgets('yanlış dizilim canı götürmez, harfler geri gelir', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(1);
    await _open(tester, rung: 1);

    final question = round.first;

    await _wrongAttempt(tester, question);

    // Nothing ends: no dialog, same question, and the slots are empty again.
    expect(find.byType(Dialog), findsNothing);
    expect(_infoValue(tester, 'Soru'), '1 / 5');
    expect(_slotted(tester), isEmpty);

    await _answerRight(tester, question);

    expect(_infoValue(tester, 'Soru'), '2 / 5');
    expect(_infoValue(tester, 'Puan'), '0');

    semantics.dispose();
  });

  testWidgets('yuvaya dokununca harf geri alınır', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(1);
    await _open(tester, rung: 1);

    final question = round.first;
    final solution = _solution(question);

    // A letter put in the wrong place must be takeable back out, otherwise
    // the only way out of a mistake is to get it wrong on purpose.
    await _tapTile(tester, _wrongTile(question));
    expect(_slotted(tester), hasLength(1));

    await _tapSlot(tester, 0);
    expect(_slotted(tester), isEmpty);

    for (final index in solution) {
      await _tapTile(tester, index);
    }
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();

    expect(_infoValue(tester, 'Soru'), '2 / 5');
    expect(_infoValue(tester, 'Puan'), isNot('0'));

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
      (await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.word)),
      1,
    );

    semantics.dispose();
  });

  testWidgets('iki soruda ilk deneme yanlışsa 💪 gelir, tur kaydedilmez', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(0);
    await _open(tester);

    for (var i = 0; i < round.length; i++) {
      if (i < 2) {
        await _tapTile(tester, _wrongTile(round[i]));
        await tester.pump(const Duration(milliseconds: 400));
      }
      await _answerRight(tester, round[i]);
    }
    await tester.pumpAndSettle();

    expect(find.text('💪'), findsOneWidget);
    expect(
      (await _prefs()).getInt(StorageKeys.gameRoundsCleared(GameId.word)),
      isNull,
    );

    semantics.dispose();
  });

  testWidgets('iki yanlıştan sonra sıradaki harf belirir', (tester) async {
    final semantics = tester.ensureSemantics();
    final round = _expectedRound(1);
    await _open(tester, rung: 1);

    final question = round.first;
    final hinted = _solution(question).first;
    final restingWidth = tester.getRect(_tiles.at(hinted)).width;

    for (var attempt = 0; attempt < 2; attempt++) {
      await _wrongAttempt(tester, question);
    }

    // The tile the child should reach for now grows and shrinks, so the
    // hint is visible without reading anything.
    await tester.pump(const Duration(milliseconds: 325));

    expect(tester.getRect(_tiles.at(hinted)).width, greaterThan(restingWidth));

    semantics.dispose();
  });

  group('her bölüm her telefona sığar', () {
    final phones = <String, Size>{
      'dar telefon': const Size(320, 568),
      'orta telefon': const Size(360, 640),
      'geniş telefon': const Size(412, 915),
    };

    for (var rung = 0; rung < wordLadder.length; rung++) {
      for (final phone in phones.entries) {
        testWidgets('bölüm ${rung + 1} ${phone.key}', (tester) async {
          final semantics = tester.ensureSemantics();
          final round = _expectedRound(rung);
          await _open(tester, rung: rung, size: phone.value);

          expect(tester.takeException(), isNull);
          expect(_tiles, findsNWidgets(round.first.letters.length));

          final screen = Offset.zero & phone.value;

          for (var i = 0; i < round.first.letters.length; i++) {
            final rect = tester.getRect(_tiles.at(i));

            expect(screen.contains(rect.topLeft), isTrue, reason: '$rect');
            expect(
              screen.contains(rect.bottomRight - const Offset(1, 1)),
              isTrue,
              reason: 'harf ekran dışında: $rect',
            );
            expect(
              rect.shortestSide,
              greaterThanOrEqualTo(Brand.minTouchTarget),
              reason: 'harf çok küçük: $rect',
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
