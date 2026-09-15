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

  test('kaşif rozeti beşinci farklı oyunda açılır, dördüncüde açılmaz',
      () async {
    final games = GameId.values.take(5).toList();

    for (final game in games.take(4)) {
      await AchievementManager.markGamePlayed(game);
    }
    expect(await AchievementManager.isUnlocked('game_explorer'), isFalse);

    await AchievementManager.markGamePlayed(games[4]);
    expect(await AchievementManager.isUnlocked('game_explorer'), isTrue);
  });
}
