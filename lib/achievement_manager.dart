import 'package:shared_preferences/shared_preferences.dart';
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
  static Future<void> markGamePlayed(String gameKey) async {
    final prefs = await SharedPreferences.getInstance();

    final playedGames =
        prefs.getStringList(StorageKeys.playedGames) ?? <String>[];

    if (!playedGames.contains(gameKey)) {
      playedGames.add(gameKey);

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