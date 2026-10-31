// terminal.dart - Command prompt that runs shell commands
//
// Copyright (c) 2025 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/settings.dart';
import '../core/storage_access.dart';
import '../desktop/window_manager.dart';

class _Line {
  const _Line(this.text, this.kind);

  final String text;

  /// 'in' for typed commands, 'out', 'err' or 'info'.
  final String kind;
}

class TerminalApp extends StatefulWidget {
  const TerminalApp({super.key});

  @override
  State<TerminalApp> createState() => _TerminalAppState();
}

class _TerminalAppState extends State<TerminalApp> {
  static const int _maxLines = 2000;

  final List<_Line> _lines = [];
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();
  final List<String> _history = [];
  int _historyIndex = 0;
  String _cwd = '/';
  Process? _process;

  String get _shell =>
      File('/system/bin/sh').existsSync() ? '/system/bin/sh' : '/bin/sh';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final home = await StorageAccess.appFolder();
    if (!mounted) return;
    setState(() => _cwd = home);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _add(context.tr('terminal_welcome'), 'info');
    });
  }

  @override
  void dispose() {
    _process?.kill();
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _add(String text, String kind) {
    if (!mounted) return;
    setState(() {
      for (final line in const LineSplitter().convert(text)) {
        _lines.add(_Line(line, kind));
      }
      if (text.isEmpty) _lines.add(_Line('', kind));
      if (_lines.length > _maxLines) {
        _lines.removeRange(0, _lines.length - _maxLines);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _submit(String command) async {
    command = command.trim();
    _input.clear();
    _focus.requestFocus();
    if (_process != null) {
      // Send typed text to the running program.
      _process!.stdin.writeln(command);
      _add(command, 'in');
      return;
    }
    _add('$_cwd \$ $command', 'in');
    if (command.isEmpty) return;
    if (_history.isEmpty || _history.last != command) _history.add(command);
    _historyIndex = _history.length;

    final parts = command.split(RegExp(r'\s+'));
    switch (parts.first) {
      case 'clear':
      case 'cls':
        setState(_lines.clear);
        return;
      case 'exit':
        final window = WindowScope.maybeOf(context);
        if (window != null) {
          WindowManagerScope.read(context).close(window.id);
        }
        return;
      case 'help':
        _add(context.tr('terminal_help'), 'info');
        return;
      case 'cd':
        _changeDirectory(parts.length > 1 ? parts.sublist(1).join(' ') : '');
        return;
    }
    await _run(command);
  }

  void _changeDirectory(String target) {
    String path;
    if (target.isEmpty || target == '~') {
      path = Platform.isAndroid ? StorageAccess.androidRoot : (Platform.environment['HOME'] ?? '/');
    } else if (target.startsWith('/')) {
      path = target;
    } else {
      path = '$_cwd/$target';
    }
    String? resolved;
    try {
      resolved = Directory(path).resolveSymbolicLinksSync();
    } catch (_) {
      resolved = null;
    }
    if (resolved == null || !Directory(resolved).existsSync()) {
      _add('cd: $target: ${context.tr('no_such_folder')}', 'err');
      return;
    }
    setState(() => _cwd = resolved!);
  }

  Future<void> _run(String command) async {
    try {
      final process = await Process.start(
        _shell,
        ['-c', command],
        workingDirectory: _cwd,
      );
      setState(() => _process = process);
      final outDone = process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .forEach((data) => _add(_trimEnd(data), 'out'));
      final errDone = process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .forEach((data) => _add(_trimEnd(data), 'err'));
      final code = await process.exitCode;
      try {
        await Future.wait([outDone, errDone]);
      } catch (_) {
        // Output stream failed; the exit code is still shown.
      }
      if (!mounted) return;
      if (code != 0) _add('[${context.tr('exit_code')}: $code]', 'info');
    } catch (e) {
      if (mounted) _add('$e', 'err');
    } finally {
      if (mounted) setState(() => _process = null);
    }
  }

  String _trimEnd(String text) =>
      text.endsWith('\n') ? text.substring(0, text.length - 1) : text;

  void _stop() {
    _process?.kill(ProcessSignal.sigint);
    _process?.kill();
  }

  void _historyStep(int delta) {
    if (_history.isEmpty) return;
    _historyIndex = (_historyIndex + delta).clamp(0, _history.length).toInt();
    final text = _historyIndex >= _history.length ? '' : _history[_historyIndex];
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0C0C0C);
    const mono = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      height: 1.25,
    );

    Color colorOf(String kind) {
      switch (kind) {
        case 'in':
          return const Color(0xFF7CFC00);
        case 'err':
          return const Color(0xFFFF6B6B);
        case 'info':
          return const Color(0xFF6CB6FF);
        default:
          return const Color(0xFFDDDDDD);
      }
    }

    return Container(
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _focus.requestFocus(),
              child: SelectionArea(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(6),
                  itemCount: _lines.length,
                  itemBuilder: (context, index) {
                    final line = _lines[index];
                    return Text(
                      line.text,
                      style: mono.copyWith(color: colorOf(line.kind)),
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Flexible(
                  flex: 0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      _process != null ? '>' : '${_cwd.split('/').last} \$',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mono.copyWith(color: const Color(0xFF7CFC00)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;
                      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        _historyStep(-1);
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        _historyStep(1);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      autofocus: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: mono.copyWith(color: Colors.white),
                      cursorColor: Colors.white,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: context.tr('terminal_hint'),
                        hintStyle: mono.copyWith(color: Colors.white38),
                      ),
                      onSubmitted: _submit,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.history, color: Colors.white70),
                  tooltip: context.tr('previous_command'),
                  onPressed: () => _historyStep(-1),
                ),
                if (_process != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.stop_circle, color: Colors.redAccent),
                    tooltip: context.tr('stop'),
                    onPressed: _stop,
                  )
                else
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.keyboard_return, color: Colors.white70),
                    tooltip: context.tr('run'),
                    onPressed: () => _submit(_input.text),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
