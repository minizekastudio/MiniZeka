import 'package:shared_preferences/shared_preferences.dart';
import 'game_id.dart';
import 'storage_keys.dart';

class AchievementManager {
  
  static Future<void> unlock(String achievementKey) async {
    final prefs = await SharedPreferences.getInstance();

    final unlocked =
        prefs.getStringList(StorageKeys.unlockedAchievements) ?? <String>[];

    if (!unlocked.contains(achievementKey)) {
      unlocked.add(achievementKey);
      await prefs.setStringList(StorageKeys.unlockedAchievements, unlocked);
      await prefs.reload();
    }
  }

  static Future<Set<String>> getUnlocked() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.reload();

    final unlocked =
        prefs.getStringList(StorageKeys.unlockedAchievements) ?? <String>[];

    return unlocked.toSet();
  }

  static Future<bool> isUnlocked(String achievementKey) async {
    final unlocked = await getUnlocked();
    return unlocked.contains(achievementKey);
  }
  /// Records that [game] has been played at least once.
  ///
  /// Takes a [GameId], not a string: callers used to pass hand-typed ids
  /// ('memory', 'math') that only matched the stored ids by coincidence.
  static Future<void> markGamePlayed(GameId game) async {
    final prefs = await SharedPreferences.getInstance();

    final playedGames =
        prefs.getStringList(StorageKeys.playedGames) ?? <String>[];

    if (!playedGames.contains(game.storageId)) {
      playedGames.add(game.storageId);

      await prefs.setStringList(
        StorageKeys.playedGames,
        playedGames,
      );
    }

    if (playedGames.length >= 5) {
      await unlock('game_explorer');
    }
  }
}