// calculator_engine.dart - Evaluates calculator expressions
//
// Copyright (c) 2025 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.

import 'dart:math' as math;

class CalculatorException implements Exception {
  const CalculatorException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Evaluates an expression such as "2+3×(4−1)^2" or "√16+50%".
///
/// Supported: + − × ÷ (also - * /), ^ (power), % (percent),
/// √ (square root), parentheses and decimal numbers.
/// Missing closing parentheses are added automatically.
double evaluateExpression(String input) {
  final parser = _Parser(_normalize(input));
  final value = parser.parse();
  if (value.isNaN || value.isInfinite) {
    throw const CalculatorException('error');
  }
  return value;
}

/// Turns a number into display text without useless zeros.
String formatNumber(double value) {
  if (value == value.roundToDouble() && value.abs() < 1e15) {
    return value.toInt().toString();
  }
  var text = value.toStringAsPrecision(12);
  if (text.contains('e')) {
    final parts = text.split('e');
    var mantissa = parts[0];
    if (mantissa.contains('.')) {
      mantissa = mantissa.replaceFirst(RegExp(r'0+$'), '');
      mantissa = mantissa.replaceFirst(RegExp(r'\.$'), '');
    }
    return '${mantissa}e${parts[1]}';
  }
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
  }
  return text;
}

String _normalize(String input) => input
    .replaceAll('×', '*')
    .replaceAll('÷', '/')
    .replaceAll('−', '-')
    .replaceAll(',', '.')
    .replaceAll(' ', '');

class _Parser {
  _Parser(this.text);

  final String text;
  int pos = 0;

  double parse() {
    if (text.isEmpty) return 0;
    final value = _expression();
    if (pos < text.length) {
      throw CalculatorException('unexpected "${text[pos]}"');
    }
    return value;
  }

  String? get _peek => pos < text.length ? text[pos] : null;

  bool _accept(String char) {
    if (_peek == char) {
      pos++;
      return true;
    }
    return false;
  }

  // expression := term (('+' | '-') term)*
  double _expression() {
    var value = _term();
    while (true) {
      if (_accept('+')) {
        value += _term();
      } else if (_accept('-')) {
        value -= _term();
      } else {
        return value;
      }
    }
  }

  // term := unary (('*' | '/') unary)*
  double _term() {
    var value = _unary();
    while (true) {
      if (_accept('*')) {
        value *= _unary();
      } else if (_accept('/')) {
        final divisor = _unary();
        if (divisor == 0) throw const CalculatorException('division by zero');
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  // unary := ('-' | '+') unary | power
  double _unary() {
    if (_accept('-')) return -_unary();
    if (_accept('+')) return _unary();
    return _power();
  }

  // power := postfix ('^' unary)?
  double _power() {
    final base = _postfix();
    if (_accept('^')) {
      final exponent = _unary();
      return math.pow(base, exponent).toDouble();
    }
    return base;
  }

  // postfix := primary '%'*
  double _postfix() {
    var value = _primary();
    while (_accept('%')) {
      value /= 100;
    }
    return value;
  }

  // primary := number | '(' expression ')' | '√' unary
  double _primary() {
    if (_accept('(')) {
      final value = _expression();
      // A missing ')' at the end is allowed.
      if (!_accept(')') && pos < text.length) {
        throw const CalculatorException('missing )');
      }
      return value;
    }
    if (_accept('√')) {
      final value = _unary();
      if (value < 0) throw const CalculatorException('negative root');
      return math.sqrt(value);
    }
    return _number();
  }

  double _number() {
    final start = pos;
    while (pos < text.length && '0123456789.'.contains(text[pos])) {
      pos++;
    }
    // Scientific notation such as 1e-7 (from earlier results).
    if (pos > start && pos < text.length && text[pos] == 'e') {
      var next = pos + 1;
      if (next < text.length && (text[next] == '-' || text[next] == '+')) {
        next++;
      }
      if (next < text.length && '0123456789'.contains(text[next])) {
        pos = next;
        while (pos < text.length && '0123456789'.contains(text[pos])) {
          pos++;
        }
      }
    }
    if (start == pos) {
      throw CalculatorException(
          pos < text.length ? 'unexpected "${text[pos]}"' : 'unexpected end');
    }
    final value = double.tryParse(text.substring(start, pos));
    if (value == null) throw const CalculatorException('bad number');
    return value;
  }
}
