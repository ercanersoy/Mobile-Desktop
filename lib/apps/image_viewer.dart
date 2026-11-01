// image_viewer.dart - Shows pictures
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code.

import 'dart:io';

import 'package:flutter/material.dart';

import '../core/settings.dart';
import '../desktop/window_manager.dart';
import '../widgets/file_dialog.dart';
import '../widgets/retro.dart';
import 'file_manager.dart' show fileExtension, kImageExtensions;

class ImageViewerApp extends StatefulWidget {
  const ImageViewerApp({super.key, this.path});

  final String? path;

  @override
  State<ImageViewerApp> createState() => _ImageViewerAppState();
}

class _ImageViewerAppState extends State<ImageViewerApp> {
  String? _path;
  List<String> _siblings = [];
  final TransformationController _transform = TransformationController();
  int _quarterTurns = 0;

  @override
  void initState() {
    super.initState();
    if (widget.path != null) _show(widget.path!);
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _show(String path) {
    List<String> siblings = [];
    try {
      siblings = File(path)
          .parent
          .listSync()
          .whereType<File>()
          .map((file) => file.path)
          .where((p) => kImageExtensions.contains(fileExtension(p)))
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    } catch (_) {
      siblings = [path];
    }
    setState(() {
      _path = path;
      _siblings = siblings;
      _quarterTurns = 0;
      _transform.value = Matrix4.identity();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final window = WindowScope.maybeOf(context);
      if (window != null) {
        WindowManagerScope.read(context)
            .setTitle(window.id, path.split('/').last);
      }
    });
  }

  void _step(int delta) {
    final path = _path;
    if (path == null || _siblings.length < 2) return;
    var index = _siblings.indexOf(path);
    if (index < 0) index = 0;
    index = (index + delta) % _siblings.length;
    _show(_siblings[index]);
  }

  Future<void> _open() async {
    final path = await showOpenFileDialog(
      context,
      initialDirectory: _path == null ? null : File(_path!).parent.path,
      extensions: kImageExtensions.toList(),
    );
    if (path != null) _show(path);
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;
    final index = path == null ? -1 : _siblings.indexOf(path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroToolbar(children: [
          ToolbarButton(
            icon: Icons.folder_open,
            tooltip: context.tr('open'),
            onPressed: _open,
          ),
          ToolbarButton(
            icon: Icons.chevron_left,
            tooltip: context.tr('previous'),
            onPressed: _siblings.length > 1 ? () => _step(-1) : null,
          ),
          ToolbarButton(
            icon: Icons.chevron_right,
            tooltip: context.tr('next'),
            onPressed: _siblings.length > 1 ? () => _step(1) : null,
          ),
          ToolbarButton(
            icon: Icons.rotate_right,
            tooltip: context.tr('rotate'),
            onPressed: path == null
                ? null
                : () => setState(() => _quarterTurns = (_quarterTurns + 1) % 4),
          ),
          ToolbarButton(
            icon: Icons.fit_screen,
            tooltip: context.tr('fit'),
            onPressed: path == null
                ? null
                : () => _transform.value = Matrix4.identity(),
          ),
        ]),
        Expanded(
          child: Container(
            color: Colors.black,
            child: path == null
                ? Center(
                    child: TextButton.icon(
                      onPressed: _open,
                      icon: const Icon(Icons.image),
                      label: Text(context.tr('open_image')),
                    ),
                  )
                : InteractiveViewer(
                    transformationController: _transform,
                    maxScale: 10,
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: _quarterTurns,
                        child: Image.file(
                          File(path),
                          key: ValueKey(path),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) => Text(
                            context.tr('image_error'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        StatusBar(children: [
          Text(path?.split('/').last ?? '-'),
          Text(index < 0 ? '' : '${index + 1} / ${_siblings.length}'),
        ]),
      ],
    );
  }
}
