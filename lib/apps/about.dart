// about.dart - About window
//
// Copyright (c) 2025 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.

import 'package:flutter/material.dart';

import '../core/settings.dart';
import '../core/version.dart';
import '../widgets/retro.dart';

class AboutApp extends StatelessWidget {
  const AboutApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = RetroColors.of(context);
    final textStyle = TextStyle(color: colors.text, fontSize: 13);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Image.asset(
            'assets/icon.png',
            width: 72,
            height: 72,
            errorBuilder: (context, error, stack) =>
                Icon(Icons.desktop_windows, size: 72, color: colors.selection),
          ),
          const SizedBox(height: 8),
          Text(
            'Mobile Desktop',
            style: TextStyle(
              color: colors.text,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text('${context.tr('version')} $kAppVersion', style: textStyle),
          const SizedBox(height: 12),
          Text(context.tr('about_description'),
              textAlign: TextAlign.center, style: textStyle),
          const SizedBox(height: 12),
          Text('© 2025 Ercan Ersoy', style: textStyle),
          Text(context.tr('license_mit'), style: textStyle),
          const SizedBox(height: 8),
          Text(context.tr('logo_notice'),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.disabledText, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 38,
            child: RetroButton(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Mobile Desktop',
                applicationVersion: kAppVersion,
                applicationLegalese: '© 2025 Ercan Ersoy',
              ),
              child: Text(context.tr('open_source_licenses')),
            ),
          ),
        ],
      ),
    );
  }
}
