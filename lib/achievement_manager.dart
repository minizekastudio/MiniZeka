import 'package:shared_preferences/shared_preferences.dart';

class AchievementManager {
  static const String _storageKey = 'unlocked_achievements';

  static Future<void> unlock(String achievementKey) async {
    final prefs = await SharedPreferences.getInstance();

    final unlocked =
        prefs.getStringList(_storageKey) ?? <String>[];

    if (!unlocked.contains(achievementKey)) {
      unlocked.add(achievementKey);
      await prefs.setStringList(_storageKey, unlocked);
      await prefs.reload();
    }
  }

  static Future<Set<String>> getUnlocked() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.reload();

    final unlocked =
        prefs.getStringList(_storageKey) ?? <String>[];

    return unlocked.toSet();
  }

  static Future<bool> isUnlocked(String achievementKey) async {
    final unlocked = await getUnlocked();
    return unlocked.contains(achievementKey);
  }
  static Future<void> markGamePlayed(String gameKey) async {
    final prefs = await SharedPreferences.getInstance();

    final playedGames =
        prefs.getStringList('played_games') ?? <String>[];

    if (!playedGames.contains(gameKey)) {
      playedGames.add(gameKey);

      await prefs.setStringList(
        'played_games',
        playedGames,
      );
    }

    if (playedGames.length >= 5) {
      await unlock('game_explorer');
    }
  }
}