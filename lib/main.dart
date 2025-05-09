// main.dart - Main of the Mobile Desktop app
//
// Copyright (c) 2025 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Used ChatGPT GPT-4o, GitHub Copilot GPT-4o, GitHub Copilot GPT-4.1 and GitHub Copilot Claude 3.7 Sonnet for writting this program.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      _initialized = true;
    });
  }

  void _updateTheme(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      title: 'Mobile Desktop',
      theme: _isDarkMode
          ? ThemeData(
              brightness: Brightness.dark,
              primaryColor: Colors.blue,
              colorScheme: ColorScheme.dark(
                primary: Colors.blue,
                secondary: Colors.blueAccent,
                surface: Colors.grey.shade900,
                background: Color(0xFF22272A),
                error: Colors.red,
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: Colors.white,
                onBackground: Colors.white,
                onError: Colors.white,
                brightness: Brightness.dark,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStateProperty.all(Colors.blue),
                trackColor: MaterialStateProperty.all(Colors.blue.shade200),
              ),
            )
          : ThemeData(
              primarySwatch: Colors.blue,
              colorScheme: ColorScheme.light(
                primary: Colors.blue,
                secondary: Colors.blueAccent,
                surface: Colors.white,
                background: Color(0xFF00CED1),
                error: Colors.red,
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: Colors.black,
                onBackground: Colors.black,
                onError: Colors.white,
                brightness: Brightness.light,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStateProperty.all(Colors.blue),
                trackColor: MaterialStateProperty.all(Colors.blue.shade200),
              ),
            ),
      home: MyHomePage(onThemeChanged: _updateTheme, isDarkMode: _isDarkMode),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final void Function(bool)? onThemeChanged;
  final bool isDarkMode;
  const MyHomePage({super.key, this.onThemeChanged, this.isDarkMode = true});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;
    final Color taskbarColor = isDark ? Colors.grey.shade900 : Colors.grey.shade300;
    final Color taskbarBorderLight = isDark ? Colors.grey.shade700 : Colors.white;
    final Color taskbarBorderDark = isDark ? Colors.black : Colors.grey.shade700;
    final Color startButtonColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final Color startButtonTextColor = isDark ? Colors.white : Colors.black;
    final Color startMenuColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final Color startMenuBorder = isDark ? Colors.grey.shade700 : Colors.grey.shade700;
    final Color startMenuShadow = isDark ? Colors.black87 : Colors.black45;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: isDark ? Color(0xFF22272A) : Color(0xFF00CED1), // Koyu tema için farklı arka plan
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: taskbarColor,
              height: 28,
              child: Row(
                children: [
                  SizedBox(width: 2),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: taskbarBorderLight, width: 2),
                        left: BorderSide(color: taskbarBorderLight, width: 2),
                        bottom: BorderSide(color: taskbarBorderDark, width: 2),
                        right: BorderSide(color: taskbarBorderDark, width: 2),
                      ),
                      color: taskbarColor,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.transparent,
                          builder: (BuildContext context) {
                            return Align(
                              alignment: Alignment.bottomLeft,
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  width: 220,
                                  margin: const EdgeInsets.only(bottom: 28, left: 2),
                                  decoration: BoxDecoration(
                                    color: startMenuColor,
                                    border: Border.all(color: startMenuBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: startMenuShadow,
                                        blurRadius: 5,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListView(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    children: [
                                      ListTile(
                                        leading: Icon(Icons.folder, color: startButtonTextColor),
                                        title: Text('Files', style: TextStyle(color: startButtonTextColor)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => FileManagerPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.settings, color: startButtonTextColor),
                                        title: Text('Settings', style: TextStyle(color: startButtonTextColor)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SettingsPage(
                                                isDarkMode: widget.isDarkMode,
                                                onThemeChanged: widget.onThemeChanged,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Divider(color: isDark ? Colors.grey.shade600 : null),
                                      ListTile(
                                        leading: Icon(Icons.info, color: startButtonTextColor),
                                        title: Text('About', style: TextStyle(color: startButtonTextColor)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const LicensePage()),
                                          );
                                        },
                                      ),
                                      Divider(color: isDark ? Colors.grey.shade600 : null),
                                      ListTile(
                                        leading: Icon(Icons.exit_to_app, color: startButtonTextColor),
                                        title: Text('Close App', style: TextStyle(color: startButtonTextColor)),
                                        onTap: () {
                                          exit(0);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: startButtonColor,
                          border: Border(
                            top: BorderSide(color: taskbarBorderLight, width: 2),
                            left: BorderSide(color: taskbarBorderLight, width: 2),
                            right: BorderSide(color: taskbarBorderDark, width: 2),
                            bottom: BorderSide(color: taskbarBorderDark, width: 2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black26 : Colors.black12,
                              offset: Offset(1, 1),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu,
                                size: 18,
                                color: startButtonTextColor,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Başlat',
                                style: TextStyle(
                                  color: startButtonTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LicensePage extends StatelessWidget {
  const LicensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Licenses'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AboutDialog(
          applicationName: 'Mobile Desktop',
          applicationVersion: '0.1.0',
          applicationLegalese: '© 2025 Ercan Ersoy',
          children: [
            const SizedBox(height: 16),
            const Text(
              'This application is licensed under MIT License.',
            ),
            const SizedBox(height: 8),
            const Text(
              'The logo of this app borrowed from Tango Icon Set, published as Public Domain.',
            ),
            const SizedBox(height: 8),
            const Text(
              'The other licenses can be found "Licenses" page.',
            )
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final void Function(bool)? onThemeChanged;
  const SettingsPage({super.key, this.isDarkMode = true, this.onThemeChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.palette),
            title: Text('Tema'),
            subtitle: Text(_isDarkMode ? 'Koyu' : 'Açık'),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                widget.onThemeChanged?.call(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FileManagerPage extends StatefulWidget {
  final String? initialPath;
  const FileManagerPage({super.key, this.initialPath});

  @override
  State<FileManagerPage> createState() => _FileManagerPageState();
}

class _FileManagerPageState extends State<FileManagerPage> {
  late String currentPath;
  List<FileSystemEntity> files = [];
  bool loading = true;
  String? error;
  bool permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initPathAndPermission();
  }

  Future<void> _initPathAndPermission() async {
    String? startPath = widget.initialPath;
    if (startPath == null) {
      if (Platform.isAndroid) {
        final dir = await getExternalStorageDirectory();
        startPath = dir?.path ?? '/storage/emulated/0';
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        startPath = dir.path;
      } else {
        startPath = '/';
      }
    }
    currentPath = startPath;
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    PermissionStatus status;
    // Sadece bir izin isteği yapılacak şekilde güncellendi
    if (await Permission.manageExternalStorage.status.isGranted) {
      status = await Permission.manageExternalStorage.status;
    } else if (await Permission.manageExternalStorage.status.isDenied || await Permission.manageExternalStorage.status.isRestricted) {
      status = await Permission.manageExternalStorage.request();
    } else {
      status = await Permission.storage.request();
    }
    if (status.isGranted) {
      setState(() {
        permissionGranted = true;
      });
      _listFiles();
    } else {
      setState(() {
        permissionGranted = false;
        loading = false;
        error = 'Depolama izni verilmedi.';
      });
    }
  }

  Future<void> _listFiles() async {
    if (!permissionGranted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final dir = Directory(currentPath);
      final exists = await dir.exists();
      if (!exists) throw Exception('Klasör bulunamadı: $currentPath');
      final children = dir.listSync();
      children.sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return a.path.compareTo(b.path);
      });
      setState(() {
        files = children;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Klasör listelenemedi: $currentPath';
        loading = false;
      });
    }
  }

  void _navigateTo(String path) {
    setState(() {
      currentPath = path;
    });
    _listFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dosya Yöneticisi'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : !permissionGranted
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Depolama izni gerekli.'),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _requestPermission,
                        child: Text('İzin iste'),
                      ),
                    ],
                  ),
                )
              : error != null
                  ? Center(child: Text('Hata: $error'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            currentPath,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: files.length,
                            itemBuilder: (context, index) {
                              final entity = files[index];
                              final isDir = entity is Directory;
                              final name = entity.path.split('/').last;
                              return ListTile(
                                leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
                                title: Text(name),
                                onTap: isDir
                                    ? () => _navigateTo(entity.path)
                                    : null,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
