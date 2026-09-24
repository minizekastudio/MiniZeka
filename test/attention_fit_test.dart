import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/app_theme.dart';
import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/attention_game.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';

/// "Ekrana hep tam sığsın, yarım yamalak olmasın" — for the attention board
/// too. It used to be a fixed four columns: 6 boxes came out 4+2 and 9 boxes
/// 4+4+1, with the bottom row half empty.
void main() {
  final phones = <String, Size>{
    'dar telefon': const Size(320, 568),
    'orta telefon': const Size(360, 640),
    'geniş telefon': const Size(412, 915),
  };

  for (var rung = 0; rung < attentionLadder.length; rung++) {
    final boxes = attentionLadder[rung].cards;

    for (final phone in phones.entries) {
      testWidgets(
          'bölüm ${rung + 1} ($boxes kutu) ${phone.key} ekranına sığar',
          (tester) async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.childAge: 4,
          StorageKeys.soundEnabled: false,
          StorageKeys.gameLimitMinutes(GameId.attention): 30,
          StorageKeys.gameLevel(GameId.attention): rung,
        });
        await SoundManager.loadSoundSetting();

        tester.view.physicalSize = phone.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(home: AttentionGame(random: Random(rung))),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(tester.takeException(), isNull,
            reason: '${phone.key} ekranında taşma');

        // Only the board's boxes: app bar buttons are Semantics too, but
        // they do not hide their children the way a box does.
        final boxFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.excludeSemantics &&
              (widget.properties.button ?? false),
        );

        expect(boxFinder, findsNWidgets(boxes));

        final screen = Offset.zero & phone.value;
        final rows = <double>{};

        for (var i = 0; i < boxes; i++) {
          final rect = tester.getRect(boxFinder.at(i));
          rows.add(rect.top);

          expect(screen.contains(rect.topLeft), isTrue, reason: '$rect');
          expect(
            screen.contains(rect.bottomRight - const Offset(1, 1)),
            isTrue,
            reason: 'kutu ekran dışında: $rect',
          );
          expect(
            rect.shortestSide,
            greaterThanOrEqualTo(Brand.minTouchTarget),
            reason: '$boxes kutu ${phone.key}: ${rect.size}',
          );
        }

        expect(boxes % rows.length, 0,
            reason: '$boxes kutu ${rows.length} sıraya bölünmüş');
      });
    }
  }
}
