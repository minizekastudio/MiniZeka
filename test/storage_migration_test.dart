import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/storage_keys.dart';
import 'package:mini_zeka/storage_migration.dart';

/// Eski anahtarlar oyunun Türkçe adını içeriyordu; adı değiştiren biri
/// ebeveynin ayarlarını sessizce kaybediyordu. Taşıma bunu kurtarır.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = StorageKeys.isoDate(DateTime.now());

  test('eski süre ve kullanım anahtarları yeni forma taşınır', () async {
    SharedPreferences.setMockInitialValues({
      'duration_Matematik Oyunu': 35,
      'duration_Harfleri Yerleştir': 25,
      'game_time_Matematik Oyunu_$today': 420,
      'child_age': 7,
    });

    await StorageMigration.run();

    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getInt(StorageKeys.gameLimitMinutes(GameId.math)), 35);
    expect(prefs.getInt(StorageKeys.gameLimitMinutes(GameId.letter)), 25);
    expect(
      prefs.getInt(StorageKeys.gamePlayedSeconds(GameId.math, today)),
      420,
    );

    // Eskiler silinmiş olmalı.
    expect(prefs.getInt('duration_Matematik Oyunu'), isNull);
    expect(prefs.getInt('game_time_Matematik Oyunu_$today'), isNull);

    // İlgisiz anahtarlara dokunulmamalı.
    expect(prefs.getInt('child_age'), 7);

    expect(
      prefs.getInt(StorageKeys.schemaVersion),
      StorageMigration.currentVersion,
    );
  });

  test('ikinci çalıştırma zarar vermez', () async {
    SharedPreferences.setMockInitialValues({
      'duration_Mantık Oyunu': 40,
    });

    await StorageMigration.run();
    await StorageMigration.run();

    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getInt(StorageKeys.gameLimitMinutes(GameId.logic)), 40);
  });

  test('çok eski kullanım satırları temizlenir', () async {
    final old = StorageKeys.isoDate(
      DateTime.now().subtract(const Duration(days: 90)),
    );

    SharedPreferences.setMockInitialValues({
      StorageKeys.gamePlayedSeconds(GameId.memory, old): 600,
      StorageKeys.gamePlayedSeconds(GameId.memory, today): 60,
    });

    await StorageMigration.run();

    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getInt(StorageKeys.gamePlayedSeconds(GameId.memory, old)),
        isNull);
    expect(prefs.getInt(StorageKeys.gamePlayedSeconds(GameId.memory, today)),
        60);
  });

  test('tanınmayan eski anahtar sessizce yok sayılır', () async {
    SharedPreferences.setMockInitialValues({
      'game_time_Silinmis Oyun_$today': 99,
    });

    await StorageMigration.run();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.startsWith('played_sec.')), isEmpty);
  });
}
