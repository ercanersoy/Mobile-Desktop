// task_manager.dart - Lists the open windows and memory usage
//
// Copyright (c) 2025 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/native_system.dart';
import '../core/settings.dart';
import '../desktop/window_manager.dart';
import '../widgets/retro.dart';
import 'app_registry.dart';

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  Timer? _timer;
  int? _memTotal;
  int? _memAvailable;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _readMemory();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (TickerMode.of(context)) _readMemory();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _readMemory() async {
    final info = await NativeSystem.memoryInfo();
    if (!mounted) return;
    setState(() {
      _memTotal = (info['total'] as num?)?.toInt();
      _memAvailable = (info['available'] as num?)?.toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    final manager = WindowManagerScope.of(context);
    final own = WindowScope.maybeOf(context);
    final windows = manager.windowsByOpenOrder;
    final selected = _selectedId == null ? null : manager.byId(_selectedId!);
    final total = _memTotal;
    final available = _memAvailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            context.tr('running_apps').replaceAll('{count}', '${windows.length}'),
            style: TextStyle(color: colors.text, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Bevel(
            sunken: true,
            color: colors.field,
            child: ListView.builder(
              itemCount: windows.length,
              itemBuilder: (context, index) {
                final window = windows[index];
                final state = window.minimized
                    ? context.tr('state_minimized')
                    : window.maximized
                        ? context.tr('state_maximized')
                        : context.tr('state_normal');
                return ListTile(
                  dense: true,
                  selected: window.id == _selectedId,
                  selectedTileColor: colors.selection.withAlpha(50),
                  leading: Icon(window.icon, color: colors.text),
                  title: Text(
                    Apps.titleOf(context, window),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.text),
                  ),
                  subtitle: Text(
                    window == own ? '$state • ${context.tr('this_window')}' : state,
                    style: TextStyle(color: colors.disabledText, fontSize: 11),
                  ),
                  onTap: () => setState(() => _selectedId = window.id),
                  onLongPress: () => manager.focus(window.id),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: RetroButton(
                    onPressed: selected == null
                        ? null
                        : () => manager.focus(selected.id),
                    child: Text(context.tr('switch_to')),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: RetroButton(
                    onPressed: selected == null
                        ? null
                        : () {
                            manager.close(selected.id);
                            setState(() => _selectedId = null);
                          },
                    child: Text(context.tr('end_task')),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
          child: Bevel(
            width: 1,
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  total == null || available == null
                      ? context.tr('sec_memory')
                      : '${context.tr('sec_memory')}: '
                          '${formatBytes(total - available)} / ${formatBytes(total)}',
                  style: TextStyle(color: colors.text, fontSize: 12),
                ),
                const SizedBox(height: 4),
                UsageBar(
                  value: total == null || available == null || total == 0
                      ? 0
                      : (total - available) / total,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
