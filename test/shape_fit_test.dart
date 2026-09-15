import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/app_theme.dart';
import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/shape_figure.dart';
import 'package:mini_zeka/games/shape_game.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';

/// "Ekrana hep tam sığsın, yarım yamalak olmasın" — for the shape game too.
void main() {
  final phones = <String, Size>{
    'dar telefon': const Size(320, 568),
    'orta telefon': const Size(360, 640),
    'geniş telefon': const Size(412, 915),
  };

  final cardLabels = {for (final kind in ShapeKind.values) kind.label};

  for (var rung = 0; rung < shapeLadder.length; rung++) {
    final cards = shapeLadder[rung].cards;

    for (final phone in phones.entries) {
      testWidgets(
          'bölüm ${rung + 1} ($cards kart) ${phone.key} ekranına sığar, '
          'kartlar en az ${Brand.minTouchTarget.toInt()} px', (tester) async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.childAge: 5,
          StorageKeys.soundEnabled: false,
          StorageKeys.gameLimitMinutes(GameId.shape): 30,
          StorageKeys.gameLevel(GameId.shape): rung,
        });
        await SoundManager.loadSoundSetting();

        tester.view.physicalSize = phone.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(home: ShapeGame(random: Random(rung))),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(tester.takeException(), isNull,
            reason: '${phone.key} ekranında taşma');

        final options = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.button ?? false) &&
              cardLabels.contains(widget.properties.label),
        );

        expect(options, findsNWidgets(cards));

        final screen = Offset.zero & phone.value;
        final rows = <double>{};

        for (var i = 0; i < cards; i++) {
          final rect = tester.getRect(options.at(i));
          rows.add(rect.top);

          expect(screen.contains(rect.topLeft), isTrue, reason: '$rect');
          expect(screen.contains(rect.bottomRight - const Offset(1, 1)), isTrue,
              reason: 'kart ekran dışında: $rect');
          expect(rect.width, greaterThanOrEqualTo(Brand.minTouchTarget));
          expect(rect.height, greaterThanOrEqualTo(Brand.minTouchTarget));
        }

        // Every row holds the same number of cards: no half-empty last row.
        expect(cards % rows.length, 0, reason: '$cards kart, ${rows.length} sıra');
      });
    }
  }
}
