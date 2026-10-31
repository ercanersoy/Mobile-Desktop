// native_system.dart - Access to Android system information
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code.

import 'dart:io';

import 'package:flutter/services.dart';

/// Talks to MainActivity.kt over a method channel. Every call has a
/// fallback, so the app keeps working on other platforms and in tests.
class NativeSystem {
  NativeSystem._();

  static const MethodChannel _channel =
      MethodChannel('net.ercanersoy.mobile_desktop/system');

  static Map<String, dynamic>? _deviceCache;

  static Future<Map<String, dynamic>> _call(String method) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(method);
      return result ?? <String, dynamic>{};
    } on MissingPluginException {
      return <String, dynamic>{};
    } on PlatformException {
      return <String, dynamic>{};
    }
  }

  /// Manufacturer, model, Android version, SDK level and so on.
  static Future<Map<String, dynamic>> deviceInfo() async {
    return _deviceCache ??= await _call('getDeviceInfo');
  }

  /// Android API level, or 0 when it is unknown.
  static Future<int> sdkInt() async {
    final info = await deviceInfo();
    return (info['sdkInt'] as int?) ?? 0;
  }

  /// Total and available RAM in bytes.
  static Future<Map<String, dynamic>> memoryInfo() async {
    final info = await _call('getMemoryInfo');
    if (info.isNotEmpty) return info;
    return _memoryFromProc();
  }

  /// Total and free space of internal storage in bytes.
  static Future<Map<String, dynamic>> storageInfo() => _call('getStorageInfo');

  /// Battery level (0-100), charging state, temperature and so on.
  static Future<Map<String, dynamic>> batteryInfo() => _call('getBatteryInfo');

  /// Time since boot in milliseconds, or null when it is unknown.
  static Future<int?> uptimeMillis() async {
    final info = await _call('getUptime');
    final value = info['uptime'];
    if (value is int) return value;
    try {
      final text = await File('/proc/uptime').readAsString();
      final seconds = double.parse(text.split(' ').first);
      return (seconds * 1000).round();
    } catch (_) {
      return null;
    }
  }

  /// Reads RAM information from /proc/meminfo (works on Linux and
  /// most Android devices).
  static Future<Map<String, dynamic>> _memoryFromProc() async {
    try {
      final lines = await File('/proc/meminfo').readAsLines();
      int? read(String key) {
        for (final line in lines) {
          if (line.startsWith('$key:')) {
            final kb = int.tryParse(
                line.substring(key.length + 1).trim().split(' ').first);
            return kb == null ? null : kb * 1024;
          }
        }
        return null;
      }

      final total = read('MemTotal');
      final available = read('MemAvailable') ?? read('MemFree');
      if (total == null || available == null) return <String, dynamic>{};
      return {'total': total, 'available': available};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// CPU model name and maximum frequency read from /proc and /sys.
  static Future<Map<String, String>> cpuDetails() async {
    final result = <String, String>{};
    try {
      final lines = await File('/proc/cpuinfo').readAsLines();
      for (final line in lines) {
        final parts = line.split(':');
        if (parts.length < 2) continue;
        final key = parts.first.trim().toLowerCase();
        final value = parts.sublist(1).join(':').trim();
        if (value.isEmpty) continue;
        if ((key == 'hardware' || key == 'model name') &&
            !result.containsKey('model')) {
          result['model'] = value;
        }
      }
    } catch (_) {
      // Not readable on this device.
    }
    try {
      final text = await File(
              '/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq')
          .readAsString();
      final khz = int.tryParse(text.trim());
      if (khz != null) {
        result['maxFreq'] = '${(khz / 1000000).toStringAsFixed(2)} GHz';
      }
    } catch (_) {
      // Not readable on this device.
    }
    return result;
  }
}
