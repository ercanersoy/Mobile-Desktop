// calculator.dart - Calculator app
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code Opus 5.5.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/settings.dart';
import '../widgets/retro.dart';
import 'calculator_engine.dart';

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  String _expression = '';
  String _result = '0';
  String _previous = '';
  bool _error = false;
  bool _justEvaluated = false;
  double _memory = 0;
  final FocusNode _focusNode = FocusNode();

  static const String _operators = '+−×÷^';

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _input(String key) {
    setState(() {
      _error = false;
      switch (key) {
        case 'C':
          _expression = '';
          _result = '0';
          _previous = '';
          _justEvaluated = false;
        case '⌫':
          if (_justEvaluated) {
            _expression = '';
            _justEvaluated = false;
          } else if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
          _preview();
        case '=':
          _evaluate();
        case '±':
          _toggleSign();
        case 'x²':
          if (_expression.isEmpty) _expression = _result.replaceAll('-', '−');
          final last = _expression[_expression.length - 1];
          if (!_operators.contains(last) && last != '(') {
            _expression += '^2';
          }
          _justEvaluated = false;
          _preview();
        case 'MC':
          _memory = 0;
        case 'MR':
          _appendValue(formatNumber(_memory).replaceAll('-', '−'));
        case 'M+':
          _memory += _currentValue() ?? 0;
        case 'M−':
          _memory -= _currentValue() ?? 0;
        default:
          if (_operators.contains(key)) {
            _appendOperator(key);
          } else if (key == '%') {
            if (_expression.isNotEmpty) _expression += '%';
            _justEvaluated = false;
          } else {
            _appendValue(key);
          }
          _preview();
      }
    });
  }

  /// Adds a digit, dot, parenthesis or root sign.
  void _appendValue(String value) {
    if (_justEvaluated) {
      // Typing a number after "=" starts a new calculation.
      _expression = '';
      _justEvaluated = false;
    }
    if (value == '.') {
      final lastNumber = RegExp(r'[0-9.]*$').stringMatch(_expression) ?? '';
      if (lastNumber.contains('.')) return;
      if (lastNumber.isEmpty) value = '0.';
    }
    _expression += value;
  }

  void _appendOperator(String op) {
    _justEvaluated = false;
    if (_expression.isEmpty) {
      if (op == '−') _expression = '−';
      if (_result != '0' && op != '−') {
        _expression = _result.replaceAll('-', '−') + op;
      }
      return;
    }
    final last = _expression[_expression.length - 1];
    if (_operators.contains(last)) {
      // A second operator in a row overrides the first one.
      _expression = _expression.substring(0, _expression.length - 1) + op;
    } else if (last == '(' && op != '−') {
      return;
    } else {
      _expression += op;
    }
  }

  void _toggleSign() {
    if (_expression.isEmpty) return;
    _expression = toggleLastSign(_expression);
    _justEvaluated = false;
    _preview();
  }

  double? _currentValue() {
    try {
      return evaluateExpression(_expression.isEmpty ? _result : _expression);
    } catch (_) {
      return null;
    }
  }

  /// Shows the result while typing.
  void _preview() {
    if (_expression.isEmpty) {
      _result = '0';
      return;
    }
    try {
      _result = formatNumber(evaluateExpression(_expression));
    } catch (_) {
      // Incomplete expression; keep the last result.
    }
  }

  void _evaluate() {
    if (_expression.isEmpty) return;
    try {
      final value = evaluateExpression(_expression);
      _previous = '$_expression =';
      _result = formatNumber(value);
      _expression = _result.replaceAll('-', '−');
      _justEvaluated = true;
    } catch (_) {
      _error = true;
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final char = event.character;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _input('=');
    } else if (key == LogicalKeyboardKey.backspace) {
      _input('⌫');
    } else if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.delete) {
      _input('C');
    } else if (char != null && char.isNotEmpty) {
      const map = {'*': '×', '/': '÷', '-': '−', ',': '.', 'r': '√'};
      final mapped = map[char] ?? char;
      if ('0123456789.+−×÷^%()√'.contains(mapped) || mapped == '=') {
        _input(mapped);
      } else {
        return KeyEventResult.ignored;
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    final operatorColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.lightBlue.shade200
        : Colors.blue.shade800;
    const rows = [
      ['MC', 'MR', 'M+', 'M−'],
      ['(', ')', '√', 'x²'],
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['±', '0', '.', '='],
    ];

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Bevel(
              sunken: true,
              color: colors.field,
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      if (_memory != 0)
                        Text('M',
                            style: TextStyle(
                                color: colors.disabledText, fontSize: 12)),
                      Expanded(
                        child: Text(
                          _previous,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: colors.disabledText, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      _expression.isEmpty ? ' ' : _expression,
                      style: TextStyle(color: colors.text, fontSize: 16),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _error ? context.tr('calc_error') : _result,
                      style: TextStyle(
                        color: _error ? Colors.red : colors.text,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Column(
                children: [
                  for (final row in rows)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final key in row)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: RetroButton(
                                  onPressed: () {
                                    _focusNode.requestFocus();
                                    _input(key);
                                  },
                                  color: key == '='
                                      ? colors.selection
                                      : null,
                                  padding: EdgeInsets.zero,
                                  child: Text(
                                    key,
                                    style: TextStyle(
                                      fontSize: key.length > 1 ? 14 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: key == '='
                                          ? Colors.white
                                          : _operators.contains(key)
                                              ? operatorColor
                                              : key == 'C' || key == '⌫'
                                                  ? Colors.red.shade700
                                                  : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
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
