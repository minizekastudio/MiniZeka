import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/app_theme.dart';
import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/math_game.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';

/// The board has to fit without scrolling on every phone, including the rung
/// where twenty things are drawn to count.
void main() {
  final phones = <String, Size>{
    'dar telefon': const Size(320, 568),
    'orta telefon': const Size(360, 640),
    'geniş telefon': const Size(412, 915),
  };

  for (var rung = 0; rung < mathLadder.length; rung++) {
    for (final phone in phones.entries) {
      testWidgets('bölüm ${rung + 1} ${phone.key} ekranına sığar',
          (tester) async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.childAge: 4,
          StorageKeys.soundEnabled: false,
          StorageKeys.gameLimitMinutes(GameId.math): 30,
          StorageKeys.gameLevel(GameId.math): rung,
        });
        await SoundManager.loadSoundSetting();

        tester.view.physicalSize = phone.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(home: MathGame(random: Random(rung + 1))),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(tester.takeException(), isNull,
            reason: '${phone.key} ekranında taşma');

        final optionFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.excludeSemantics &&
              (widget.properties.button ?? false),
        );

        expect(optionFinder, findsNWidgets(mathLadder[rung].cards));

        final screen = Offset.zero & phone.value;

        for (var i = 0; i < mathLadder[rung].cards; i++) {
          final rect = tester.getRect(optionFinder.at(i));

          expect(screen.contains(rect.topLeft), isTrue, reason: '$rect');
          expect(
            screen.contains(rect.bottomRight - const Offset(1, 1)),
            isTrue,
            reason: 'şık ekran dışında: $rect',
          );
          expect(
            rect.shortestSide,
            greaterThanOrEqualTo(Brand.minTouchTarget),
            reason: 'bölüm ${rung + 1} ${phone.key}: ${rect.size}',
          );
        }
      });
    }
  }
}
