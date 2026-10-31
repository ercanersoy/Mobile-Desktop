// notepad.dart - Simple text editor
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/settings.dart';
import '../desktop/window_manager.dart';
import '../widgets/file_dialog.dart';
import '../widgets/retro.dart';

class NotepadApp extends StatefulWidget {
  const NotepadApp({super.key, this.path});

  /// File to open at start.
  final String? path;

  @override
  State<NotepadApp> createState() => _NotepadAppState();
}

class _NotepadAppState extends State<NotepadApp> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _path;
  String _savedText = '';
  bool _monospace = false;
  String _lastSearch = '';
  AppWindow? _window;

  bool get _dirty => _controller.text != _savedText;

  String get _fileName =>
      _path?.split('/').last ?? context.tr('untitled');

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    if (widget.path != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(widget.path!));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_window == null) {
      _window = WindowScope.maybeOf(context);
      _window?.closeGuard = _confirmDiscard;
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateTitle());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _wasDirty = false;

  void _onChanged() {
    // Rebuild for the status bar (cursor position, length).
    setState(() {});
    if (_dirty != _wasDirty) {
      _wasDirty = _dirty;
      _updateTitle();
    }
  }

  void _updateTitle() {
    final window = _window;
    if (window == null || !mounted) return;
    final mark = _dirty ? '*' : '';
    WindowManagerScope.read(context)
        .setTitle(window.id, '$mark$_fileName - ${context.tr('app_notepad')}');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _load(String path) async {
    try {
      final text = await File(path).readAsString();
      if (!mounted) return;
      setState(() {
        _path = path;
        _savedText = text;
        _controller.text = text;
        _controller.selection = const TextSelection.collapsed(offset: 0);
      });
      _wasDirty = false;
      _updateTitle();
    } catch (_) {
      if (mounted) _showMessage(context.tr('file_read_error'));
    }
  }

  Future<bool> _save({bool askPath = false}) async {
    var path = _path;
    if (path == null || askPath) {
      path = await showSaveFileDialog(
        context,
        initialDirectory: _path == null ? null : File(_path!).parent.path,
        suggestedName: _path?.split('/').last ?? 'note.txt',
      );
      if (path == null) return false;
    }
    try {
      await File(path).writeAsString(_controller.text);
      if (!mounted) return true;
      setState(() {
        _path = path;
        _savedText = _controller.text;
      });
      _wasDirty = false;
      _updateTitle();
      _showMessage(context.tr('saved'));
      return true;
    } catch (_) {
      if (mounted) _showMessage(context.tr('file_write_error'));
      return false;
    }
  }

  /// Asks what to do with unsaved changes. Returns true when it is
  /// fine to continue (close, open another file, ...).
  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('app_notepad')),
        content: Text(context.tr('unsaved_changes')
            .replaceAll('{name}', _fileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text(context.tr('dont_save')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
    if (choice == 'discard') return true;
    if (choice == 'save') return _save();
    return false;
  }

  Future<void> _newFile() async {
    if (!await _confirmDiscard()) return;
    setState(() {
      _path = null;
      _savedText = '';
      _controller.clear();
    });
    _wasDirty = false;
    _updateTitle();
  }

  Future<void> _openFile() async {
    if (!await _confirmDiscard()) return;
    if (!mounted) return;
    final path = await showOpenFileDialog(
      context,
      initialDirectory: _path == null ? null : File(_path!).parent.path,
    );
    if (path != null) await _load(path);
  }

  Future<void> _find() async {
    final controller = TextEditingController(text: _lastSearch);
    final query = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('find')),
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
            child: Text(context.tr('find_next')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (query == null || query.isEmpty) return;
    _lastSearch = query;
    _findNext();
  }

  void _findNext() {
    if (_lastSearch.isEmpty) return;
    final text = _controller.text.toLowerCase();
    final query = _lastSearch.toLowerCase();
    final start = _controller.selection.end < 0 ? 0 : _controller.selection.end;
    var index = text.indexOf(query, start);
    if (index < 0) index = text.indexOf(query);
    if (index < 0) {
      _showMessage(context.tr('not_found').replaceAll('{text}', _lastSearch));
      return;
    }
    _controller.selection =
        TextSelection(baseOffset: index, extentOffset: index + query.length);
    _focusNode.requestFocus();
  }

  Future<void> _copy() async {
    final selection = _controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    await Clipboard.setData(
        ClipboardData(text: selection.textInside(_controller.text)));
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null) return;
    final value = _controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    _controller.value = value.replaced(selection, text);
    _focusNode.requestFocus();
  }

  void _insertDate() {
    final value = _controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    _controller.value =
        value.replaced(selection, formatDateTime(DateTime.now()));
  }

  void _changeFontSize(double delta) {
    final settings = SettingsScope.read(context);
    settings.notepadFontSize =
        (settings.notepadFontSize + delta).clamp(10.0, 32.0).toDouble();
  }

  void _onMenu(String action) {
    switch (action) {
      case 'new':
        _newFile();
      case 'open':
        _openFile();
      case 'save':
        _save();
      case 'save_as':
        _save(askPath: true);
      case 'find':
        _find();
      case 'find_next':
        _findNext();
      case 'select_all':
        _controller.selection = TextSelection(
            baseOffset: 0, extentOffset: _controller.text.length);
        _focusNode.requestFocus();
      case 'copy':
        _copy();
      case 'paste':
        _paste();
      case 'date':
        _insertDate();
      case 'zoom_in':
        _changeFontSize(2);
      case 'zoom_out':
        _changeFontSize(-2);
      case 'monospace':
        setState(() => _monospace = !_monospace);
    }
  }

  /// Line and column of the cursor (1-based).
  (int, int) _cursorPosition() {
    final text = _controller.text;
    var offset = _controller.selection.baseOffset;
    if (offset < 0 || offset > text.length) offset = text.length;
    final before = text.substring(0, offset);
    final line = '\n'.allMatches(before).length + 1;
    final column = offset - (before.lastIndexOf('\n') + 1) + 1;
    return (line, column);
  }

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    final settings = SettingsScope.of(context);
    final (line, column) = _cursorPosition();
    final lineCount = '\n'.allMatches(_controller.text).length + 1;

    PopupMenuItem<String> item(String value, String labelKey,
        [String? shortcut]) {
      return PopupMenuItem<String>(
        value: value,
        height: 40,
        child: Row(
          children: [
            Expanded(child: Text(context.tr(labelKey))),
            if (shortcut != null)
              Text(shortcut,
                  style: TextStyle(fontSize: 12, color: colors.disabledText)),
          ],
        ),
      );
    }

    Widget menu(String labelKey, List<PopupMenuEntry<String>> items) {
      return PopupMenuButton<String>(
        onSelected: _onMenu,
        itemBuilder: (_) => items,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(context.tr(labelKey),
              style: TextStyle(color: colors.text, fontSize: 14)),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyO, control: true):
            _openFile,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            _newFile,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _find,
        const SingleActivator(LogicalKeyboardKey.f3): _findNext,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              menu('menu_file', [
                item('new', 'new', 'Ctrl+N'),
                item('open', 'open', 'Ctrl+O'),
                item('save', 'save', 'Ctrl+S'),
                item('save_as', 'save_as'),
              ]),
              menu('menu_edit', [
                item('select_all', 'select_all'),
                item('copy', 'copy'),
                item('paste', 'paste'),
                const PopupMenuDivider(),
                item('find', 'find', 'Ctrl+F'),
                item('find_next', 'find_next', 'F3'),
                const PopupMenuDivider(),
                item('date', 'insert_date'),
              ]),
              menu('menu_view', [
                item('zoom_in', 'zoom_in'),
                item('zoom_out', 'zoom_out'),
                CheckedPopupMenuItem(
                  value: 'monospace',
                  checked: _monospace,
                  child: Text(context.tr('monospace')),
                ),
              ]),
            ],
          ),
          Expanded(
            child: Bevel(
              sunken: true,
              color: colors.field,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  color: colors.text,
                  fontSize: settings.notepadFontSize,
                  fontFamily: _monospace ? 'monospace' : null,
                ),
                cursorColor: colors.text,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(6),
                  isCollapsed: true,
                ),
              ),
            ),
          ),
          StatusBar(children: [
            Text('${context.tr('line')} $line, ${context.tr('column')} $column'),
            Text('$lineCount ${context.tr('lines')}'),
            Text('${_controller.text.length} ${context.tr('chars')}'),
          ]),
        ],
      ),
    );
  }
}
