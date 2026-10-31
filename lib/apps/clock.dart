// clock.dart - Clock, stopwatch and timer
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/settings.dart';
import '../core/strings.dart';
import '../desktop/taskbar.dart' show formatClock;
import '../widgets/retro.dart';

class ClockApp extends StatelessWidget {
  const ClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: colors.text,
            unselectedLabelColor: colors.disabledText,
            indicatorColor: colors.selection,
            tabs: [
              Tab(icon: const Icon(Icons.access_time), text: context.tr('clock')),
              Tab(icon: const Icon(Icons.timer), text: context.tr('stopwatch')),
              Tab(
                  icon: const Icon(Icons.hourglass_bottom),
                  text: context.tr('timer')),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [_ClockTab(), _StopwatchTab(), _TimerTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockTab extends StatefulWidget {
  const _ClockTab();

  @override
  State<_ClockTab> createState() => _ClockTabState();
}

class _ClockTabState extends State<_ClockTab> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (TickerMode.of(context)) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    final settings = SettingsScope.of(context);
    final lang = settings.language;
    final date = '${_now.day} ${monthName(lang, _now.month)} ${_now.year}, '
        '${weekdayName(lang, _now.weekday)}';
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight - 90)
            .clamp(80.0, 260.0)
            .toDouble();
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: _AnalogClockPainter(
                      time: _now,
                      face: colors.field,
                      ink: colors.text,
                      accent: Colors.red.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  formatClock(
                    _now,
                    settings,
                    forceSeconds: true,
                  ),
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(date, style: TextStyle(color: colors.text, fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  _AnalogClockPainter({
    required this.time,
    required this.face,
    required this.ink,
    required this.accent,
  });

  final DateTime time;
  final Color face;
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 2;
    canvas.drawCircle(center, radius, Paint()..color = face);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Hour and minute marks.
    for (var i = 0; i < 60; i++) {
      final angle = i * math.pi / 30;
      final hourMark = i % 5 == 0;
      final outer = center + Offset(math.sin(angle), -math.cos(angle)) * (radius - 4);
      final inner = center +
          Offset(math.sin(angle), -math.cos(angle)) *
              (radius - (hourMark ? 14 : 8));
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = ink
          ..strokeWidth = hourMark ? 3 : 1,
      );
    }

    void hand(double fraction, double length, double width, Color color) {
      final angle = fraction * 2 * math.pi;
      final end = center +
          Offset(math.sin(angle), -math.cos(angle)) * (radius * length);
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    final seconds = time.second;
    final minutes = time.minute + seconds / 60;
    final hours = (time.hour % 12) + minutes / 60;
    hand(hours / 12, 0.5, 6, ink);
    hand(minutes / 60, 0.75, 4, ink);
    hand(seconds / 60, 0.85, 2, accent);
    canvas.drawCircle(center, 5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_AnalogClockPainter oldDelegate) =>
      time != oldDelegate.time ||
      face != oldDelegate.face ||
      ink != oldDelegate.ink;
}

String _formatDuration(Duration d, {bool hundredths = true}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;
  final centis = (d.inMilliseconds % 1000) ~/ 10;
  final main = hours > 0
      ? '${two(hours)}:${two(minutes)}:${two(seconds)}'
      : '${two(minutes)}:${two(seconds)}';
  return hundredths ? '$main.${two(centis)}' : main;
}

class _StopwatchTab extends StatefulWidget {
  const _StopwatchTab();

  @override
  State<_StopwatchTab> createState() => _StopwatchTabState();
}

class _StopwatchTabState extends State<_StopwatchTab>
    with AutomaticKeepAliveClientMixin {
  final Stopwatch _stopwatch = Stopwatch();
  final List<Duration> _laps = [];
  Timer? _ticker;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _ticker?.cancel();
      } else {
        _stopwatch.start();
        _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  void _lapOrReset() {
    setState(() {
      if (_stopwatch.isRunning) {
        _laps.insert(0, _stopwatch.elapsed);
      } else {
        _stopwatch.reset();
        _laps.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = RetroColors.of(context);
    final running = _stopwatch.isRunning;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              _formatDuration(_stopwatch.elapsed),
              style: TextStyle(
                color: colors.text,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: RetroButton(
                    onPressed: _lapOrReset,
                    child: Text(context.tr(running ? 'lap' : 'reset')),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: RetroButton(
                    onPressed: _toggle,
                    child: Text(
                      context.tr(running ? 'stop' : 'start_timer'),
                      style: TextStyle(
                        color: running ? Colors.red.shade700 : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _laps.length,
              itemBuilder: (context, index) {
                final lap = _laps[index];
                final previous =
                    index + 1 < _laps.length ? _laps[index + 1] : Duration.zero;
                return ListTile(
                  dense: true,
                  leading: Text('#${_laps.length - index}',
                      style: TextStyle(color: colors.text)),
                  title: Text(_formatDuration(lap),
                      style: TextStyle(color: colors.text)),
                  trailing: Text('+${_formatDuration(lap - previous)}',
                      style: TextStyle(color: colors.disabledText)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerTab extends StatefulWidget {
  const _TimerTab();

  @override
  State<_TimerTab> createState() => _TimerTabState();
}

class _TimerTabState extends State<_TimerTab>
    with AutomaticKeepAliveClientMixin {
  Duration _total = const Duration(minutes: 5);
  Duration _left = const Duration(minutes: 5);
  DateTime? _endsAt;
  Timer? _ticker;

  @override
  bool get wantKeepAlive => true;

  bool get _running => _endsAt != null;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _setTotal(Duration value) {
    if (_running) return;
    setState(() {
      _total = value;
      _left = value;
    });
  }

  void _toggle() {
    if (_running) {
      _ticker?.cancel();
      setState(() {
        _left = _endsAt!.difference(DateTime.now());
        _endsAt = null;
      });
      return;
    }
    if (_left <= Duration.zero) _left = _total;
    setState(() => _endsAt = DateTime.now().add(_left));
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _tick() {
    final endsAt = _endsAt;
    if (endsAt == null || !mounted) return;
    final left = endsAt.difference(DateTime.now());
    if (left <= Duration.zero) {
      _ticker?.cancel();
      setState(() {
        _left = Duration.zero;
        _endsAt = null;
      });
      _alarm();
    } else {
      setState(() => _left = left);
    }
  }

  Future<void> _alarm() async {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.alarm, size: 40),
        title: Text(context.tr('timer')),
        content: Text(context.tr('time_is_up')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _endsAt = null;
      _left = _total;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = RetroColors.of(context);
    const presets = [1, 3, 5, 10, 15, 30, 60];
    final progress = _total.inMilliseconds == 0
        ? 0.0
        : 1 - _left.inMilliseconds / _total.inMilliseconds;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          FittedBox(
            child: Text(
              _formatDuration(_left, hundredths: false),
              style: TextStyle(
                color: colors.text,
                fontSize: 44,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 6),
          UsageBar(value: progress, color: Colors.indigo.shade400),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final step in const [-60, -10, 10, 60])
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: SizedBox(
                    width: 56,
                    height: 34,
                    child: RetroButton(
                      onPressed: _running
                          ? null
                          : () {
                              final value =
                                  _total + Duration(seconds: step);
                              if (value > Duration.zero) _setTotal(value);
                            },
                      child: Text(step > 0
                          ? '+${step >= 60 ? '${step ~/ 60}m' : '${step}s'}'
                          : '−${step <= -60 ? '${-step ~/ 60}m' : '${-step}s'}'),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final minutes in presets)
                SizedBox(
                  width: 56,
                  height: 32,
                  child: RetroButton(
                    pressed: _total == Duration(minutes: minutes),
                    onPressed: _running
                        ? null
                        : () => _setTotal(Duration(minutes: minutes)),
                    child: Text('$minutes ${context.tr('minutes_short')}'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: RetroButton(
                    onPressed: _reset,
                    child: Text(context.tr('reset')),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: RetroButton(
                    onPressed: _toggle,
                    child: Text(
                      context.tr(_running ? 'pause' : 'start_timer'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
