// main.dart - Main of the Mobile Desktop app.
//
// Copyright (c) 2025 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.
//
// Used ChatGPT GPT-4o and GitHub Copilot GPT-4o for writting this program.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Desktop',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.lightBlueAccent,
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              children: [
                SizedBox(
                  width: 70,
                  child: Column(
                    children: [
                      Icon(Icons.folder, size: 32),
                      Text(
                        'Files',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 100,
            left: 20,
            child: Column(
              children: [
                SizedBox(
                  width: 70,
                  child: Column(
                    children: [
                      Icon(Icons.folder, size: 32),
                      Text(
                        'Settings',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.grey.shade300,
              height: 28,
              child: Row(
                children: [
                  SizedBox(width: 2),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 2),
                        left: BorderSide(color: Colors.white, width: 2),
                        bottom: BorderSide(color: Colors.grey.shade700, width: 2),
                        right: BorderSide(color: Colors.grey.shade700, width: 2),
                      ),
                      color: Colors.grey.shade300,
                    ),
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'about') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LicensePage()),
                          );
                        }
                        else if (value == 'close') {
                            Navigator.of(context).pop();
                            Future.delayed(Duration(milliseconds: 100), () {
                            SystemNavigator.pop();
                            });
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'files',
                          child: Text('Files'),
                        ),
                        PopupMenuItem(
                          value: 'settings',
                          child: Text('Settings'),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'about',
                          child: Text('About'),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'close',
                          child: Text('Close the App'),
                        ),
                      ],
                      child: TextButton(
                        onPressed: null,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.start, color: Colors.black),
                            SizedBox(width: 4),
                            Text(
                              'Start',
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
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
