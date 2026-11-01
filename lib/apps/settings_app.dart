// settings_app.dart - Settings window
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code Opus 5.5.

import 'package:flutter/material.dart';

import '../core/settings.dart';
import '../core/strings.dart';
import '../widgets/retro.dart';

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final colors = RetroColors.of(context);
    final textStyle = TextStyle(color: colors.text);

    Widget header(String key) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
          child: Text(
            context.tr(key),
            style: TextStyle(
              color: colors.selection,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );

    Widget toggle(IconData icon, String key, bool value,
        ValueChanged<bool> onChanged) {
      return SwitchListTile(
        secondary: Icon(icon, color: colors.text),
        title: Text(context.tr(key), style: textStyle),
        value: value,
        onChanged: onChanged,
        dense: true,
      );
    }

    return ListView(
      children: [
        header('appearance'),
        toggle(Icons.dark_mode, 'dark_theme', settings.isDarkMode,
            (value) => settings.isDarkMode = value),
        ListTile(
          dense: true,
          leading: Icon(Icons.wallpaper, color: colors.text),
          title: Text(context.tr('wallpaper_color'), style: textStyle),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final color in kWallpaperColors)
                  GestureDetector(
                    onTap: () => settings.wallpaperColor = color,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(color),
                        border: Border.all(
                          color: settings.wallpaperColor == color
                              ? colors.selection
                              : colors.shadow,
                          width: settings.wallpaperColor == color ? 3 : 1,
                        ),
                      ),
                      child: settings.wallpaperColor == color
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
        toggle(Icons.apps, 'show_desktop_icons', settings.showDesktopIcons,
            (value) => settings.showDesktopIcons = value),
        toggle(Icons.fullscreen, 'open_maximized',
            settings.openWindowsMaximized,
            (value) => settings.openWindowsMaximized = value),
        header('language_and_time'),
        ListTile(
          dense: true,
          leading: Icon(Icons.language, color: colors.text),
          title: Text(context.tr('language'), style: textStyle),
          trailing: DropdownButton<String>(
            value: settings.language,
            dropdownColor: colors.face,
            style: textStyle,
            onChanged: (value) {
              if (value != null) settings.language = value;
            },
            items: [
              for (final code in kSupportedLanguages)
                DropdownMenuItem(
                  value: code,
                  child: Text(languageName(code)),
                ),
            ],
          ),
        ),
        toggle(Icons.schedule, 'clock_24h', settings.use24HourClock,
            (value) => settings.use24HourClock = value),
        toggle(Icons.timer_outlined, 'show_seconds', settings.showSeconds,
            (value) => settings.showSeconds = value),
        header('notepad_settings'),
        ListTile(
          dense: true,
          leading: Icon(Icons.format_size, color: colors.text),
          title: Text(context.tr('font_size'), style: textStyle),
          subtitle: Slider(
            value: settings.notepadFontSize,
            min: 10,
            max: 32,
            divisions: 11,
            label: settings.notepadFontSize.round().toString(),
            onChanged: (value) => settings.notepadFontSize = value,
          ),
        ),
      ],
    );
  }
}
