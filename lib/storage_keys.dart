import 'game_id.dart';

/// Every SharedPreferences key in the app, in one place.
///
/// Keys used to be raw strings spread across a dozen files, and the per-game
/// ones were built from Turkish display names — editing a name silently
/// orphaned the parent's saved settings. Nothing outside this class should
/// write a preference key literal.
class StorageKeys {
  StorageKeys._();

  /// Bumped when stored data needs migrating. See StorageMigration.
  static const schemaVersion = 'schema_version';

  static const childAge = 'child_age';
  static const childName = 'child_name';
  static const parentPin = 'parent_pin';

  static const darkMode = 'dark_mode';
  static const soundEnabled = 'sound_enabled';
  static const selectedAvatar = 'selected_avatar';

  static const playedGames = 'played_games';
  static const unlockedAchievements = 'unlocked_achievements';

  /// Daily limit a parent set for one game, in minutes.
  static String gameLimitMinutes(GameId game) => 'limit_min.${game.storageId}';

  /// Seconds played of one game on one day. [isoDate] is yyyy-MM-dd.
  static String gamePlayedSeconds(GameId game, String isoDate) =>
      'played_sec.${game.storageId}.$isoDate';

  /// Prefix shared by every daily usage key, for pruning old days.
  static const playedSecondsPrefix = 'played_sec.';

  /// yyyy-MM-dd for the given day.
  static String isoDate(DateTime when) =>
      '${when.year}-'
      '${when.month.toString().padLeft(2, '0')}-'
      '${when.day.toString().padLeft(2, '0')}';
}
