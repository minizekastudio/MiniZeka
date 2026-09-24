import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/attention_game.dart';
import 'package:mini_zeka/games/logic_game.dart';
import 'package:mini_zeka/games/math_game.dart';
import 'package:mini_zeka/games/memory_game.dart';
import 'package:mini_zeka/games/shape_game.dart';
import 'package:mini_zeka/letter_game.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';
import 'package:mini_zeka/word_game.dart';

/// Screens open dialogs a child has to reach the buttons of. On the
/// narrowest phone the app supports they must not overflow.
final _phones = <String, Size>{
  'dar telefon': const Size(320, 568),
  'orta telefon': const Size(360, 640),
};

final _games = <GameId, Widget Function()>{
  GameId.memory: () => const MemoryGame(),
  GameId.shape: () => const ShapeGame(),
  GameId.attention: () => const AttentionGame(),
  GameId.math: () => const MathGame(),
  GameId.logic: () => const LogicGame(),
  GameId.word: () => const WordGame(),
  GameId.letter: () => const LetterGame(),
};

Future<void> _open(WidgetTester tester, GameId game, Size phone) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.childAge: 5,
    StorageKeys.soundEnabled: false,
    StorageKeys.gameLimitMinutes(game): 30,
  });
  await SoundManager.loadSoundSetting();

  tester.view.physicalSize = phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: _games[game]!()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

dynamic _state(WidgetTester tester, GameId game) =>
    tester.state(find.byWidgetPredicate(
      (w) => w.runtimeType == _games[game]!().runtimeType,
    ));

void main() {
  for (final phone in _phones.entries) {
    group(phone.key, () {
      for (final game in _games.keys) {
        testWidgets('${game.shortTitle}: "?" modalı taşmıyor', (tester) async {
          await _open(tester, game, phone.value);

          await tester.tap(find.byTooltip('Nasıl oynanır?'));
          await tester.pumpAndSettle();

          expect(find.text('Anladım'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }

      // Dikkat artık soru arası diyalog kullanmıyor.
      for (final game in [GameId.math, GameId.logic]) {
        testWidgets('${game.shortTitle}: cevap diyaloğu taşmıyor',
            (tester) async {
          await _open(tester, game, phone.value);

          final state = _state(tester, game);
          switch (game) {
            case GameId.math:
              state.answer(state.options.first as int);
            case GameId.logic:
              state.answer(state.currentOptions.first as String);
            default:
              fail('bu oyun soru-cevap değil');
          }

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          expect(find.byType(Dialog), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('${game.shortTitle}: sonuç diyaloğu taşmıyor',
            (tester) async {
          await _open(tester, game, phone.value);

          final state = _state(tester, game);
          state.question = 5;

          switch (game) {
            case GameId.math:
              state.answer(state.options.first as int);
            case GameId.logic:
              state.answer(state.currentOptions.first as String);
            default:
              fail('bu oyun soru-cevap değil');
          }

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          // Through the answer dialog to the result.
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();

          expect(find.text('Tekrar Oyna'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('süre dolunca çıkan uyarı taşmıyor', (tester) async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.childAge: 5,
          StorageKeys.soundEnabled: false,
          StorageKeys.gameLimitMinutes(GameId.memory): 10,
          StorageKeys.gamePlayedSeconds(
            GameId.memory,
            StorageKeys.isoDate(DateTime.now()),
          ): 10 * 60,
        });
        await SoundManager.loadSoundSetting();

        tester.view.physicalSize = phone.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const MaterialApp(home: MemoryGame()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Bugünkü Süren Doldu'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
