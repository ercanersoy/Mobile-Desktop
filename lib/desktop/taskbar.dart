// taskbar.dart - Start button, window buttons and clock
//
// Copyright (c) 2025 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.

import 'dart:async';

import 'package:flutter/material.dart';

import '../apps/app_registry.dart';
import '../core/native_system.dart';
import '../core/settings.dart';
import '../widgets/retro.dart';
import 'window_manager.dart';

const double kTaskbarHeight = 42;

class Taskbar extends StatelessWidget {
  const Taskbar({
    super.key,
    required this.startMenuOpen,
    required this.onStartPressed,
  });

  final bool startMenuOpen;
  final VoidCallback onStartPressed;

  @override
  Widget build(BuildContext context) {
    final manager = WindowManagerScope.of(context);
    final focused = manager.focused;
    final windows = manager.windowsByOpenOrder;

    return Bevel(
      padding: const EdgeInsets.all(3),
      child: SizedBox(
        height: kTaskbarHeight - 10,
        child: Row(
          children: [
            RetroButton(
              pressed: startMenuOpen,
              onPressed: onStartPressed,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.window, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    context.tr('start'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: windows.length,
                separatorBuilder: (_, __) => const SizedBox(width: 3),
                itemBuilder: (context, index) {
                  final window = windows[index];
                  return SizedBox(
                    width: 120,
                    child: RetroButton(
                      pressed: window == focused,
                      onPressed: () => manager.toggleFromTaskbar(window.id),
                      onLongPress: () =>
                          _showWindowMenu(context, manager, window),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        children: [
                          Icon(window.icon, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              Apps.titleOf(context, window),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: window == focused
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 4),
            const _Tray(),
          ],
        ),
      ),
    );
  }

  Future<void> _showWindowMenu(
      BuildContext context, WindowManager manager, AppWindow window) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        16,
        topLeft.dy - 150,
        overlay.size.width - 16,
        overlay.size.height - topLeft.dy,
      ),
      items: [
        PopupMenuItem(value: 'restore', child: Text(context.tr('restore'))),
        PopupMenuItem(value: 'minimize', child: Text(context.tr('minimize'))),
        PopupMenuItem(value: 'maximize', child: Text(context.tr('maximize'))),
        PopupMenuItem(value: 'close', child: Text(context.tr('close'))),
      ],
    );
    switch (choice) {
      case 'restore':
        if (window.maximized) manager.toggleMaximize(window.id);
        manager.focus(window.id);
      case 'minimize':
        manager.minimize(window.id);
      case 'maximize':
        if (!window.maximized) manager.toggleMaximize(window.id);
        manager.focus(window.id);
      case 'close':
        manager.close(window.id);
    }
  }
}

/// Battery level and clock on the right side of the taskbar.
class _Tray extends StatefulWidget {
  const _Tray();

  @override
  State<_Tray> createState() => _TrayState();
}

class _TrayState extends State<_Tray> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  int? _battery;
  bool _charging = false;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    _readBattery();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _ticks++;
      if (_ticks % 60 == 0) _readBattery();
      setState(() => _now = DateTime.now());
    });
  }

  Future<void> _readBattery() async {
    final info = await NativeSystem.batteryInfo();
    final level = info['level'];
    if (!mounted) return;
    setState(() {
      _battery = level is int && level >= 0 ? level : null;
      _charging = info['charging'] == true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    return GestureDetector(
      onTap: () => Apps.launch(context, 'calendar'),
      onLongPress: () => Apps.launch(context, 'clock'),
      child: Bevel(
        sunken: true,
        width: 1,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_battery != null) ...[
              Icon(
                _charging ? Icons.battery_charging_full : _batteryIcon(),
                size: 16,
              ),
              Text('$_battery%', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
            ],
            Text(
              formatClock(_now, settings),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  IconData _batteryIcon() {
    final level = _battery ?? 100;
    if (level > 90) return Icons.battery_full;
    if (level > 60) return Icons.battery_5_bar;
    if (level > 40) return Icons.battery_4_bar;
    if (level > 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }
}

/// Formats the time using the clock settings.
String formatClock(DateTime time, AppSettings settings,
    {bool forceSeconds = false}) {
  String two(int n) => n.toString().padLeft(2, '0');
  var hour = time.hour;
  var suffix = '';
  if (!settings.use24HourClock) {
    suffix = hour < 12 ? ' AM' : ' PM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
  }
  final seconds =
      settings.showSeconds || forceSeconds ? ':${two(time.second)}' : '';
  final hourText = settings.use24HourClock ? two(hour) : '$hour';
  return '$hourText:${two(time.minute)}$seconds$suffix';
}
