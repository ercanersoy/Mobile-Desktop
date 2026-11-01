// calendar.dart - Month calendar with notes for each day
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code.

import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/settings.dart';
import '../core/strings.dart';
import '../widgets/retro.dart';

class CalendarApp extends StatefulWidget {
  const CalendarApp({super.key});

  @override
  State<CalendarApp> createState() => _CalendarAppState();
}

class _CalendarAppState extends State<CalendarApp> {
  static const String _prefsKey = 'calendarNotes';

  late DateTime _month;
  late DateTime _selected;

  /// Notes per day, keyed by "yyyy-mm-dd".
  Map<String, List<String>> _notes = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_notes.isEmpty) _loadNotes();
  }

  void _loadNotes() {
    final raw = SettingsScope.read(context).prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _notes = decoded.map(
          (key, value) => MapEntry(key, List<String>.from(value as List)));
    } catch (_) {
      _notes = {};
    }
  }

  Future<void> _saveNotes() async {
    _notes.removeWhere((_, list) => list.isEmpty);
    await SettingsScope.read(context)
        .prefs
        .setString(_prefsKey, jsonEncode(_notes));
  }

  String _key(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month);
      _selected = DateTime(now.year, now.month, now.day);
    });
  }

  Future<void> _editNote({int? index}) async {
    final list = _notes[_key(_selected)] ?? [];
    final controller =
        TextEditingController(text: index == null ? '' : list[index]);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr(index == null ? 'add_note' : 'edit_note')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty) return;
    setState(() {
      final notes = _notes.putIfAbsent(_key(_selected), () => []);
      if (index == null) {
        notes.add(text.trim());
      } else {
        notes[index] = text.trim();
      }
    });
    await _saveNotes();
  }

  Future<void> _deleteNote(int index) async {
    setState(() => _notes[_key(_selected)]?.removeAt(index));
    await _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    final lang = SettingsScope.of(context).language;
    final today = DateTime.now();
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Weeks start on Monday.
    final leading = firstDay.weekday - 1;
    final cellCount = ((leading + daysInMonth) / 7).ceil() * 7;
    final notes = _notes[_key(_selected)] ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroToolbar(children: [
          ToolbarButton(
            icon: Icons.chevron_left,
            tooltip: context.tr('previous'),
            onPressed: () => _changeMonth(-1),
          ),
          ToolbarButton(
            icon: Icons.today,
            tooltip: context.tr('today'),
            onPressed: _goToday,
          ),
          ToolbarButton(
            icon: Icons.chevron_right,
            tooltip: context.tr('next'),
            onPressed: () => _changeMonth(1),
          ),
          const SizedBox(width: 8),
          Text(
            '${monthName(lang, _month.month)} ${_month.year}',
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Row(
            children: [
              for (var d = 1; d <= 7; d++)
                Expanded(
                  child: Center(
                    child: Text(
                      weekdayName(lang, d, short: true),
                      style: TextStyle(
                        color: d >= 6 ? Colors.red.shade400 : colors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 38,
            ),
            itemCount: cellCount,
            itemBuilder: (context, index) {
              final dayNumber = index - leading + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final day = DateTime(_month.year, _month.month, dayNumber);
              final isToday = day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              final isSelected = day == _selected;
              final hasNotes = (_notes[_key(day)] ?? const []).isNotEmpty;
              return GestureDetector(
                onTap: () => setState(() => _selected = day),
                onDoubleTap: () {
                  setState(() => _selected = day);
                  _editNote();
                },
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.selection
                        : isToday
                            ? colors.selection.withAlpha(50)
                            : colors.field,
                    border: Border.all(
                      color: isToday ? colors.selection : colors.shadow,
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : day.weekday >= 6
                                    ? Colors.red.shade400
                                    : colors.text,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasNotes)
                        Positioned(
                          right: 3,
                          top: 3,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.orange.shade700,
                              shape: BoxShape.circle,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_selected.day} ${monthName(lang, _selected.month)} '
                  '${_selected.year}, ${weekdayName(lang, _selected.weekday)}',
                  style: TextStyle(
                      color: colors.text, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, color: colors.text),
                tooltip: context.tr('add_note'),
                onPressed: () => _editNote(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Bevel(
            sunken: true,
            color: colors.field,
            child: notes.isEmpty
                ? Center(
                    child: Text(
                      context.tr('no_notes'),
                      style: TextStyle(color: colors.disabledText),
                    ),
                  )
                : ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) => ListTile(
                      dense: true,
                      leading: Icon(Icons.event_note,
                          color: Colors.orange.shade700),
                      title: Text(notes[index],
                          style: TextStyle(color: colors.text)),
                      onTap: () => _editNote(index: index),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: colors.disabledText),
                        tooltip: context.tr('delete'),
                        onPressed: () => _deleteNote(index),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
