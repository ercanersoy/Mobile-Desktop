// retro.dart - Classic desktop look (bevelled borders and buttons)
//
// Copyright (c) 2025 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.

import 'package:flutter/material.dart';

/// Colors of the classic desktop look for light and dark themes.
class RetroColors {
  const RetroColors._({
    required this.face,
    required this.highlight,
    required this.shadow,
    required this.darkShadow,
    required this.text,
    required this.disabledText,
    required this.activeTitle,
    required this.inactiveTitle,
    required this.titleText,
    required this.field,
    required this.selection,
  });

  final Color face;
  final Color highlight;
  final Color shadow;
  final Color darkShadow;
  final Color text;
  final Color disabledText;
  final List<Color> activeTitle;
  final List<Color> inactiveTitle;
  final Color titleText;
  final Color field;
  final Color selection;

  static const RetroColors light = RetroColors._(
    face: Color(0xFFC0C0C0),
    highlight: Color(0xFFFFFFFF),
    shadow: Color(0xFF808080),
    darkShadow: Color(0xFF000000),
    text: Color(0xFF000000),
    disabledText: Color(0xFF808080),
    activeTitle: [Color(0xFF000080), Color(0xFF1084D0)],
    inactiveTitle: [Color(0xFF808080), Color(0xFFB5B5B5)],
    titleText: Color(0xFFFFFFFF),
    field: Color(0xFFFFFFFF),
    selection: Color(0xFF000080),
  );

  static const RetroColors dark = RetroColors._(
    face: Color(0xFF3A3F44),
    highlight: Color(0xFF5E656C),
    shadow: Color(0xFF24282B),
    darkShadow: Color(0xFF0B0C0D),
    text: Color(0xFFEDEDED),
    disabledText: Color(0xFF8A9096),
    activeTitle: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
    inactiveTitle: [Color(0xFF2B2F33), Color(0xFF4A5056)],
    titleText: Color(0xFFFFFFFF),
    field: Color(0xFF1E2124),
    selection: Color(0xFF1E88E5),
  );

  static RetroColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Raised (or sunken) 3D border.
class Bevel extends StatelessWidget {
  const Bevel({
    super.key,
    required this.child,
    this.sunken = false,
    this.color,
    this.padding = EdgeInsets.zero,
    this.width = 2,
  });

  final Widget child;
  final bool sunken;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    final light = sunken ? colors.shadow : colors.highlight;
    final dark = sunken ? colors.highlight : colors.darkShadow;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.face,
        border: Border(
          top: BorderSide(color: light, width: width),
          left: BorderSide(color: light, width: width),
          bottom: BorderSide(color: dark, width: width),
          right: BorderSide(color: dark, width: width),
        ),
      ),
      child: child,
    );
  }
}

/// Button with the classic raised look that sinks when pressed.
class RetroButton extends StatefulWidget {
  const RetroButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.pressed = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.color,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  /// Shows the button as pushed in (for toggles and the active window).
  final bool pressed;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final String? tooltip;

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    final enabled = widget.onPressed != null || widget.onLongPress != null;
    final sunken = widget.pressed || _down;
    Widget button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setDown(true) : null,
      onTapUp: enabled ? (_) => _setDown(false) : null,
      onTapCancel: enabled ? () => _setDown(false) : null,
      onTap: widget.onPressed,
      onLongPress: widget.onLongPress,
      child: Bevel(
        sunken: sunken,
        color: widget.color,
        padding: widget.padding,
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: enabled ? colors.text : colors.disabledText,
            fontSize: 13,
          ),
          child: IconTheme.merge(
            data: IconThemeData(
              color: enabled ? colors.text : colors.disabledText,
              size: 18,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Transform.translate(
                offset: sunken ? const Offset(1, 1) : Offset.zero,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return Semantics(button: true, enabled: enabled, child: button);
  }
}

/// A bar with small icon buttons, used at the top of most apps.
class RetroToolbar extends StatelessWidget {
  const RetroToolbar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Bevel(
      width: 1,
      padding: const EdgeInsets.all(2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: children),
      ),
    );
  }
}

/// Square icon button for a [RetroToolbar].
class ToolbarButton extends StatelessWidget {
  const ToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.pressed = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: SizedBox(
        width: 36,
        height: 34,
        child: RetroButton(
          tooltip: tooltip,
          onPressed: onPressed,
          pressed: pressed,
          padding: EdgeInsets.zero,
          child: Icon(icon),
        ),
      ),
    );
  }
}

/// Toolbar button that opens a popup menu below itself.
class ToolbarMenuButton<T> extends StatelessWidget {
  const ToolbarMenuButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.itemBuilder,
    required this.onSelected,
  });

  final IconData icon;
  final String tooltip;

  /// Called each time the menu opens, so checked items stay current.
  final List<PopupMenuEntry<T>> Function(BuildContext context) itemBuilder;
  final ValueChanged<T> onSelected;

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final topLeft =
        box.localToGlobal(box.size.bottomLeft(Offset.zero), ancestor: overlay);
    final bottomRight = box.localToGlobal(box.size.bottomRight(Offset.zero),
        ancestor: overlay);
    final value = await showMenu<T>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(topLeft, bottomRight),
        Offset.zero & overlay.size,
      ),
      items: itemBuilder(context),
    );
    if (value != null) onSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    return ToolbarButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: () => _openMenu(context),
    );
  }
}

/// Thin status bar shown at the bottom of an app.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    return Bevel(
      width: 1,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(
              flex: i == 0 ? 2 : 1,
              child: Bevel(
                sunken: true,
                width: 1,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: colors.text, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: children[i],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Horizontal bar that shows how full something is.
class UsageBar extends StatelessWidget {
  const UsageBar({super.key, required this.value, this.color});

  /// From 0 to 1.
  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    final barColor = color ??
        (v > 0.9
            ? Colors.red.shade600
            : v > 0.75
                ? Colors.orange.shade700
                : colors.selection);
    return Bevel(
      sunken: true,
      width: 1,
      color: colors.field,
      child: SizedBox(
        height: 14,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v,
            heightFactor: 1,
            child: Container(color: barColor),
          ),
        ),
      ),
    );
  }
}

/// Formats a byte count as "1.5 GB".
String formatBytes(num bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = unit == 0 || value >= 100
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}

/// Formats a date and time as "2025-01-31 14:05".
String formatDateTime(DateTime time) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)} '
      '${two(time.hour)}:${two(time.minute)}';
}
