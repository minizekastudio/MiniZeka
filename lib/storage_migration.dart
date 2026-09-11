import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_id.dart';
import 'storage_keys.dart';

/// Brings stored preferences up to the current schema.
///
/// Runs once at startup, before anything reads a preference. Each step is
/// idempotent, so an interrupted run simply repeats harmlessly next launch.
class StorageMigration {
  StorageMigration._();

  /// Bump this when a new step is added below.
  static const currentVersion = 1;

  /// Daily usage rows older than this are pruned; the parent panel only ever
  /// shows today, and history rows otherwise accumulate forever.
  static const _keepUsageDays = 30;

  static Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();

    final version = prefs.getInt(StorageKeys.schemaVersion) ?? 0;

    if (version < 1) {
      await _v1MoveGameKeysOffDisplayNames(prefs);
    }

    if (version < currentVersion) {
      await prefs.setInt(StorageKeys.schemaVersion, currentVersion);
    }

    await _pruneOldUsage(prefs);
  }

  /// v1: per-game keys used to embed the Turkish display name, e.g.
  /// `duration_Matematik Oyunu` and `game_time_Matematik Oyunu_2026-09-11`.
  /// Editing a game's name silently orphaned the parent's settings. Keys are
  /// now built from [GameId.storageId], which never changes.
  static Future<void> _v1MoveGameKeysOffDisplayNames(
    SharedPreferences prefs,
  ) async {
    var moved = 0;

    for (final game in GameId.values) {
      final legacyKey = 'duration_${game.title}';
      final minutes = prefs.getInt(legacyKey);

      if (minutes != null) {
        await prefs.setInt(StorageKeys.gameLimitMinutes(game), minutes);
        await prefs.remove(legacyKey);
        moved++;
      }
    }

    const usagePrefix = 'game_time_';

    for (final key in prefs.getKeys().toList()) {
      if (!key.startsWith(usagePrefix)) continue;

      final rest = key.substring(usagePrefix.length);

      // `<display name>_<yyyy-MM-dd>` — the name itself may contain spaces,
      // so split on the LAST underscore.
      final cut = rest.lastIndexOf('_');
      if (cut <= 0) continue;

      final game = _byTitle(rest.substring(0, cut));
      if (game == null) continue;

      final seconds = prefs.getInt(key);
      if (seconds != null) {
        await prefs.setInt(
          StorageKeys.gamePlayedSeconds(game, rest.substring(cut + 1)),
          seconds,
        );
        moved++;
      }

      await prefs.remove(key);
    }

    if (moved > 0) {
      debugPrint('StorageMigration v1: moved $moved legacy key(s)');
    }
  }

  /// Legacy keys carried the display name; resolve it back to a game.
  static GameId? _byTitle(String title) {
    for (final game in GameId.values) {
      if (game.title == title) return game;
    }
    return null;
  }

  static Future<void> _pruneOldUsage(SharedPreferences prefs) async {
    final cutoff = StorageKeys.isoDate(
      DateTime.now().subtract(const Duration(days: _keepUsageDays)),
    );

    for (final key in prefs.getKeys().toList()) {
      if (!key.startsWith(StorageKeys.playedSecondsPrefix)) continue;

      // played_sec.<id>.<yyyy-MM-dd> — dates sort lexicographically.
      final date = key.split('.').last;
      if (date.length == 10 && date.compareTo(cutoff) < 0) {
        await prefs.remove(key);
      }
    }
  }
}
