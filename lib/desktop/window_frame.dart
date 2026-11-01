// window_frame.dart - Title bar, borders and buttons of a window
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code.

import 'package:flutter/material.dart';

import '../apps/app_registry.dart';
import '../core/settings.dart';
import '../widgets/retro.dart';
import 'window_manager.dart';

class WindowFrame extends StatelessWidget {
  const WindowFrame({
    super.key,
    required this.window,
    required this.active,
  });

  final AppWindow window;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final manager = WindowManagerScope.read(context);
    final colors = RetroColors.of(context);
    final title = Apps.titleOf(context, window);

    return Listener(
      // Any touch inside the window brings it to the front.
      onPointerDown: (_) => manager.focus(window.id),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            if (active)
              const BoxShadow(
                color: Color(0x66000000),
                blurRadius: 8,
                offset: Offset(2, 3),
              ),
          ],
        ),
        child: Bevel(
          padding: const EdgeInsets.all(2),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) =>
                        manager.move(window.id, details.delta),
                    onDoubleTap: () => manager.toggleMaximize(window.id),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.only(left: 6, right: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: active
                              ? colors.activeTitle
                              : colors.inactiveTitle,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(window.icon, size: 18, color: colors.titleText),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.titleText,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          _TitleButton(
                            icon: Icons.minimize,
                            tooltip: context.tr('minimize'),
                            onPressed: () => manager.minimize(window.id),
                          ),
                          _TitleButton(
                            icon: window.maximized
                                ? Icons.filter_none
                                : Icons.crop_square,
                            tooltip: context.tr(
                                window.maximized ? 'restore' : 'maximize'),
                            onPressed: () => manager.toggleMaximize(window.id),
                          ),
                          const SizedBox(width: 2),
                          _TitleButton(
                            icon: Icons.close,
                            tooltip: context.tr('close'),
                            onPressed: () => manager.close(window.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: ClipRect(
                      child: Material(
                        color: colors.face,
                        child: WindowScope(
                          window: window,
                          child: window.content ?? const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!window.maximized)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) =>
                        manager.resize(window.id, details.delta),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CustomPaint(
                        painter: _ResizeGripPainter(
                          light: colors.highlight,
                          dark: colors.shadow,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleButton extends StatelessWidget {
  const _TitleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: SizedBox(
        width: 30,
        height: 26,
        child: RetroButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }
}

/// Diagonal lines in the bottom-right corner, used to resize.
class _ResizeGripPainter extends CustomPainter {
  _ResizeGripPainter({required this.light, required this.dark});

  final Color light;
  final Color dark;

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()
      ..color = light
      ..strokeWidth = 1.5;
    final darkPaint = Paint()
      ..color = dark
      ..strokeWidth = 1.5;
    for (var i = 0; i < 3; i++) {
      final offset = 6.0 + i * 6;
      canvas.drawLine(Offset(size.width - offset, size.height - 2),
          Offset(size.width - 2, size.height - offset), darkPaint);
      canvas.drawLine(Offset(size.width - offset + 1.5, size.height - 2),
          Offset(size.width - 2, size.height - offset + 1.5), lightPaint);
    }
  }

  @override
  bool shouldRepaint(_ResizeGripPainter oldDelegate) =>
      light != oldDelegate.light || dark != oldDelegate.dark;
}
