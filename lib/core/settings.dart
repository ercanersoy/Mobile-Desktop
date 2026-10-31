// settings.dart - Persistent user settings of the Mobile Desktop app
//
// Copyright (c) 2025 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings.dart';

/// Wallpaper colors the user can choose from.
const List<int> kWallpaperColors = [
  0xFF008080, // Teal
  0xFF00CED1, // Turquoise
  0xFF22272A, // Graphite
  0xFF1E3A5F, // Navy
  0xFF3A5F1E, // Forest
  0xFF5F1E3A, // Wine
  0xFF4B3A6B, // Purple
  0xFF6B6B6B, // Grey
];

/// Holds every user preference and stores it with [SharedPreferences].
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(prefs);
  }

  bool get isDarkMode => _prefs.getBool('isDarkMode') ?? true;
  set isDarkMode(bool value) => _setBool('isDarkMode', value);

  /// Language code: 'tr' or 'en'. Defaults to the device language.
  String get language {
    final saved = _prefs.getString('language');
    if (saved != null && kSupportedLanguages.contains(saved)) return saved;
    final device = PlatformDispatcher.instance.locale.languageCode;
    return kSupportedLanguages.contains(device) ? device : 'en';
  }

  set language(String value) {
    _prefs.setString('language', value);
    notifyListeners();
  }

  int get wallpaperColor {
    final saved = _prefs.getInt('wallpaperColor');
    if (saved != null) return saved;
    return isDarkMode ? 0xFF22272A : 0xFF008080;
  }

  set wallpaperColor(int value) {
    _prefs.setInt('wallpaperColor', value);
    notifyListeners();
  }

  bool get use24HourClock => _prefs.getBool('use24HourClock') ?? true;
  set use24HourClock(bool value) => _setBool('use24HourClock', value);

  bool get showSeconds => _prefs.getBool('showSeconds') ?? false;
  set showSeconds(bool value) => _setBool('showSeconds', value);

  bool get showDesktopIcons => _prefs.getBool('showDesktopIcons') ?? true;
  set showDesktopIcons(bool value) => _setBool('showDesktopIcons', value);

  bool get openWindowsMaximized =>
      _prefs.getBool('openWindowsMaximized') ?? false;
  set openWindowsMaximized(bool value) =>
      _setBool('openWindowsMaximized', value);

  double get notepadFontSize => _prefs.getDouble('notepadFontSize') ?? 15;
  set notepadFontSize(double value) {
    _prefs.setDouble('notepadFontSize', value);
    notifyListeners();
  }

  /// Gives direct access for apps that keep their own small data
  /// (for example the calendar notes).
  SharedPreferences get prefs => _prefs;

  void _setBool(String key, bool value) {
    _prefs.setBool(key, value);
    notifyListeners();
  }
}

/// Makes [AppSettings] available to the widget tree and rebuilds
/// dependent widgets when a setting changes.
class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'No SettingsScope found in context');
    return scope!.notifier!;
  }

  /// Reads the settings without rebuilding when they change.
  static AppSettings read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'No SettingsScope found in context');
    return scope!.notifier!;
  }
}

extension LocalizedContext on BuildContext {
  /// Returns the translated text for [key] in the current language.
  String tr(String key) => translate(SettingsScope.of(this).language, key);
}
