import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/app_theme.dart';
import 'package:mini_zeka/difficulty.dart';
import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/memory_game.dart';
import 'package:mini_zeka/storage_keys.dart';

/// "Ekrana hep tam sığsın, yarım yamalak olmasın."
///
/// Her bölüm gerçek telefon ölçülerinde çizilir; taşma olursa Flutter
/// istisna atar ve test düşer.
void main() {
  final phones = <String, Size>{
    'dar telefon': const Size(320, 568),
    'orta telefon': const Size(412, 915),
    'geniş telefon': const Size(480, 1000),
  };

  for (final level in List.generate(memoryLadder.length, (i) => i)) {
    final cards = memoryLadder[level].cards;

    for (final phone in phones.entries) {
      testWidgets('$cards kart ${phone.key} ekranına taşmadan sığar',
          (tester) async {
        SharedPreferences.setMockInitialValues({
          // The youngest band starts at rung 0, so the saved rung is the one
          // that gets drawn. With an older child the ladder floor lifted the
          // board and the first two rungs were never really tested.
          StorageKeys.childAge: 4,
          StorageKeys.gameLevel(GameId.memory): level,
          StorageKeys.gameLimitMinutes(GameId.memory): 30,
        });

        tester.view.physicalSize = phone.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const MaterialApp(home: MemoryGame()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          tester.takeException(),
          isNull,
          reason: '$cards kart ${phone.key} ekranında taşıyor',
        );

        final cardFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.button ?? false) &&
              widget.properties.label == 'Kapalı kart',
        );

        expect(cardFinder, findsNWidgets(cards));

        final screen = Offset.zero & phone.value;

        for (var i = 0; i < cards; i++) {
          final rect = tester.getRect(cardFinder.at(i));

          expect(screen.contains(rect.topLeft), isTrue, reason: '$rect');
          expect(
            screen.contains(rect.bottomRight - const Offset(1, 1)),
            isTrue,
            reason: 'kart ekran dışında: $rect',
          );
          expect(
            rect.shortestSide,
            greaterThanOrEqualTo(Brand.minTouchTarget),
            reason: '$cards kart ${phone.key}: kart ${rect.size}',
          );
        }
      });
    }
  }
}
