import 'package:flutter/material.dart';
import 'storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static final ValueNotifier<ThemeMode> themeNotifier =
  ValueNotifier(ThemeMode.light);

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool(StorageKeys.darkMode) ?? false;

    themeNotifier.value =
    isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(StorageKeys.darkMode, value);

    themeNotifier.value =
    value ? ThemeMode.dark : ThemeMode.light;
  }
}