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
    }
  }

  static Future<Set<String>> getUnlocked() async {
    final prefs = await SharedPreferences.getInstance();

    // No reload(): it swaps the whole in-memory cache for a copy read a
    // moment earlier, which silently dropped values other code wrote in
    // between — a round's saved level was lost that way. Everything here
    // runs in one isolate, so the cache is already current.
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

    // Every game, not a fixed five: the app had five games when this was
    // written and quietly kept the old bar after two more were added.
    if (playedGames.length >= GameId.values.length) {
      await unlock('game_explorer');
    }
  }
}