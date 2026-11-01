// system_info.dart - Shows information about the device
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code Opus 5.5.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/native_system.dart';
import '../core/settings.dart';
import '../desktop/window_manager.dart';
import '../core/version.dart';
import '../widgets/retro.dart';

class SystemInfoApp extends StatefulWidget {
  const SystemInfoApp({super.key});

  @override
  State<SystemInfoApp> createState() => _SystemInfoAppState();
}

class _SystemInfoAppState extends State<SystemInfoApp> {
  Map<String, dynamic> _device = {};
  Map<String, dynamic> _memory = {};
  Map<String, dynamic> _storage = {};
  Map<String, dynamic> _battery = {};
  Map<String, String> _cpu = {};
  int? _uptime;
  bool _loaded = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadStatic();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadDynamic());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatic() async {
    final device = await NativeSystem.deviceInfo();
    final cpu = await NativeSystem.cpuDetails();
    if (!mounted) return;
    setState(() {
      _device = device;
      _cpu = cpu;
    });
    await _loadDynamic();
  }

  Future<void> _loadDynamic() async {
    // Do not waste battery while the window is minimized.
    if (!TickerMode.valuesOf(context).enabled && _loaded) return;
    final results = await Future.wait([
      NativeSystem.memoryInfo(),
      NativeSystem.storageInfo(),
      NativeSystem.batteryInfo(),
    ]);
    final uptime = await NativeSystem.uptimeMillis();
    if (!mounted) return;
    setState(() {
      _memory = results[0];
      _storage = results[1];
      _battery = results[2];
      _uptime = uptime;
      _loaded = true;
    });
  }

  String _formatUptime(int millis) {
    final d = Duration(milliseconds: millis);
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final parts = <String>[
      if (days > 0) '$days ${context.tr('days_short')}',
      if (days > 0 || hours > 0) '$hours ${context.tr('hours_short')}',
      '$minutes ${context.tr('minutes_short')}',
    ];
    return parts.join(' ');
  }

  String _osName() {
    if (Platform.isAndroid) {
      final version = _device['androidVersion'];
      return version == null ? 'Android' : 'Android $version';
    }
    return Platform.operatingSystem;
  }

  /// Text of all values, for the "copy" button.
  String _report(List<_Section> sections) {
    final buffer = StringBuffer();
    for (final section in sections) {
      buffer.writeln('[${section.title}]');
      for (final row in section.rows) {
        buffer.writeln('${row.key}: ${row.value}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    final media = MediaQuery.of(context);
    final windowCount = WindowManagerScope.of(context).windows.length;

    String value(Object? v) => v == null || '$v'.isEmpty ? '-' : '$v';

    final memTotal = (_memory['total'] as num?)?.toDouble();
    final memAvail = (_memory['available'] as num?)?.toDouble();
    final stTotal = (_storage['total'] as num?)?.toDouble();
    final stFree = (_storage['free'] as num?)?.toDouble();
    final batteryLevel = _battery['level'] as int?;

    final sections = <_Section>[
      _Section(context.tr('sec_device'), Icons.smartphone, [
        MapEntry(context.tr('manufacturer'), value(_device['manufacturer'])),
        MapEntry(context.tr('model'), value(_device['model'])),
        MapEntry(context.tr('brand'), value(_device['brand'])),
        MapEntry(context.tr('device_code'), value(_device['device'])),
      ]),
      _Section(context.tr('sec_os'), Icons.android, [
        MapEntry(context.tr('os'), _osName()),
        if (_device['sdkInt'] != null)
          MapEntry('API', value(_device['sdkInt'])),
        if (_device['securityPatch'] != null)
          MapEntry(context.tr('security_patch'), value(_device['securityPatch'])),
        MapEntry(context.tr('build'), value(_device['buildId'])),
        MapEntry(context.tr('kernel'), Platform.operatingSystemVersion),
        MapEntry(context.tr('uptime'),
            _uptime == null ? '-' : _formatUptime(_uptime!)),
        MapEntry(context.tr('language'), Platform.localeName),
      ]),
      _Section(context.tr('sec_cpu'), Icons.memory, [
        MapEntry(
            context.tr('cpu_model'),
            value(_device['socModel'] != null
                ? '${_device['socManufacturer'] ?? ''} ${_device['socModel']}'
                    .trim()
                : _cpu['model'] ?? _device['hardware'])),
        MapEntry(context.tr('cores'), '${Platform.numberOfProcessors}'),
        if (_cpu['maxFreq'] != null)
          MapEntry(context.tr('max_freq'), _cpu['maxFreq']!),
        MapEntry(context.tr('abis'), value(_device['abis'])),
      ]),
      _Section(context.tr('sec_memory'), Icons.developer_board, [
        MapEntry(context.tr('total'),
            memTotal == null ? '-' : formatBytes(memTotal)),
        MapEntry(context.tr('available'),
            memAvail == null ? '-' : formatBytes(memAvail)),
        MapEntry(
            context.tr('used'),
            memTotal == null || memAvail == null
                ? '-'
                : formatBytes(memTotal - memAvail)),
      ], usage: memTotal == null || memAvail == null || memTotal == 0
          ? null
          : (memTotal - memAvail) / memTotal),
      _Section(context.tr('sec_storage'), Icons.sd_storage, [
        MapEntry(context.tr('total'),
            stTotal == null ? '-' : formatBytes(stTotal)),
        MapEntry(context.tr('free'), stFree == null ? '-' : formatBytes(stFree)),
        MapEntry(
            context.tr('used'),
            stTotal == null || stFree == null
                ? '-'
                : formatBytes(stTotal - stFree)),
      ], usage: stTotal == null || stFree == null || stTotal == 0
          ? null
          : (stTotal - stFree) / stTotal),
      if (batteryLevel != null && batteryLevel >= 0)
        _Section(context.tr('sec_battery'), Icons.battery_std, [
          MapEntry(context.tr('level'), '$batteryLevel%'),
          MapEntry(
              context.tr('status'),
              _battery['full'] == true
                  ? context.tr('battery_full')
                  : _battery['charging'] == true
                      ? context.tr('charging')
                      : context.tr('discharging')),
          MapEntry(context.tr('temperature'),
              '${(_battery['temperature'] as num?)?.toStringAsFixed(1) ?? '-'} °C'),
          MapEntry(context.tr('voltage'), '${value(_battery['voltage'])} mV'),
          MapEntry(context.tr('technology'), value(_battery['technology'])),
        ], usage: batteryLevel / 100, usageColor: Colors.green.shade600),
      _Section(context.tr('sec_display'), Icons.monitor, [
        MapEntry(
            context.tr('resolution'),
            '${(media.size.width * media.devicePixelRatio).round()} × '
                '${(media.size.height * media.devicePixelRatio).round()} px'),
        MapEntry(context.tr('logical_size'),
            '${media.size.width.round()} × ${media.size.height.round()} dp'),
        MapEntry(context.tr('density'),
            '${media.devicePixelRatio.toStringAsFixed(2)}x '
                '(${(media.devicePixelRatio * 160).round()} dpi)'),
        MapEntry(
            context.tr('orientation'),
            context.tr(media.orientation == Orientation.portrait
                ? 'portrait'
                : 'landscape')),
      ]),
      _Section(context.tr('sec_app'), Icons.apps, [
        MapEntry(context.tr('version'), kAppVersion),
        MapEntry('Dart', Platform.version.split(' ').first),
        MapEntry(context.tr('open_windows'), '$windowCount'),
      ]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroToolbar(children: [
          ToolbarButton(
            icon: Icons.refresh,
            tooltip: context.tr('refresh'),
            onPressed: _loadStatic,
          ),
          ToolbarButton(
            icon: Icons.copy,
            tooltip: context.tr('copy_report'),
            onPressed: () async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              final copied = context.tr('copied');
              await Clipboard.setData(
                  ClipboardData(text: _report(sections)));
              messenger?.showSnackBar(SnackBar(content: Text(copied)));
            },
          ),
        ]),
        Expanded(
          child: !_loaded
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(6),
                  children: [
                    for (final section in sections)
                      _SectionView(section: section, colors: colors),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Section {
  _Section(this.title, this.icon, this.rows, {this.usage, this.usageColor});

  final String title;
  final IconData icon;
  final List<MapEntry<String, String>> rows;
  final double? usage;
  final Color? usageColor;
}

class _SectionView extends StatelessWidget {
  const _SectionView({required this.section, required this.colors});

  final _Section section;
  final RetroColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Bevel(
        width: 1,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(section.icon, size: 18, color: colors.selection),
                const SizedBox(width: 6),
                Text(
                  section.title,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (section.usage != null) ...[
              UsageBar(value: section.usage!, color: section.usageColor),
              const SizedBox(height: 4),
            ],
            for (final row in section.rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        row.key,
                        style: TextStyle(
                            color: colors.disabledText, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: SelectableText(
                        row.value,
                        style: TextStyle(color: colors.text, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
