import 'package:audioplayers/audioplayers.dart';
import 'storage_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  // Ses ayarının anahtarı
  
  // Varsayılan olarak ses açık
  static bool _isSoundEnabled = true;

  // =====================================================
  // SES AYARINI YÜKLE
  // =====================================================

  static Future<void> loadSoundSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isSoundEnabled = prefs.getBool(StorageKeys.soundEnabled) ?? true;
    } catch (e) {
      debugPrint('❌ SES AYARI YÜKLENEMEDİ: $e');
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
        StorageKeys.soundEnabled,
        enabled,
      );

      // Ses kapatıldıysa mevcut sesi de durdur.
      if (!enabled) {
        await _player.stop();
      }

    } catch (e) {
      debugPrint('❌ SES AYARI KAYDEDİLEMEDİ: $e');
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

    } catch (e) {
      debugPrint('❌ SES HATASI: $e');
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

    } catch (e) {
      debugPrint('❌ SES HATASI: $e');
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

    } catch (e) {
      debugPrint('❌ SES HATASI: $e');
    }
  }
}