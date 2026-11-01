// window_manager.dart - Keeps track of the open windows
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Called before a window closes. Returning false keeps it open
/// (for example when a document has unsaved changes).
typedef CloseGuard = Future<bool> Function();

/// One open window on the desktop.
class AppWindow {
  AppWindow({
    required this.id,
    required this.appId,
    this.title,
    required this.icon,
    required this.rect,
    this.args = const {},
    this.maximized = false,
  });

  final int id;
  final String appId;
  final Map<String, dynamic> args;
  /// Custom title. When null the translated app name is shown.
  String? title;
  IconData icon;
  Rect rect;
  bool maximized;
  bool minimized = false;
  CloseGuard? closeGuard;

  /// The app content. It is created once, so moving the window does not
  /// rebuild the app.
  Widget? content;
}

class WindowManager extends ChangeNotifier {
  final List<AppWindow> _windows = [];
  int _nextId = 1;
  int _cascade = 0;

  /// Size of the area above the taskbar. Updated by the desktop layout.
  Size desktopSize = const Size(360, 640);

  static const double minWidth = 180;
  static const double minHeight = 140;

  /// Windows from bottom to top.
  List<AppWindow> get windows => List.unmodifiable(_windows);

  /// Windows in the order they were opened (for the taskbar).
  List<AppWindow> get windowsByOpenOrder =>
      List.of(_windows)..sort((a, b) => a.id.compareTo(b.id));

  AppWindow? get focused {
    for (final window in _windows.reversed) {
      if (!window.minimized) return window;
    }
    return null;
  }

  AppWindow? byId(int id) {
    for (final window in _windows) {
      if (window.id == id) return window;
    }
    return null;
  }

  /// Opens a new window and brings it to the front.
  AppWindow open({
    required String appId,
    String? title,
    required IconData icon,
    required Size preferredSize,
    Map<String, dynamic> args = const {},
    bool maximized = false,
  }) {
    final width = math.min(preferredSize.width, desktopSize.width - 8);
    final height = math.min(preferredSize.height, desktopSize.height - 8);
    final step = 24.0 * (_cascade % 6);
    _cascade++;
    var left = 8.0 + step;
    var top = 8.0 + step;
    if (left + width > desktopSize.width) {
      left = math.max(0.0, desktopSize.width - width);
    }
    if (top + height > desktopSize.height) {
      top = math.max(0.0, desktopSize.height - height);
    }
    final window = AppWindow(
      id: _nextId++,
      appId: appId,
      title: title,
      icon: icon,
      rect: Rect.fromLTWH(left, top, math.max(width, minWidth),
          math.max(height, minHeight)),
      args: args,
      maximized: maximized,
    );
    _windows.add(window);
    notifyListeners();
    return window;
  }

  /// Closes a window after asking its close guard.
  Future<void> close(int id, {bool force = false}) async {
    final window = byId(id);
    if (window == null) return;
    if (!force && window.closeGuard != null) {
      final allowed = await window.closeGuard!();
      if (!allowed) return;
    }
    _windows.remove(window);
    if (_windows.isEmpty) _cascade = 0;
    notifyListeners();
  }

  void focus(int id) {
    final window = byId(id);
    if (window == null) return;
    final alreadyOnTop = _windows.last == window && !window.minimized;
    if (alreadyOnTop) return;
    window.minimized = false;
    _windows.remove(window);
    _windows.add(window);
    notifyListeners();
  }

  void minimize(int id) {
    final window = byId(id);
    if (window == null || window.minimized) return;
    window.minimized = true;
    notifyListeners();
  }

  void toggleMaximize(int id) {
    final window = byId(id);
    if (window == null) return;
    window.maximized = !window.maximized;
    focus(id);
    notifyListeners();
  }

  /// Taskbar button behaviour: minimize the front window, otherwise
  /// restore and focus.
  void toggleFromTaskbar(int id) {
    final window = byId(id);
    if (window == null) return;
    if (focused == window) {
      minimize(id);
    } else {
      focus(id);
    }
  }

  void minimizeAll() {
    for (final window in _windows) {
      window.minimized = true;
    }
    notifyListeners();
  }

  void move(int id, Offset delta) {
    final window = byId(id);
    if (window == null || window.maximized) return;
    final rect = window.rect.shift(delta);
    // Keep part of the title bar on screen so the window can be grabbed.
    final left = _clamp(rect.left, 60 - rect.width, desktopSize.width - 60);
    final top = _clamp(rect.top, 0, desktopSize.height - 32);
    window.rect = Rect.fromLTWH(left, top, rect.width, rect.height);
    notifyListeners();
  }

  void resize(int id, Offset delta) {
    final window = byId(id);
    if (window == null || window.maximized) return;
    final rect = window.rect;
    final width =
        _clamp(rect.width + delta.dx, minWidth, desktopSize.width - rect.left);
    final height = _clamp(
        rect.height + delta.dy, minHeight, desktopSize.height - rect.top);
    window.rect = Rect.fromLTWH(rect.left, rect.top, width, height);
    notifyListeners();
  }

  void setTitle(int id, String? title) {
    final window = byId(id);
    if (window == null || window.title == title) return;
    window.title = title;
    notifyListeners();
  }

  /// Rectangle where the window is drawn, fitted to the current screen.
  Rect visibleRect(AppWindow window) {
    if (window.maximized) return Offset.zero & desktopSize;
    final width = math.min(window.rect.width, desktopSize.width);
    final height = math.min(window.rect.height, desktopSize.height);
    final left = _clamp(window.rect.left, 60 - width, desktopSize.width - 60);
    final top = _clamp(window.rect.top, 0, desktopSize.height - 32);
    return Rect.fromLTWH(left, top, width, height);
  }

  /// Like [num.clamp], but never throws when [max] is below [min].
  static double _clamp(double value, double min, double max) {
    if (max < min) return min;
    return value < min ? min : (value > max ? max : value);
  }
}

/// Gives widgets access to the [WindowManager].
class WindowManagerScope extends InheritedNotifier<WindowManager> {
  const WindowManagerScope({
    super.key,
    required WindowManager manager,
    required super.child,
  }) : super(notifier: manager);

  /// Rebuilds the caller whenever windows change.
  static WindowManager of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<WindowManagerScope>();
    assert(scope != null, 'No WindowManagerScope found in context');
    return scope!.notifier!;
  }

  /// Reads the manager without rebuilding on changes.
  static WindowManager read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<WindowManagerScope>();
    assert(scope != null, 'No WindowManagerScope found in context');
    return scope!.notifier!;
  }
}

/// Lets app content find its own window (to change its title, add a
/// close guard or close itself).
class WindowScope extends InheritedWidget {
  const WindowScope({super.key, required this.window, required super.child});

  final AppWindow window;

  static AppWindow? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<WindowScope>()?.window;

  @override
  bool updateShouldNotify(WindowScope oldWidget) => window != oldWidget.window;
}
