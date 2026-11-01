// desktop_screen.dart - Wallpaper, desktop icons, windows and taskbar
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code Opus 5.5.

import 'package:flutter/material.dart';

import '../apps/app_registry.dart';
import '../core/settings.dart';
import 'start_menu.dart';
import 'taskbar.dart';
import 'window_frame.dart';
import 'window_manager.dart';

class DesktopScreen extends StatefulWidget {
  const DesktopScreen({super.key});

  @override
  State<DesktopScreen> createState() => _DesktopScreenState();
}

class _DesktopScreenState extends State<DesktopScreen> {
  bool _startMenuOpen = false;

  void _toggleStartMenu() => setState(() => _startMenuOpen = !_startMenuOpen);

  void _closeStartMenu() {
    if (_startMenuOpen) setState(() => _startMenuOpen = false);
  }

  /// Android back button: close the start menu, then the front window.
  void _handleBack(WindowManager manager) {
    if (_startMenuOpen) {
      _closeStartMenu();
      return;
    }
    final focused = manager.focused;
    if (focused != null) manager.close(focused.id);
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final manager = WindowManagerScope.of(context);
    final focused = manager.focused;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack(manager);
      },
      child: Scaffold(
        backgroundColor: Color(settings.wallpaperColor),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    manager.desktopSize = constraints.biggest;
                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _closeStartMenu,
                            onLongPressStart: (details) =>
                                _showDesktopMenu(context, details.globalPosition),
                            child: settings.showDesktopIcons
                                ? const _DesktopIcons()
                                : const SizedBox.expand(),
                          ),
                        ),
                        for (final window in manager.windows)
                          _buildWindow(manager, window, focused),
                        if (_startMenuOpen) ...[
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _closeStartMenu,
                            ),
                          ),
                          Positioned(
                            left: 2,
                            bottom: 0,
                            child: StartMenu(onClose: _closeStartMenu),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              Taskbar(
                startMenuOpen: _startMenuOpen,
                onStartPressed: _toggleStartMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindow(
      WindowManager manager, AppWindow window, AppWindow? focused) {
    final rect = manager.visibleRect(window);
    return Positioned(
      key: ValueKey(window.id),
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Offstage(
        offstage: window.minimized,
        child: TickerMode(
          enabled: !window.minimized,
          child: WindowFrame(window: window, active: window == focused),
        ),
      ),
    );
  }

  Future<void> _showDesktopMenu(BuildContext context, Offset position) async {
    final manager = WindowManagerScope.read(context);
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
            value: 'show_desktop', child: Text(context.tr('show_desktop'))),
        PopupMenuItem(value: 'files', child: Text(context.tr('app_files'))),
        PopupMenuItem(
            value: 'wallpaper', child: Text(context.tr('change_wallpaper'))),
        PopupMenuItem(
            value: 'settings', child: Text(context.tr('app_settings'))),
      ],
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'show_desktop':
        manager.minimizeAll();
      case 'files':
        Apps.launch(context, 'files');
      case 'wallpaper':
      case 'settings':
        Apps.launch(context, 'settings');
    }
  }
}

/// Grid of app shortcuts on the wallpaper.
class _DesktopIcons extends StatelessWidget {
  const _DesktopIcons();

  @override
  Widget build(BuildContext context) {
    final apps = Apps.all.where((app) => app.onDesktop).toList();
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Wrap(
        direction: Axis.vertical,
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final app in apps)
            _DesktopIcon(
              icon: app.icon,
              color: app.color,
              label: context.tr(app.nameKey),
              onTap: () => Apps.launch(context, app.id),
            ),
        ],
      ),
    );
  }
}

class _DesktopIcon extends StatelessWidget {
  const _DesktopIcon({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 86,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        splashColor: Colors.white24,
        // Align to the top so every icon sits on the same grid line,
        // whether its label takes one line or two.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 3,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                shadows: [
                  Shadow(color: Colors.black, offset: Offset(1, 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
