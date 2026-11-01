// storage_access.dart - Storage permission and common folders
//
// Copyright (c) 2025-2026 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Written with Claude Code.

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'native_system.dart';

class StorageAccess {
  StorageAccess._();

  static const String androidRoot = '/storage/emulated/0';

  /// Asks for the right storage permission for the Android version.
  /// Returns true when files outside the app folder can be used.
  static Future<bool> ensurePermission({bool request = true}) async {
    if (!Platform.isAndroid) return true;
    final sdk = await NativeSystem.sdkInt();
    try {
      if (sdk >= 30 || sdk == 0) {
        var status = await Permission.manageExternalStorage.status;
        if (status.isGranted) return true;
        if (request) {
          status = await Permission.manageExternalStorage.request();
          if (status.isGranted) return true;
        }
        if (sdk >= 30) return false;
      }
      var status = await Permission.storage.status;
      if (status.isGranted) return true;
      if (!request) return false;
      status = await Permission.storage.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Folder that always works, even without storage permission.
  static Future<String> appFolder() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Start folder for file dialogs.
  static Future<String> homeFolder() async {
    if (Platform.isAndroid) {
      if (await ensurePermission(request: false) &&
          await Directory(androidRoot).exists()) {
        return androidRoot;
      }
      return appFolder();
    }
    return Platform.environment['HOME'] ?? '/';
  }

  /// Well-known folders shown in the "Locations" menu.
  /// Keys are translation keys, values are paths.
  static Future<List<MapEntry<String, String>>> locations() async {
    final result = <MapEntry<String, String>>[];
    if (Platform.isAndroid) {
      result.add(const MapEntry('loc_internal', androidRoot));
      result.add(const MapEntry('loc_downloads', '$androidRoot/Download'));
      result.add(const MapEntry('loc_documents', '$androidRoot/Documents'));
      result.add(const MapEntry('loc_pictures', '$androidRoot/Pictures'));
      result.add(const MapEntry('loc_dcim', '$androidRoot/DCIM'));
      result.add(const MapEntry('loc_music', '$androidRoot/Music'));
      try {
        // Memory cards and USB drives are mounted under /storage.
        final volumes = Directory('/storage').listSync();
        for (final volume in volumes) {
          final name = volume.path.split('/').last;
          if (volume is Directory && name != 'emulated' && name != 'self') {
            result.add(MapEntry('loc_external:$name', volume.path));
          }
        }
      } catch (_) {
        // /storage is not listable on this device.
      }
    } else {
      final home = Platform.environment['HOME'];
      if (home != null) result.add(MapEntry('loc_home', home));
      result.add(const MapEntry('loc_root', '/'));
    }
    result.add(MapEntry('loc_app', await appFolder()));
    return result;
  }
}
