import 'package:flutter/foundation.dart';
import 'storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarManager {
  
  // Varsayılan avatar
  static String _selectedAvatar = '👦';

  // =====================================================
  // MEVCUT AVATAR
  // =====================================================

  static String get selectedAvatar => _selectedAvatar;

  // =====================================================
  // AVATARLARI YÜKLE
  // =====================================================

  static Future<void> loadAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _selectedAvatar =
          prefs.getString(StorageKeys.selectedAvatar) ?? '👦';
    } catch (e) {
      debugPrint('❌ AVATAR AYARI YÜKLENEMEDİ: $e');
    }
  }

  // =====================================================
  // AVATAR KAYDET
  // =====================================================

  static Future<void> setAvatar(String avatar) async {
    _selectedAvatar = avatar;

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        StorageKeys.selectedAvatar,
        avatar,
      );
    } catch (e) {
      debugPrint('❌ AVATAR KAYDEDİLEMEDİ: $e');
    }
  }
}