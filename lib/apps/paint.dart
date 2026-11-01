// paint.dart - Simple drawing app
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code Opus 5.5.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../core/settings.dart';
import '../core/storage_access.dart';
import '../widgets/retro.dart';

enum _Tool { pen, line, rectangle, ellipse, eraser }

class _Stroke {
  _Stroke({
    required this.tool,
    required this.color,
    required this.width,
    required this.points,
    this.filled = false,
  });

  final _Tool tool;
  final Color color;
  final double width;
  final List<Offset> points;
  final bool filled;
}

class PaintApp extends StatefulWidget {
  const PaintApp({super.key});

  @override
  State<PaintApp> createState() => _PaintAppState();
}

class _PaintAppState extends State<PaintApp> {
  static const List<Color> _palette = [
    Colors.black,
    Colors.white,
    Color(0xFF808080),
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.brown,
  ];

  static const List<double> _widths = [2, 4, 8, 14];

  final List<_Stroke> _strokes = [];
  final List<_Stroke> _redo = [];
  final GlobalKey _canvasKey = GlobalKey();
  _Stroke? _current;
  _Tool _tool = _Tool.pen;
  Color _color = Colors.black;
  double _width = 4;
  bool _fill = false;
  Color _background = Colors.white;

  void _start(Offset point) {
    setState(() {
      _current = _Stroke(
        tool: _tool,
        color: _color,
        width: _tool == _Tool.eraser ? _width * 3 : _width,
        points: [point],
        filled: _fill,
      );
      _redo.clear();
    });
  }

  void _update(Offset point) {
    final current = _current;
    if (current == null) return;
    setState(() {
      if (current.tool == _Tool.pen || current.tool == _Tool.eraser) {
        current.points.add(point);
      } else if (current.points.length == 1) {
        current.points.add(point);
      } else {
        current.points[1] = point;
      }
    });
  }

  void _end() {
    final current = _current;
    if (current == null) return;
    setState(() {
      _strokes.add(current);
      _current = null;
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _redo.add(_strokes.removeLast()));
  }

  void _redoLast() {
    if (_redo.isEmpty) return;
    setState(() => _strokes.add(_redo.removeLast()));
  }

  Future<void> _clear() async {
    if (_strokes.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('clear')),
        content: Text(context.tr('clear_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _strokes.clear();
        _redo.clear();
      });
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final savedText = context.tr('saved_to');
    final errorText = context.tr('file_write_error');
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;

      String folder;
      if (await StorageAccess.ensurePermission()) {
        folder = Platform.isAndroid
            ? '${StorageAccess.androidRoot}/Pictures/MobileDesktop'
            : '${await StorageAccess.homeFolder()}/Pictures';
      } else {
        folder = await StorageAccess.appFolder();
      }
      await Directory(folder).create(recursive: true);
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final name = 'paint_${now.year}${two(now.month)}${two(now.day)}_'
          '${two(now.hour)}${two(now.minute)}${two(now.second)}.png';
      final file = File('$folder/$name');
      await file.writeAsBytes(data.buffer.asUint8List());
      messenger?.showSnackBar(
          SnackBar(content: Text(savedText.replaceAll('{path}', file.path))));
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(errorText)));
    }
  }

  IconData _toolIcon(_Tool tool) {
    switch (tool) {
      case _Tool.pen:
        return Icons.edit;
      case _Tool.line:
        return Icons.horizontal_rule;
      case _Tool.rectangle:
        return Icons.crop_square;
      case _Tool.ellipse:
        return Icons.circle_outlined;
      case _Tool.eraser:
        return Icons.auto_fix_normal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroToolbar(children: [
          for (final tool in _Tool.values)
            ToolbarButton(
              icon: _toolIcon(tool),
              tooltip: context.tr('tool_${tool.name}'),
              pressed: _tool == tool,
              onPressed: () => setState(() => _tool = tool),
            ),
          ToolbarButton(
            icon: _fill ? Icons.format_color_fill : Icons.format_color_reset,
            tooltip: context.tr('fill_shapes'),
            pressed: _fill,
            onPressed: () => setState(() => _fill = !_fill),
          ),
          ToolbarButton(
            icon: Icons.undo,
            tooltip: context.tr('undo'),
            onPressed: _strokes.isEmpty ? null : _undo,
          ),
          ToolbarButton(
            icon: Icons.redo,
            tooltip: context.tr('redo'),
            onPressed: _redo.isEmpty ? null : _redoLast,
          ),
          ToolbarButton(
            icon: Icons.delete_outline,
            tooltip: context.tr('clear'),
            onPressed: _strokes.isEmpty ? null : _clear,
          ),
          ToolbarButton(
            icon: Icons.save,
            tooltip: context.tr('save_png'),
            onPressed: _save,
          ),
        ]),
        Expanded(
          child: Bevel(
            sunken: true,
            child: ClipRect(
              child: RepaintBoundary(
                key: _canvasKey,
                child: GestureDetector(
                  onPanStart: (d) => _start(d.localPosition),
                  onPanUpdate: (d) => _update(d.localPosition),
                  onPanEnd: (_) => _end(),
                  onTapUp: (d) {
                    _start(d.localPosition);
                    _update(d.localPosition + const Offset(0.1, 0.1));
                    _end();
                  },
                  child: CustomPaint(
                    painter: _CanvasPainter(
                      strokes: _strokes,
                      current: _current,
                      background: _background,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
        ),
        Bevel(
          width: 1,
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              // Current color and brush size.
              GestureDetector(
                onTap: () => setState(() => _background =
                    _background == Colors.white ? Colors.black : Colors.white),
                child: Tooltip(
                  message: context.tr('background_toggle'),
                  child: Bevel(
                    sunken: true,
                    width: 1,
                    color: _background,
                    padding: const EdgeInsets.all(5),
                    child: Container(width: 18, height: 18, color: _color),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final color in _palette)
                        GestureDetector(
                          onTap: () => setState(() {
                            _color = color;
                            if (_tool == _Tool.eraser) _tool = _Tool.pen;
                          }),
                          child: Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: color,
                              border: Border.all(
                                color: color == _color
                                    ? colors.selection
                                    : colors.shadow,
                                width: color == _color ? 3 : 1,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      for (final width in _widths)
                        GestureDetector(
                          onTap: () => setState(() => _width = width),
                          child: Container(
                            width: 28,
                            height: 26,
                            margin: const EdgeInsets.all(1),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: width == _width
                                    ? colors.selection
                                    : colors.shadow,
                                width: width == _width ? 2 : 1,
                              ),
                            ),
                            child: Container(
                              width: 18,
                              height: width,
                              decoration: BoxDecoration(
                                color: colors.text,
                                borderRadius: BorderRadius.circular(width / 2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CanvasPainter extends CustomPainter {
  _CanvasPainter({
    required this.strokes,
    required this.current,
    required this.background,
  });

  final List<_Stroke> strokes;
  final _Stroke? current;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    // Draw on a separate layer so the eraser only removes strokes and
    // keeps the background.
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final stroke in strokes) {
      _draw(canvas, stroke);
    }
    if (current != null) _draw(canvas, current!);
    canvas.restore();
  }

  void _draw(Canvas canvas, _Stroke stroke) {
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (stroke.tool == _Tool.eraser) paint.blendMode = BlendMode.clear;
    final points = stroke.points;
    switch (stroke.tool) {
      case _Tool.pen:
      case _Tool.eraser:
        if (points.length == 1) {
          canvas.drawCircle(points.first, stroke.width / 2,
              paint..style = PaintingStyle.fill);
          return;
        }
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
      case _Tool.line:
        if (points.length < 2) return;
        canvas.drawLine(points[0], points[1], paint);
      case _Tool.rectangle:
        if (points.length < 2) return;
        if (stroke.filled) paint.style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromPoints(points[0], points[1]), paint);
      case _Tool.ellipse:
        if (points.length < 2) return;
        if (stroke.filled) paint.style = PaintingStyle.fill;
        canvas.drawOval(Rect.fromPoints(points[0], points[1]), paint);
    }
  }

  // The stroke lists change in place, so always repaint.
  @override
  bool shouldRepaint(_CanvasPainter oldDelegate) => true;
}
