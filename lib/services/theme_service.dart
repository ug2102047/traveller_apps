import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal();

  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);
  static const _prefKey = 'isDarkMode';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_prefKey) ?? false;
    mode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDark(bool dark) async {
    mode.value = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, dark);
  }

  Future<void> toggle() async {
    final isDark = mode.value == ThemeMode.dark;
    await setDark(!isDark);
  }
}
