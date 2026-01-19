import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'app_theme_mode';
  static late SharedPreferences _prefs;
  
  // ValueNotifier to notify listeners when theme changes
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  /// Initialize theme service and load saved theme
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs.getString(_themeKey);
    
    if (savedTheme != null) {
      themeNotifier.value = _themeModeFromString(savedTheme);
    } else {
      themeNotifier.value = ThemeMode.light;
    }
    
    print('🎨 Theme initialized: ${themeNotifier.value}');
  }

  /// Get current theme mode
  static ThemeMode get currentTheme => themeNotifier.value;

  /// Check if dark mode is enabled
  static bool get isDarkMode => themeNotifier.value == ThemeMode.dark;

  /// Set theme mode and persist to storage
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeNotifier.value = mode;
    await _prefs.setString(_themeKey, _themeModeToString(mode));
    print('🎨 Theme changed to: $mode');
  }

  /// Toggle between light and dark mode
  static Future<void> toggleTheme() async {
    final newMode = themeNotifier.value == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Convert ThemeMode to String for storage
  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Convert String to ThemeMode
  static ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
}