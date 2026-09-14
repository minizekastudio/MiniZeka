import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/games/memory_game.dart';
import 'package:mini_zeka/sound_manager.dart';
import 'package:mini_zeka/storage_keys.dart';

/// What the level strip shows when the game opens with this saved state.
Future<({String levelLabel, int filledStars, int emptyStars})> _openWith(
  WidgetTester tester, {
  required int childAge,
  required int savedLevel,
  required int savedRounds,
}) async {
  SharedPreferences.setMockInitialValues({
    StorageKeys.childAge: childAge,
    StorageKeys.soundEnabled: false,
    StorageKeys.gameLimitMinutes(GameId.memory): 30,
    StorageKeys.gameLevel(GameId.memory): savedLevel,
    StorageKeys.gameRoundsCleared(GameId.memory): savedRounds,
  });
  await SoundManager.loadSoundSetting();

  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: MemoryGame()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  final label = tester
      .widgetList<Text>(find.textContaining('. Bölüm'))
      .map((text) => text.data)
      .single!;

  return (
    levelLabel: label,
    filledStars: find.byIcon(Icons.star_rounded).evaluate().length,
    emptyStars: find.byIcon(Icons.star_outline_rounded).evaluate().length,
  );
}

void main() {
  group('hafıza ilerlemesi açılışta', () {
    testWidgets(
        'yaş yükseltilince eski bölümün yıldızları yeni bölüme taşınmaz',
        (tester) async {
      // 4 kartlık bölümde bir yıldız kazanmış, sonra yaşı 8'e çıkarılmış.
      final strip = await _openWith(
        tester,
        childAge: 8,
        savedLevel: 0,
        savedRounds: 1,
      );

      expect(strip.levelLabel, '3. Bölüm');
      expect(strip.filledStars, 0);
      expect(strip.emptyStars, 3);
    });

    testWidgets('kayıtlı bölüm yaştan yüksekse bölüm de yıldızlar da korunur',
        (tester) async {
      final strip = await _openWith(
        tester,
        childAge: 5,
        savedLevel: 2,
        savedRounds: 1,
      );

      expect(strip.levelLabel, '3. Bölüm', reason: 'seviye geri gitmez');
      expect(strip.filledStars, 1);
      expect(strip.emptyStars, 2);
    });

    testWidgets('yaşa denk gelen kayıtlı bölümün yıldızları korunur',
        (tester) async {
      final strip = await _openWith(
        tester,
        childAge: 8,
        savedLevel: 2,
        savedRounds: 2,
      );

      expect(strip.levelLabel, '3. Bölüm');
      expect(strip.filledStars, 2);
    });
  });
}
