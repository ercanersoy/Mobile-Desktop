// main.dart - Main of the Mobile Desktop app
//
// Copyright (c) 2025 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Used ChatGPT GPT-4o, GitHub Copilot GPT-4o, GitHub Copilot GPT-4.1,
// GitHub Copilot Claude 3.7 Sonnet and Claude Code for writting this program.

import 'package:flutter/material.dart';

import 'core/settings.dart';
import 'desktop/desktop_screen.dart';
import 'desktop/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(MyApp(settings: settings));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final WindowManager _windowManager = WindowManager();

  @override
  void dispose() {
    _windowManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: widget.settings,
      child: WindowManagerScope(
        manager: _windowManager,
        child: ListenableBuilder(
          listenable: widget.settings,
          builder: (context, _) {
            final dark = widget.settings.isDarkMode;
            return MaterialApp(
              title: 'Mobile Desktop',
              debugShowCheckedModeBanner: false,
              theme: buildTheme(dark ? Brightness.dark : Brightness.light),
              home: const DesktopScreen(),
            );
          },
        ),
      ),
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: dark ? const Color(0xFF1E88E5) : const Color(0xFF000080),
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    brightness: brightness,
    visualDensity: VisualDensity.compact,
    scaffoldBackgroundColor:
        dark ? const Color(0xFF22272A) : const Color(0xFF008080),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF0D47A1) : const Color(0xFF000080),
      foregroundColor: Colors.white,
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 600),
    ),
  );
}
