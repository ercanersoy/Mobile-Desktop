// start_menu.dart - The start menu
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../apps/app_registry.dart';
import '../core/settings.dart';
import '../widgets/retro.dart';

class StartMenu extends StatelessWidget {
  const StartMenu({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    final programs = Apps.all.where((app) => app.inStartMenu).toList();

    void open(String appId) {
      onClose();
      Apps.launch(context, appId);
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 250,
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Color(0x88000000), blurRadius: 6, offset: Offset(2, 2)),
          ],
        ),
        child: Bevel(
          padding: const EdgeInsets.all(2),
          child: Stack(
            children: [
              // Vertical banner on the left side.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 28,
                child: Container(
                  width: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: colors.activeTitle,
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: const RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'Mobile Desktop',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final app in programs)
                          _MenuEntry(
                            icon: app.icon,
                            iconColor: app.color,
                            label: context.tr(app.nameKey),
                            onTap: () => open(app.id),
                          ),
                        const _MenuDivider(),
                        _MenuEntry(
                          icon: Icons.settings,
                          label: context.tr('app_settings'),
                          onTap: () => open('settings'),
                        ),
                        _MenuEntry(
                          icon: Icons.info_outline,
                          label: context.tr('app_about'),
                          onTap: () => open('about'),
                        ),
                        const _MenuDivider(),
                        _MenuEntry(
                          icon: Icons.power_settings_new,
                          iconColor: Colors.red.shade600,
                          label: context.tr('exit_app'),
                          onTap: () async {
                            onClose();
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(context.tr('exit_app')),
                                content: Text(context.tr('exit_confirm')),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(context.tr('cancel')),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(context.tr('ok')),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await SystemNavigator.pop();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuEntry extends StatelessWidget {
  const _MenuEntry({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    return InkWell(
      onTap: onTap,
      hoverColor: colors.selection.withAlpha(60),
      splashColor: colors.selection.withAlpha(90),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor ?? colors.text),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: colors.text, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: Column(
        children: [
          Container(height: 1, color: colors.shadow),
          Container(height: 1, color: colors.highlight),
        ],
      ),
    );
  }
}
