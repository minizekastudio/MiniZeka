import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_zeka/game_id.dart';
import 'package:mini_zeka/game_timer.dart';
import 'package:mini_zeka/storage_keys.dart';

/// Gunluk oyun suresi sayaci.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('kayıtlı süre okunur ve saniye saniye işlenir', (tester) async {
    final day = DateTime(2026, 9, 11, 10, 0);

    SharedPreferences.setMockInitialValues({
      StorageKeys.gameLimitMinutes(GameId.math): 20,
      StorageKeys.gamePlayedSeconds(GameId.math, '2026-09-11'): 30,
    });

    final timer = GameTimerController(game: GameId.math, clock: () => day);
    await timer.load();

    expect(timer.allowedMinutes, 20);
    expect(timer.usedSeconds, 30);

    timer.start();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(timer.usedSeconds, 32);

    timer.dispose();
  });

  testWidgets('gece yarısı geçilince yeni güne sıfırdan başlar',
      (tester) async {
    // Bu hata gerçekti: tarih her kayıtta yeniden hesaplandığı için akşamın
    // toplamı ertesi günün anahtarına yazılıyor ve çocuk uygulamayı hiç
    // açmadan ertesi günün hakkını tüketmiş oluyordu.
    var now = DateTime(2026, 9, 11, 23, 59, 58);

    final timer = GameTimerController(game: GameId.memory, clock: () => now);
    await timer.load();
    timer.start();

    await tester.pump(const Duration(seconds: 1));
    expect(timer.usedSeconds, 1);

    // Saat 00:00'ı geçti.
    now = DateTime(2026, 9, 12, 0, 0, 0);
    await tester.pump(const Duration(seconds: 1));

    expect(timer.usedSeconds, 0, reason: 'yeni gün sıfırdan başlamalı');

    await tester.pump(const Duration(seconds: 1));
    expect(timer.usedSeconds, 1);

    timer.stop();
    await tester.pump();

    final prefs = await SharedPreferences.getInstance();

    expect(
      prefs.getInt(StorageKeys.gamePlayedSeconds(GameId.memory, '2026-09-11')),
      1,
      reason: 'eski günün toplamı kendi anahtarında kalmalı',
    );
    expect(
      prefs.getInt(StorageKeys.gamePlayedSeconds(GameId.memory, '2026-09-12')),
      1,
      reason: 'yeni gün kendi anahtarına yazmalı',
    );

    timer.dispose();
  });

  testWidgets('süre dolunca sayaç durur ve bitmiş işaretlenir', (tester) async {
    final day = DateTime(2026, 9, 11, 10, 0);

    SharedPreferences.setMockInitialValues({
      StorageKeys.gameLimitMinutes(GameId.logic): 1,
      StorageKeys.gamePlayedSeconds(GameId.logic, '2026-09-11'): 58,
    });

    final timer = GameTimerController(game: GameId.logic, clock: () => day);
    await timer.load();
    timer.start();

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(timer.timeIsOver, isTrue);
    expect(timer.isFinished, isTrue);
    expect(timer.remainingSeconds, 0);

    timer.dispose();
  });

  test('limit zaten dolmuşsa açılışta bitmiş gelir', () async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.gameLimitMinutes(GameId.word): 5,
      StorageKeys.gamePlayedSeconds(GameId.word, '2026-09-11'): 9999,
    });

    final timer = GameTimerController(
      game: GameId.word,
      clock: () => DateTime(2026, 9, 11, 12),
    );
    await timer.load();

    expect(timer.isFinished, isTrue);
    expect(timer.usedSeconds, 300);

    timer.dispose();
  });
}
