import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  // Ses ayarının anahtarı
  static const String _soundKey = 'sound_enabled';

  // Varsayılan olarak ses açık
  static bool _isSoundEnabled = true;

  // =====================================================
  // SES AYARINI YÜKLE
  // =====================================================

  static Future<void> loadSoundSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isSoundEnabled = prefs.getBool(_soundKey) ?? true;
    } catch (e) {
      print('❌ SES AYARI YÜKLENEMEDİ: $e');
    }
  }

  // =====================================================
  // SES AÇIK MI?
  // =====================================================

  static bool get isSoundEnabled => _isSoundEnabled;

  // =====================================================
  // SESİ AÇ / KAPAT
  // =====================================================

  static Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(
        _soundKey,
        enabled,
      );

      // Ses kapatıldıysa mevcut sesi de durdur.
      if (!enabled) {
        await _player.stop();
      }

      print(
        enabled
            ? '🔊 SES AÇILDI'
            : '🔇 SES KAPATILDI',
      );
    } catch (e) {
      print('❌ SES AYARI KAYDEDİLEMEDİ: $e');
    }
  }

  // =====================================================
  // DOĞRU CEVAP
  // =====================================================

  static Future<void> playCorrect() async {
    if (!_isSoundEnabled) return;

    try {
      await _player.stop();

      await _player.setVolume(1.0);

      await _player.play(
        AssetSource('sounds/correct.mp3'),
      );

      print('✅ DOĞRU SESİ ÇALINDI');
    } catch (e) {
      print('❌ SES HATASI: $e');
    }
  }

  // =====================================================
  // YANLIŞ CEVAP
  // =====================================================

  static Future<void> playWrong() async {
    if (!_isSoundEnabled) return;

    try {
      await _player.stop();

      await _player.setVolume(1.0);

      await _player.play(
        AssetSource('sounds/wrong.mp3'),
      );

      print('❌ YANLIŞ SESİ ÇALINDI');
    } catch (e) {
      print('❌ SES HATASI: $e');
    }
  }

  // =====================================================
  // OYUN BİTTİ
  // =====================================================

  static Future<void> playGameOver() async {
    if (!_isSoundEnabled) return;

    try {
      await _player.stop();

      await _player.setVolume(1.0);

      await _player.play(
        AssetSource('sounds/game_over.mp3'),
      );

      print('🎮 OYUN BİTTİ SESİ ÇALINDI');
    } catch (e) {
      print('❌ SES HATASI: $e');
    }
  }
}