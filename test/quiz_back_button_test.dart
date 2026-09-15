import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/attention_game.dart';
import 'package:mini_zeka/games/logic_game.dart';
import 'package:mini_zeka/games/math_game.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';

/// A question-and-answer game, and how a test answers one of its questions.
class _Quiz {
  const _Quiz({
    required this.name,
    required this.game,
    required this.build,
    required this.answer,
    required this.lastQuestion,
  });

  final String name;
  final GameId game;
  final Widget Function() build;

  /// Answers the current question through the screen's own handler.
  final void Function(dynamic state) answer;

  final int lastQuestion;
}

final _quizzes = [
  _Quiz(
    name: 'Dikkat',
    game: GameId.attention,
    build: () => const AttentionGame(),
    answer: (state) => state.selectItem(0),
    lastQuestion: 3,
  ),
  _Quiz(
    name: 'Matematik',
    game: GameId.math,
    build: () => const MathGame(),
    answer: (state) => state.answer(state.options.first as int),
    lastQuestion: 5,
  ),
  _Quiz(
    name: 'Mantık',
    game: GameId.logic,
    build: () => const LogicGame(),
    answer: (state) => state.answer(state.currentOptions.first as String),
    lastQuestion: 5,
  ),
];

Future<void> _open(WidgetTester tester, _Quiz quiz) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.childAge: 5,
    StorageKeys.soundEnabled: false,
    StorageKeys.gameLimitMinutes(quiz.game): 30,
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
                MaterialPageRoute(builder: (_) => quiz.build()),
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

dynamic _state(WidgetTester tester, _Quiz quiz) =>
    tester.state(find.byWidgetPredicate((w) => w.runtimeType == quiz.build().runtimeType));

Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  for (final quiz in _quizzes) {
    group(quiz.name, () {
      testWidgets('cevap diyaloğunda geri tuşu oyunu kilitlemez, soru ilerler',
          (tester) async {
        await _open(tester, quiz);

        quiz.answer(_state(tester, quiz));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(Dialog), findsOneWidget);

        await _pressBack(tester);

        expect(find.byType(Dialog), findsNothing);
        expect(_state(tester, quiz).question, 2,
            reason: 'geri tuşu "Devam Et" gibi ilerletmeli');

        // Not locked: the next answer opens its dialog again.
        quiz.answer(_state(tester, quiz));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(Dialog), findsOneWidget);
      });

      testWidgets('sonuç diyaloğunda geri tuşu oyundan çıkarır', (tester) async {
        await _open(tester, quiz);

        final state = _state(tester, quiz);
        state.question = quiz.lastQuestion;

        quiz.answer(state);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Last answer's dialog leads to the result.
        await _pressBack(tester);
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(Dialog), findsOneWidget,
            reason: 'son cevaptan sonra sonuç diyaloğu gelmeli');

        await _pressBack(tester);

        expect(find.byWidgetPredicate(
          (w) => w.runtimeType == quiz.build().runtimeType,
        ), findsNothing);
        expect(find.text('open'), findsOneWidget);
      });
    });
  }
}
