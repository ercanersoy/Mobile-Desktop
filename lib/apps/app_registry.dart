// app_registry.dart - List of the built-in apps and how to start them
//
// Copyright (c) 2025 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.

import 'package:flutter/material.dart';

import '../core/settings.dart';
import '../core/strings.dart';
import '../desktop/window_manager.dart';
import 'about.dart';
import 'calculator.dart';
import 'calendar.dart';
import 'clock.dart';
import 'file_manager.dart';
import 'image_viewer.dart';
import 'notepad.dart';
import 'paint.dart';
import 'settings_app.dart';
import 'system_info.dart';
import 'task_manager.dart';
import 'terminal.dart';

typedef AppBuilder = Widget Function(AppWindow window);

class AppInfo {
  const AppInfo({
    required this.id,
    required this.nameKey,
    required this.icon,
    required this.color,
    required this.preferredSize,
    required this.builder,
    this.singleInstance = false,
    this.onDesktop = true,
    this.inStartMenu = true,
  });

  final String id;
  final String nameKey;
  final IconData icon;

  /// Icon color on the desktop and in the start menu.
  final Color color;
  final Size preferredSize;
  final AppBuilder builder;

  /// Focus the open window instead of opening a second one.
  final bool singleInstance;
  final bool onDesktop;
  final bool inStartMenu;
}

class Apps {
  Apps._();

  static final List<AppInfo> all = [
    AppInfo(
      id: 'files',
      nameKey: 'app_files',
      icon: Icons.folder,
      color: Colors.amber.shade700,
      preferredSize: const Size(380, 460),
      builder: (window) => FileManagerApp(
        initialPath: window.args['path'] as String?,
      ),
    ),
    AppInfo(
      id: 'notepad',
      nameKey: 'app_notepad',
      icon: Icons.description,
      color: Colors.lightBlue.shade600,
      preferredSize: const Size(360, 420),
      builder: (window) => NotepadApp(path: window.args['path'] as String?),
    ),
    AppInfo(
      id: 'calculator',
      nameKey: 'app_calculator',
      icon: Icons.calculate,
      color: Colors.green.shade600,
      preferredSize: const Size(290, 420),
      builder: (window) => const CalculatorApp(),
    ),
    AppInfo(
      id: 'sysinfo',
      nameKey: 'app_sysinfo',
      icon: Icons.memory,
      color: Colors.teal.shade600,
      preferredSize: const Size(360, 480),
      builder: (window) => const SystemInfoApp(),
      singleInstance: true,
    ),
    AppInfo(
      id: 'paint',
      nameKey: 'app_paint',
      icon: Icons.brush,
      color: Colors.pink.shade400,
      preferredSize: const Size(380, 460),
      builder: (window) => const PaintApp(),
    ),
    AppInfo(
      id: 'terminal',
      nameKey: 'app_terminal',
      icon: Icons.terminal,
      color: Colors.blueGrey.shade700,
      preferredSize: const Size(380, 340),
      builder: (window) => const TerminalApp(),
    ),
    AppInfo(
      id: 'clock',
      nameKey: 'app_clock',
      icon: Icons.access_time,
      color: Colors.indigo.shade400,
      preferredSize: const Size(320, 420),
      builder: (window) => const ClockApp(),
      singleInstance: true,
    ),
    AppInfo(
      id: 'calendar',
      nameKey: 'app_calendar',
      icon: Icons.calendar_month,
      color: Colors.red.shade500,
      preferredSize: const Size(340, 440),
      builder: (window) => const CalendarApp(),
      singleInstance: true,
    ),
    AppInfo(
      id: 'taskmgr',
      nameKey: 'app_taskmgr',
      icon: Icons.view_list,
      color: Colors.deepPurple.shade400,
      preferredSize: const Size(340, 400),
      builder: (window) => const TaskManagerApp(),
      singleInstance: true,
    ),
    AppInfo(
      id: 'imageviewer',
      nameKey: 'app_imageviewer',
      icon: Icons.image,
      color: Colors.orange.shade600,
      preferredSize: const Size(380, 420),
      builder: (window) => ImageViewerApp(path: window.args['path'] as String?),
      onDesktop: false,
    ),
    AppInfo(
      id: 'settings',
      nameKey: 'app_settings',
      icon: Icons.settings,
      color: Colors.grey.shade600,
      preferredSize: const Size(340, 460),
      builder: (window) => const SettingsApp(),
      singleInstance: true,
      inStartMenu: false,
    ),
    AppInfo(
      id: 'about',
      nameKey: 'app_about',
      icon: Icons.info,
      color: Colors.blue.shade600,
      preferredSize: const Size(330, 420),
      builder: (window) => const AboutApp(),
      singleInstance: true,
      onDesktop: false,
      inStartMenu: false,
    ),
  ];

  static AppInfo? byId(String id) {
    for (final app in all) {
      if (app.id == id) return app;
    }
    return null;
  }

  /// Opens [appId] in a new window (or focuses it for single-instance apps).
  static void launch(
    BuildContext context,
    String appId, {
    Map<String, dynamic> args = const {},
  }) {
    final app = byId(appId);
    if (app == null) return;
    final manager = WindowManagerScope.read(context);
    final settings = SettingsScope.read(context);
    if (app.singleInstance) {
      for (final window in manager.windows) {
        if (window.appId == appId) {
          manager.focus(window.id);
          return;
        }
      }
    }
    final window = manager.open(
      appId: app.id,
      icon: app.icon,
      preferredSize: app.preferredSize,
      args: args,
      maximized: settings.openWindowsMaximized,
    );
    window.content = app.builder(window);
  }

  /// Title shown on the window and the taskbar.
  static String titleOf(BuildContext context, AppWindow window) {
    final custom = window.title;
    if (custom != null) return custom;
    final app = byId(window.appId);
    if (app == null) return window.appId;
    return translate(SettingsScope.of(context).language, app.nameKey);
  }
}
