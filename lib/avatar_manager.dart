import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarManager {
  static const String _avatarKey = 'selected_avatar';

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
          prefs.getString(_avatarKey) ?? '👦';
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
        _avatarKey,
        avatar,
      );
    } catch (e) {
      debugPrint('❌ AVATAR KAYDEDİLEMEDİ: $e');
    }
  }
}