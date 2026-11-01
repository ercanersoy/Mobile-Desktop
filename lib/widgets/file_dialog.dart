// file_dialog.dart - Dialogs to choose a file to open or a place to save
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Opus 5.5.

import 'dart:io';

import 'package:flutter/material.dart';

import '../core/settings.dart';
import '../core/storage_access.dart';
import 'retro.dart';

/// Lets the user pick an existing file. Returns its path or null.
Future<String?> showOpenFileDialog(
  BuildContext context, {
  String? initialDirectory,
  List<String>? extensions,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _FileDialog(
      save: false,
      initialDirectory: initialDirectory,
      extensions: extensions,
    ),
  );
}

/// Lets the user choose a folder and file name. Returns the full path
/// or null.
Future<String?> showSaveFileDialog(
  BuildContext context, {
  String? initialDirectory,
  String suggestedName = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _FileDialog(
      save: true,
      initialDirectory: initialDirectory,
      suggestedName: suggestedName,
    ),
  );
}

/// Translated name of a location from [StorageAccess.locations].
String locationLabel(BuildContext context, String key) {
  if (key.startsWith('loc_external:')) {
    return '${context.tr('loc_external')} (${key.substring(13)})';
  }
  return context.tr(key);
}

class _FileDialog extends StatefulWidget {
  const _FileDialog({
    required this.save,
    this.initialDirectory,
    this.extensions,
    this.suggestedName = '',
  });

  final bool save;
  final String? initialDirectory;
  final List<String>? extensions;
  final String suggestedName;

  @override
  State<_FileDialog> createState() => _FileDialogState();
}

class _FileDialogState extends State<_FileDialog> {
  String? _path;
  List<FileSystemEntity> _entries = [];
  bool _error = false;
  List<MapEntry<String, String>> _locations = [];
  late final TextEditingController _nameController =
      TextEditingController(text: widget.suggestedName);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await StorageAccess.ensurePermission();
    final start = widget.initialDirectory ?? await StorageAccess.homeFolder();
    final locations = await StorageAccess.locations();
    if (!mounted) return;
    _locations = locations;
    _open(start);
  }

  void _open(String path) {
    try {
      final entries = Directory(path).listSync().where((entry) {
        final name = entry.path.split('/').last;
        if (name.startsWith('.')) return false;
        if (entry is Directory) return true;
        final filter = widget.extensions;
        if (filter == null) return true;
        final lower = name.toLowerCase();
        return filter.any((ext) => lower.endsWith('.$ext'));
      }).toList()
        ..sort((a, b) {
          final aDir = a is Directory;
          final bDir = b is Directory;
          if (aDir != bDir) return aDir ? -1 : 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });
      setState(() {
        _path = path;
        _entries = entries;
        _error = false;
      });
    } catch (_) {
      setState(() {
        _path = path;
        _entries = [];
        _error = true;
      });
    }
  }

  void _goUp() {
    final path = _path;
    if (path == null || path == '/') return;
    final parent = Directory(path).parent.path;
    _open(parent);
  }

  Future<void> _confirmSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _path == null) return;
    if (name.contains('/') || name == '.' || name == '..') return;
    final path = '$_path/$name';
    if (await FileSystemEntity.isDirectory(path)) return;
    if (await File(path).exists()) {
      if (!mounted) return;
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('save_as')),
          content:
              Text(context.tr('overwrite_confirm').replaceAll('{name}', name)),
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
      if (replace != true) return;
    }
    if (mounted) Navigator.pop(context, path);
  }

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      title: Text(context.tr(widget.save ? 'save_as' : 'open')),
      content: SizedBox(
        width: 360,
        height: 380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: context.tr('up'),
                  onPressed: _goUp,
                ),
                Expanded(
                  child: Text(
                    _path ?? '...',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.place),
                  tooltip: context.tr('locations'),
                  onSelected: _open,
                  itemBuilder: (context) => [
                    for (final location in _locations)
                      PopupMenuItem(
                        value: location.value,
                        child: Text(locationLabel(context, location.key)),
                      ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.shadow),
                ),
                child: _path == null
                    ? const Center(child: CircularProgressIndicator())
                    : _error
                        ? Center(child: Text(context.tr('folder_unreadable')))
                        : _entries.isEmpty
                            ? Center(child: Text(context.tr('empty_folder')))
                            : ListView.builder(
                                itemCount: _entries.length,
                                itemBuilder: (context, index) {
                                  final entry = _entries[index];
                                  final isDir = entry is Directory;
                                  final name = entry.path.split('/').last;
                                  return ListTile(
                                    dense: true,
                                    leading: Icon(
                                      isDir
                                          ? Icons.folder
                                          : Icons.insert_drive_file,
                                      color: isDir
                                          ? Colors.amber.shade700
                                          : null,
                                    ),
                                    title: Text(name),
                                    onTap: () {
                                      if (isDir) {
                                        _open(entry.path);
                                      } else if (widget.save) {
                                        _nameController.text = name;
                                      } else {
                                        Navigator.pop(context, entry.path);
                                      }
                                    },
                                  );
                                },
                              ),
              ),
            ),
            if (widget.save)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.tr('file_name'),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _confirmSave(),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        if (widget.save)
          TextButton(
            onPressed: _confirmSave,
            child: Text(context.tr('save')),
          ),
      ],
    );
  }
}
