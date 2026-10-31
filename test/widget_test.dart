// widget_test.dart - Tests of the Mobile Desktop app
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_desktop/apps/calculator_engine.dart';
import 'package:mobile_desktop/core/settings.dart';
import 'package:mobile_desktop/core/strings.dart';
import 'package:mobile_desktop/desktop/window_manager.dart';
import 'package:mobile_desktop/main.dart';

void main() {
  group('Calculator engine', () {
    test('follows operator precedence', () {
      expect(evaluateExpression('2+3×4'), 14);
      expect(evaluateExpression('(2+3)×4'), 20);
      expect(evaluateExpression('10−4÷2'), 8);
      expect(evaluateExpression('2^3^2'), 512);
      expect(evaluateExpression('−2^2'), -4);
    });

    test('supports percent, roots and decimals', () {
      expect(evaluateExpression('50%'), 0.5);
      expect(evaluateExpression('√16+1'), 5);
      expect(evaluateExpression('0.1+0.2'), closeTo(0.3, 1e-12));
      expect(evaluateExpression('1,5×2'), 3);
    });

    test('closes missing parentheses', () {
      expect(evaluateExpression('2×(3+4'), 14);
    });

    test('reports errors', () {
      expect(() => evaluateExpression('1÷0'),
          throwsA(isA<CalculatorException>()));
      expect(() => evaluateExpression('2+'),
          throwsA(isA<CalculatorException>()));
      expect(() => evaluateExpression('√−4'),
          throwsA(isA<CalculatorException>()));
    });

    test('formats numbers without useless zeros', () {
      expect(formatNumber(5), '5');
      expect(formatNumber(-2), '-2');
      expect(formatNumber(0.1 + 0.2), '0.3');
      expect(formatNumber(1 / 3), '0.333333333333');
      expect(evaluateExpression(formatNumber(1e20)), 1e20);
    });
  });

  group('Window manager', () {
    late WindowManager manager;

    setUp(() {
      manager = WindowManager()..desktopSize = const Size(400, 700);
    });

    AppWindow open(String id) => manager.open(
          appId: id,
          icon: Icons.apps,
          preferredSize: const Size(300, 300),
        );

    test('opens windows on top and focuses them', () {
      final a = open('a');
      final b = open('b');
      expect(manager.focused, b);
      manager.focus(a.id);
      expect(manager.focused, a);
      expect(manager.windows.last, a);
    });

    test('minimize and taskbar toggle', () {
      final a = open('a');
      manager.toggleFromTaskbar(a.id);
      expect(a.minimized, isTrue);
      expect(manager.focused, isNull);
      manager.toggleFromTaskbar(a.id);
      expect(a.minimized, isFalse);
      expect(manager.focused, a);
    });

    test('keeps windows inside the desktop', () {
      final a = open('a');
      manager.move(a.id, const Offset(5000, 5000));
      expect(a.rect.left, lessThanOrEqualTo(400 - 60));
      expect(a.rect.top, lessThanOrEqualTo(700 - 32));
      manager.resize(a.id, const Offset(-5000, -5000));
      expect(a.rect.width, WindowManager.minWidth);
      expect(a.rect.height, WindowManager.minHeight);
    });

    test('close guard can keep a window open', () async {
      final a = open('a');
      a.closeGuard = () async => false;
      await manager.close(a.id);
      expect(manager.windows, contains(a));
      await manager.close(a.id, force: true);
      expect(manager.windows, isEmpty);
    });

    test('maximized windows fill the desktop', () {
      final a = open('a');
      manager.toggleMaximize(a.id);
      expect(manager.visibleRect(a), Offset.zero & const Size(400, 700));
    });
  });

  test('translations exist for both languages', () {
    expect(translate('tr', 'start'), 'Başlat');
    expect(translate('en', 'start'), 'Start');
    expect(translate('de', 'start'), 'Start');
    expect(monthName('tr', 1), 'Ocak');
    expect(weekdayName('en', 7, short: true), 'Sun');
  });

  testWidgets('desktop opens apps from the start menu', (tester) async {
    SharedPreferences.setMockInitialValues({'language': 'en'});
    final settings = await AppSettings.load();
    await tester.binding.setSurfaceSize(const Size(480, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MyApp(settings: settings));
    await tester.pump();

    expect(find.text('Start'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('Calculator'), findsWidgets);

    await tester.tap(find.text('Calculator').last);
    await tester.pump();

    // The calculator window is open and works.
    await tester.tap(find.text('7'));
    await tester.tap(find.text('×'));
    await tester.tap(find.text('6'));
    await tester.tap(find.text('='));
    await tester.pump();
    expect(find.text('42'), findsWidgets);

    // Closing the window removes it.
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    expect(find.text('42'), findsNothing);
  });
}
