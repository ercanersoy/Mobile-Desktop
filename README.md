# Mobile Desktop

A mobile desktop interface app.

Copyright (c) 2025-2026 Ercan Ersoy

This project is licensed under the MIT License.

## Features

Mobile Desktop gives Android a classic desktop: a wallpaper with app icons,
a taskbar with a start menu, and windows that can be moved, resized,
minimized and maximized.

  * **Window manager:** Drag a window by its title bar, resize it from the
    bottom-right corner, double-tap the title bar to maximize it. The taskbar
    shows every open window; tap to switch or minimize, long-press for more
    options. The Android back button closes the front window.
  * **File Manager:** Browse internal storage and memory cards, create
    folders and text files, copy, cut, paste, rename and delete (also for
    several items at once), see file properties, show hidden files, sort by
    name, size or date, and switch between list and icon views. Text files
    open in Notepad and pictures open in Image Viewer.
  * **Notepad:** Open, edit and save text files, find text, insert the date,
    change the font size, see the cursor line and column. It asks before
    closing a document with unsaved changes.
  * **Calculator:** Operator precedence, parentheses, percent, square root,
    powers, memory keys and keyboard support.
  * **System Information:** Device model, Android version, processor, RAM,
    storage, battery, display and uptime, with a button to copy everything as
    a report.
  * **Paint:** Pen, line, rectangle, ellipse and eraser tools, colors, brush
    sizes, undo/redo, and saving as PNG to `Pictures/MobileDesktop`.
  * **Command Prompt:** Runs shell commands (`ls`, `cat`, `ps`, `df`, ...)
    with `cd`, `clear`, `help` and `exit` built in.
  * **Clock:** Analog and digital clock, stopwatch with laps, and a timer.
  * **Calendar:** Month view with notes for each day.
  * **Task Manager:** Lists open windows, switches to them or ends them, and
    shows memory usage.
  * **Image Viewer:** Zoom, rotate, and browse the pictures in a folder.
  * **Settings:** Dark or light theme, wallpaper color, Turkish or English
    language, 12/24-hour clock, desktop icons, and more.

## Building

    flutter pub get
    flutter run

Run the tests with `flutter test`.

## Notes

  * The logo of this app is borrowed from the Tango Icon Set, released into
    the public domain.
  * The other licenses can be found in the "About" page in this app. Click
    the "About" button in the start menu to display this page.
  * Storage access on Android 11 and newer needs the "All files access"
    permission. Without it, the File Manager still works in the app's own
    folder.
  * This README.md was mostly written with Claude Code Opus 5.5.
