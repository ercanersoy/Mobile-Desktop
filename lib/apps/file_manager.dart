// file_manager.dart - File manager app
//
// Copyright (c) 2025 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/settings.dart';
import '../core/storage_access.dart';
import '../widgets/file_dialog.dart';
import '../widgets/retro.dart';
import 'app_registry.dart';

const Set<String> kTextExtensions = {
  'txt', 'md', 'log', 'csv', 'json', 'xml', 'yaml', 'yml', 'ini', 'conf',
  'cfg', 'dart', 'java', 'kt', 'py', 'js', 'ts', 'html', 'htm', 'css', 'sh',
  'c', 'h', 'cpp', 'hpp', 'rs', 'go', 'properties', 'gradle', 'sql', 'toml',
};

const Set<String> kImageExtensions = {
  'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp',
};

String fileExtension(String path) {
  final name = path.split('/').last;
  final dot = name.lastIndexOf('.');
  return dot <= 0 ? '' : name.substring(dot + 1).toLowerCase();
}

IconData iconForFile(String path) {
  final ext = fileExtension(path);
  if (kImageExtensions.contains(ext)) return Icons.image;
  if (kTextExtensions.contains(ext)) return Icons.description;
  switch (ext) {
    case 'mp3':
    case 'wav':
    case 'ogg':
    case 'flac':
    case 'm4a':
    case 'aac':
      return Icons.audio_file;
    case 'mp4':
    case 'mkv':
    case 'avi':
    case 'webm':
    case 'mov':
    case '3gp':
      return Icons.video_file;
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
      return Icons.folder_zip;
    case 'apk':
      return Icons.android;
    case 'pdf':
      return Icons.picture_as_pdf;
    default:
      return Icons.insert_drive_file;
  }
}

enum _SortMode { name, size, date }

class _ClipboardEntry {
  const _ClipboardEntry(this.paths, this.cut);

  final List<String> paths;
  final bool cut;
}

/// Shared between all file manager windows, so files can be copied from
/// one window and pasted into another.
_ClipboardEntry? _fileClipboard;

class FileManagerApp extends StatefulWidget {
  const FileManagerApp({super.key, this.initialPath});

  final String? initialPath;

  @override
  State<FileManagerApp> createState() => _FileManagerAppState();
}

class _FileManagerAppState extends State<FileManagerApp> {
  String? _path;
  List<FileSystemEntity> _entries = [];
  final Map<String, FileStat> _stats = {};
  final List<String> _history = [];
  final Set<String> _selected = {};
  List<MapEntry<String, String>> _locations = [];
  bool _loading = true;
  bool _permission = false;
  bool _error = false;
  bool _showHidden = false;
  bool _grid = false;
  _SortMode _sort = _SortMode.name;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final granted = await StorageAccess.ensurePermission();
    final locations = await StorageAccess.locations();
    final start = widget.initialPath ?? await StorageAccess.homeFolder();
    if (!mounted) return;
    setState(() {
      _permission = granted;
      _locations = locations;
    });
    await _open(start, addToHistory: false);
  }

  Future<void> _retryPermission() async {
    final granted = await StorageAccess.ensurePermission();
    if (!granted) {
      await openAppSettings();
      return;
    }
    if (!mounted) return;
    setState(() => _permission = true);
    await _open(StorageAccess.androidRoot, addToHistory: false);
  }

  Future<void> _open(String path, {bool addToHistory = true}) async {
    setState(() {
      _loading = true;
      _selected.clear();
    });
    try {
      final dir = Directory(path);
      final entries = await dir.list().toList();
      final stats = <String, FileStat>{};
      for (final entry in entries) {
        try {
          stats[entry.path] = await entry.stat();
        } catch (_) {
          // Ignore files we cannot read.
        }
      }
      if (!mounted) return;
      setState(() {
        if (addToHistory && _path != null && _path != path) {
          _history.add(_path!);
        }
        _path = path;
        _entries = entries;
        _stats
          ..clear()
          ..addAll(stats);
        _error = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (addToHistory && _path != null && _path != path) {
          _history.add(_path!);
        }
        _path = path;
        _entries = [];
        _error = true;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_path != null) await _open(_path!, addToHistory: false);
  }

  void _back() {
    if (_history.isEmpty) return;
    _open(_history.removeLast(), addToHistory: false);
  }

  void _up() {
    final path = _path;
    if (path == null || path == '/') return;
    _open(Directory(path).parent.path);
  }

  List<FileSystemEntity> get _visibleEntries {
    final list = _entries.where((entry) {
      if (_showHidden) return true;
      return !_nameOf(entry.path).startsWith('.');
    }).toList();
    list.sort((a, b) {
      final aDir = a is Directory;
      final bDir = b is Directory;
      if (aDir != bDir) return aDir ? -1 : 1;
      switch (_sort) {
        case _SortMode.size:
          final sa = _stats[a.path]?.size ?? 0;
          final sb = _stats[b.path]?.size ?? 0;
          if (sa != sb) return sb.compareTo(sa);
        case _SortMode.date:
          final da = _stats[a.path]?.modified;
          final db = _stats[b.path]?.modified;
          if (da != null && db != null && da != db) return db.compareTo(da);
        case _SortMode.name:
          break;
      }
      return _nameOf(a.path).toLowerCase().compareTo(_nameOf(b.path).toLowerCase());
    });
    return list;
  }

  String _nameOf(String path) => path.split('/').last;

  void _showMessage(String text) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(text)));
  }

  void _activate(FileSystemEntity entry) {
    if (_selected.isNotEmpty) {
      _toggleSelected(entry);
      return;
    }
    if (entry is Directory) {
      _open(entry.path);
      return;
    }
    final ext = fileExtension(entry.path);
    if (kImageExtensions.contains(ext)) {
      Apps.launch(context, 'imageviewer', args: {'path': entry.path});
    } else if (kTextExtensions.contains(ext)) {
      Apps.launch(context, 'notepad', args: {'path': entry.path});
    } else {
      // Unknown type: let the user choose what to do.
      _showEntryMenu(entry);
    }
  }

  void _toggleSelected(FileSystemEntity entry) {
    setState(() {
      if (!_selected.remove(entry.path)) _selected.add(entry.path);
    });
  }

  Future<String?> _askName(String titleKey, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr(titleKey)),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
    controller.dispose();
    final name = result?.trim();
    if (name == null || name.isEmpty) return null;
    if (name.contains('/') || name == '.' || name == '..') {
      _showMessage(context.tr('invalid_name'));
      return null;
    }
    return name;
  }

  Future<void> _newFolder() async {
    final name = await _askName('new_folder');
    if (name == null || _path == null) return;
    try {
      await Directory('$_path/$name').create();
      await _refresh();
    } catch (_) {
      _showMessage(context.tr('operation_failed'));
    }
  }

  Future<void> _newTextFile() async {
    final name = await _askName('new_text_file', initial: 'new.txt');
    if (name == null || _path == null) return;
    try {
      final file = File('$_path/$name');
      if (await file.exists()) {
        _showMessage(context.tr('already_exists'));
        return;
      }
      await file.create();
      await _refresh();
    } catch (_) {
      _showMessage(context.tr('operation_failed'));
    }
  }

  Future<void> _rename(FileSystemEntity entry) async {
    final name = await _askName('rename', initial: _nameOf(entry.path));
    if (name == null) return;
    try {
      await entry.rename('${entry.parent.path}/$name');
      await _refresh();
    } catch (_) {
      _showMessage(context.tr('operation_failed'));
    }
  }

  Future<void> _delete(List<String> paths) async {
    if (paths.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete')),
        content: Text(paths.length == 1
            ? context.tr('delete_confirm_one').replaceAll('{name}', _nameOf(paths.first))
            : context.tr('delete_confirm_many').replaceAll('{count}', '${paths.length}')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('delete'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    var failed = false;
    for (final path in paths) {
      try {
        final type = await FileSystemEntity.type(path, followLinks: false);
        if (type == FileSystemEntityType.directory) {
          await Directory(path).delete(recursive: true);
        } else {
          await File(path).delete();
        }
      } catch (_) {
        failed = true;
      }
    }
    if (failed && mounted) _showMessage(context.tr('operation_failed'));
    await _refresh();
  }

  void _copyToClipboard(List<String> paths, {required bool cut}) {
    if (paths.isEmpty) return;
    setState(() {
      _fileClipboard = _ClipboardEntry(List.of(paths), cut);
      _selected.clear();
    });
    _showMessage(context
        .tr(cut ? 'cut_done' : 'copy_done')
        .replaceAll('{count}', '${paths.length}'));
  }

  Future<void> _paste() async {
    final clip = _fileClipboard;
    final target = _path;
    if (clip == null || target == null) return;
    setState(() => _loading = true);
    var failed = false;
    for (final source in clip.paths) {
      final name = _nameOf(source);
      var destination = '$target/$name';
      if (destination == source && clip.cut) continue;
      destination = await _uniquePath(destination);
      if (target == source || target.startsWith('$source/')) {
        // Cannot copy a folder into itself.
        failed = true;
        continue;
      }
      try {
        if (clip.cut) {
          await _move(source, destination);
        } else {
          await _copy(source, destination);
        }
      } catch (_) {
        failed = true;
      }
    }
    if (clip.cut) _fileClipboard = null;
    if (failed && mounted) _showMessage(context.tr('operation_failed'));
    await _refresh();
  }

  /// Adds " (2)", " (3)", ... when the name is already used.
  Future<String> _uniquePath(String path) async {
    if (!await FileSystemEntity.isFile(path) &&
        !await FileSystemEntity.isDirectory(path)) {
      return path;
    }
    final dot = path.lastIndexOf('.');
    final slash = path.lastIndexOf('/');
    final hasExt = dot > slash + 1;
    final base = hasExt ? path.substring(0, dot) : path;
    final ext = hasExt ? path.substring(dot) : '';
    for (var i = 2;; i++) {
      final candidate = '$base ($i)$ext';
      if (!await FileSystemEntity.isFile(candidate) &&
          !await FileSystemEntity.isDirectory(candidate)) {
        return candidate;
      }
    }
  }

  Future<void> _copy(String source, String destination) async {
    if (await FileSystemEntity.isDirectory(source)) {
      await Directory(destination).create(recursive: true);
      await for (final child in Directory(source).list(followLinks: false)) {
        await _copy(child.path, '$destination/${_nameOf(child.path)}');
      }
    } else {
      await File(source).copy(destination);
    }
  }

  Future<void> _move(String source, String destination) async {
    try {
      if (await FileSystemEntity.isDirectory(source)) {
        await Directory(source).rename(destination);
      } else {
        await File(source).rename(destination);
      }
    } on FileSystemException {
      // Rename does not work across drives; copy and delete instead.
      await _copy(source, destination);
      if (await FileSystemEntity.isDirectory(source)) {
        await Directory(source).delete(recursive: true);
      } else {
        await File(source).delete();
      }
    }
  }

  Future<void> _showProperties(FileSystemEntity entry) async {
    final stat = _stats[entry.path] ?? await entry.stat();
    int? folderSize;
    int? itemCount;
    if (entry is Directory) {
      try {
        var size = 0;
        var count = 0;
        await for (final child
            in entry.list(recursive: true, followLinks: false)) {
          count++;
          if (child is File) size += await child.length();
          if (count > 20000) break;
        }
        folderSize = size;
        itemCount = count;
      } catch (_) {
        // Some sub folders cannot be read.
      }
    }
    if (!mounted) return;
    final rows = <MapEntry<String, String>>[
      MapEntry(context.tr('name'), _nameOf(entry.path)),
      MapEntry(context.tr('location'), entry.parent.path),
      MapEntry(
          context.tr('type'),
          entry is Directory
              ? context.tr('folder')
              : '${fileExtension(entry.path).toUpperCase()} ${context.tr('file')}'),
      MapEntry(context.tr('size'),
          formatBytes(entry is Directory ? (folderSize ?? 0) : stat.size)),
      if (itemCount != null)
        MapEntry(context.tr('contents'), '$itemCount ${context.tr('items')}'),
      MapEntry(context.tr('modified'), formatDateTime(stat.modified)),
      MapEntry(context.tr('permissions'), stat.modeString()),
    ];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('properties')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(row.key,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: SelectableText(row.value)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
  }

  Future<void> _showEntryMenu(FileSystemEntity entry) async {
    final isDir = entry is Directory;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        Widget tile(String value, IconData icon, String labelKey) => ListTile(
              leading: Icon(icon),
              title: Text(context.tr(labelKey)),
              onTap: () => Navigator.pop(context, value),
            );
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(isDir ? Icons.folder : iconForFile(entry.path)),
                  title: Text(_nameOf(entry.path),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                tile('open', Icons.open_in_new, 'open'),
                if (isDir) tile('open_window', Icons.tab, 'open_new_window'),
                if (!isDir) tile('notepad', Icons.description, 'open_with_notepad'),
                tile('select', Icons.check_box, 'select'),
                tile('copy', Icons.copy, 'copy'),
                tile('cut', Icons.content_cut, 'cut'),
                tile('rename', Icons.drive_file_rename_outline, 'rename'),
                tile('delete', Icons.delete, 'delete'),
                tile('properties', Icons.info_outline, 'properties'),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    switch (action) {
      case 'open':
        if (isDir) {
          _open(entry.path);
        } else if (kImageExtensions.contains(fileExtension(entry.path))) {
          Apps.launch(context, 'imageviewer', args: {'path': entry.path});
        } else {
          Apps.launch(context, 'notepad', args: {'path': entry.path});
        }
      case 'open_window':
        Apps.launch(context, 'files', args: {'path': entry.path});
      case 'notepad':
        Apps.launch(context, 'notepad', args: {'path': entry.path});
      case 'select':
        _toggleSelected(entry);
      case 'copy':
        _copyToClipboard([entry.path], cut: false);
      case 'cut':
        _copyToClipboard([entry.path], cut: true);
      case 'rename':
        _rename(entry);
      case 'delete':
        _delete([entry.path]);
      case 'properties':
        _showProperties(entry);
    }
  }

  Future<void> _editPath() async {
    final controller = TextEditingController(text: _path ?? '');
    final path = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('go_to')),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (path != null && path.trim().isNotEmpty) _open(path.trim());
  }

  void _onMoreMenu(String value) {
    switch (value) {
      case 'new_file':
        _newTextFile();
      case 'hidden':
        setState(() => _showHidden = !_showHidden);
      case 'view':
        setState(() => _grid = !_grid);
      case 'sort_name':
        setState(() => _sort = _SortMode.name);
      case 'sort_size':
        setState(() => _sort = _SortMode.size);
      case 'sort_date':
        setState(() => _sort = _SortMode.date);
      case 'select_all':
        setState(() {
          _selected
            ..clear()
            ..addAll(_visibleEntries.map((e) => e.path));
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    final entries = _visibleEntries;
    final hasSelection = _selected.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroToolbar(children: [
          ToolbarButton(
            icon: Icons.arrow_back,
            tooltip: context.tr('back'),
            onPressed: _history.isEmpty ? null : _back,
          ),
          ToolbarButton(
            icon: Icons.arrow_upward,
            tooltip: context.tr('up'),
            onPressed: _path == null || _path == '/' ? null : _up,
          ),
          ToolbarButton(
            icon: Icons.refresh,
            tooltip: context.tr('refresh'),
            onPressed: _refresh,
          ),
          ToolbarMenuButton<String>(
            icon: Icons.place,
            tooltip: context.tr('locations'),
            onSelected: (path) => _open(path),
            itemBuilder: (context) => [
              for (final location in _locations)
                PopupMenuItem(
                  value: location.value,
                  child: Text(locationLabel(context, location.key)),
                ),
            ],
          ),
          if (hasSelection) ...[
            ToolbarButton(
              icon: Icons.copy,
              tooltip: context.tr('copy'),
              onPressed: () =>
                  _copyToClipboard(_selected.toList(), cut: false),
            ),
            ToolbarButton(
              icon: Icons.content_cut,
              tooltip: context.tr('cut'),
              onPressed: () => _copyToClipboard(_selected.toList(), cut: true),
            ),
            ToolbarButton(
              icon: Icons.delete,
              tooltip: context.tr('delete'),
              onPressed: () => _delete(_selected.toList()),
            ),
            ToolbarButton(
              icon: Icons.close,
              tooltip: context.tr('clear_selection'),
              onPressed: () => setState(_selected.clear),
            ),
          ] else ...[
            ToolbarButton(
              icon: Icons.create_new_folder,
              tooltip: context.tr('new_folder'),
              onPressed: _path == null ? null : _newFolder,
            ),
            ToolbarButton(
              icon: Icons.content_paste,
              tooltip: context.tr('paste'),
              onPressed: _fileClipboard == null ? null : _paste,
            ),
          ],
          ToolbarMenuButton<String>(
            icon: Icons.more_vert,
            tooltip: context.tr('more'),
            onSelected: _onMoreMenu,
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'new_file', child: Text(context.tr('new_text_file'))),
              PopupMenuItem(
                  value: 'select_all', child: Text(context.tr('select_all'))),
              const PopupMenuDivider(),
              CheckedPopupMenuItem(
                value: 'hidden',
                checked: _showHidden,
                child: Text(context.tr('show_hidden')),
              ),
              CheckedPopupMenuItem(
                value: 'view',
                checked: _grid,
                child: Text(context.tr('grid_view')),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem(
                value: 'sort_name',
                checked: _sort == _SortMode.name,
                child: Text(context.tr('sort_name')),
              ),
              CheckedPopupMenuItem(
                value: 'sort_size',
                checked: _sort == _SortMode.size,
                child: Text(context.tr('sort_size')),
              ),
              CheckedPopupMenuItem(
                value: 'sort_date',
                checked: _sort == _SortMode.date,
                child: Text(context.tr('sort_date')),
              ),
            ],
          ),
        ]),
        GestureDetector(
          onTap: _editPath,
          child: Container(
            margin: const EdgeInsets.fromLTRB(2, 2, 2, 2),
            child: Bevel(
              sunken: true,
              width: 1,
              color: colors.field,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Row(
                children: [
                  Icon(Icons.folder_open, size: 16, color: colors.text),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _path ?? '...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.text, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!_permission && Platform.isAndroid)
          Container(
            color: Colors.amber.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.lock, size: 18, color: Colors.black87),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.tr('storage_permission_needed'),
                    style: const TextStyle(color: Colors.black87, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: _retryPermission,
                  child: Text(context.tr('grant')),
                ),
              ],
            ),
          ),
        Expanded(
          child: Bevel(
            sunken: true,
            color: colors.field,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            context.tr('folder_unreadable'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.text),
                          ),
                        ),
                      )
                    : entries.isEmpty
                        ? Center(
                            child: Text(context.tr('empty_folder'),
                                style: TextStyle(color: colors.disabledText)),
                          )
                        : RefreshIndicator(
                            onRefresh: _refresh,
                            child: _grid
                                ? _buildGrid(entries, colors)
                                : _buildList(entries, colors),
                          ),
          ),
        ),
        StatusBar(children: [
          Text(hasSelection
              ? context
                  .tr('selected_count')
                  .replaceAll('{count}', '${_selected.length}')
              : '${entries.length} ${context.tr('items')}'),
          Text(_fileClipboard == null
              ? ''
              : '${context.tr(_fileClipboard!.cut ? 'cut' : 'copy')}: ${_fileClipboard!.paths.length}'),
        ]),
      ],
    );
  }

  Widget _buildList(List<FileSystemEntity> entries, RetroColors colors) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isDir = entry is Directory;
        final stat = _stats[entry.path];
        final selected = _selected.contains(entry.path);
        final subtitle = [
          if (!isDir && stat != null) formatBytes(stat.size),
          if (stat != null) formatDateTime(stat.modified),
        ].join('  •  ');
        return ListTile(
          dense: true,
          selected: selected,
          selectedTileColor: colors.selection.withAlpha(50),
          leading: Icon(
            selected
                ? Icons.check_circle
                : isDir
                    ? Icons.folder
                    : iconForFile(entry.path),
            color: selected
                ? colors.selection
                : isDir
                    ? Colors.amber.shade700
                    : colors.text,
          ),
          title: Text(
            _nameOf(entry.path),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.text),
          ),
          subtitle: subtitle.isEmpty
              ? null
              : Text(subtitle,
                  style: TextStyle(color: colors.disabledText, fontSize: 11)),
          onTap: () => _activate(entry),
          onLongPress: () => _showEntryMenu(entry),
        );
      },
    );
  }

  Widget _buildGrid(List<FileSystemEntity> entries, RetroColors colors) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 90,
        mainAxisExtent: 86,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isDir = entry is Directory;
        final selected = _selected.contains(entry.path);
        return InkWell(
          onTap: () => _activate(entry),
          onLongPress: () => _showEntryMenu(entry),
          child: Container(
            color: selected ? colors.selection.withAlpha(60) : null,
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Icon(
                  isDir ? Icons.folder : iconForFile(entry.path),
                  size: 40,
                  color: isDir ? Colors.amber.shade700 : colors.text,
                ),
                const SizedBox(height: 2),
                Text(
                  _nameOf(entry.path),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.text, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
