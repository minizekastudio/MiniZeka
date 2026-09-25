import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/achievement_manager.dart';
import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/storage_keys.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('oynanan oyun kalıcı kimliğiyle ve yalnızca bir kez kaydedilir',
      () async {
    await AchievementManager.markGamePlayed(GameId.memory);
    await AchievementManager.markGamePlayed(GameId.memory);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(StorageKeys.playedGames), ['memory']);
  });

  test('rozet açılırken aynı anda yazılan başka kayıt kaybolmaz', () async {
    // A round saves its level while its badge unlocks. Whatever point of the
    // unlock the other write lands on, it must survive.
    for (var step = 0; step <= 30; step++) {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final unlocking = AchievementManager.unlock('first_step');
      for (var i = 0; i < step; i++) {
        await Future<void>.value();
      }
      await prefs.setInt(StorageKeys.gameRoundsCleared(GameId.shape), 1);
      await unlocking;

      expect(prefs.getInt(StorageKeys.gameRoundsCleared(GameId.shape)), 1,
          reason: 'yazma, unlock\'un $step. adımına denk geldi');
    }
  });

  test('kaşif rozeti bütün oyunlar oynanınca açılır, biri eksikken açılmaz',
      () async {
    // The bar is GameId.values.length, so adding a game raises it instead of
    // leaving the badge unlockable with a stale five.
    final games = GameId.values;

    for (final game in games.take(games.length - 1)) {
      await AchievementManager.markGamePlayed(game);
    }
    expect(await AchievementManager.isUnlocked('game_explorer'), isFalse);

    await AchievementManager.markGamePlayed(games.last);
    expect(await AchievementManager.isUnlocked('game_explorer'), isTrue);
  });
}
