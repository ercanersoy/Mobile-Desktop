// strings.dart - Turkish and English texts of the Mobile Desktop app
//
// Copyright (c) 2025 Ercan Ersoy.
//
// This file is part of the Mobile Desktop app.

const List<String> kSupportedLanguages = ['tr', 'en'];

String languageName(String code) {
  switch (code) {
    case 'tr':
      return 'Türkçe';
    case 'en':
      return 'English';
    default:
      return code;
  }
}

/// Returns the text for [key] in [language]. Falls back to English and
/// then to the key itself.
String translate(String language, String key) {
  return _strings[language]?[key] ?? _strings['en']![key] ?? key;
}

String monthName(String language, int month) {
  final names = language == 'tr' ? _monthsTr : _monthsEn;
  return names[(month - 1) % 12];
}

/// [weekday] is 1 for Monday ... 7 for Sunday (like [DateTime.weekday]).
String weekdayName(String language, int weekday, {bool short = false}) {
  final List<String> names;
  if (language == 'tr') {
    names = short ? _weekdaysShortTr : _weekdaysTr;
  } else {
    names = short ? _weekdaysShortEn : _weekdaysEn;
  }
  return names[(weekday - 1) % 7];
}

const List<String> _weekdaysShortTr = [
  'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz',
];

const List<String> _weekdaysShortEn = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

const List<String> _monthsTr = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

const List<String> _monthsEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> _weekdaysTr = [
  'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar',
];

const List<String> _weekdaysEn = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
  'Sunday',
];

const Map<String, Map<String, String>> _strings = {
  'tr': {
    // Desktop
    'start': 'Başlat',
    'minimize': 'Simge durumuna küçült',
    'maximize': 'Ekranı kapla',
    'restore': 'Önceki boyut',
    'close': 'Kapat',
    'exit_app': 'Uygulamadan çık',
    'exit_confirm': 'Mobile Desktop kapatılsın mı? Kaydedilmemiş veriler kaybolabilir.',
    'show_desktop': 'Masaüstünü göster',
    'change_wallpaper': 'Duvar kağıdını değiştir',
    'ok': 'Tamam',
    'cancel': 'İptal',

    // App names
    'app_files': 'Dosya Yöneticisi',
    'app_notepad': 'Not Defteri',
    'app_calculator': 'Hesap Makinesi',
    'app_sysinfo': 'Sistem Bilgisi',
    'app_paint': 'Paint',
    'app_terminal': 'Komut İstemi',
    'app_clock': 'Saat',
    'app_calendar': 'Takvim',
    'app_taskmgr': 'Görev Yöneticisi',
    'app_imageviewer': 'Resim Görüntüleyici',
    'app_settings': 'Ayarlar',
    'app_about': 'Hakkında',

    // Common
    'open': 'Aç',
    'save': 'Kaydet',
    'save_as': 'Farklı kaydet',
    'dont_save': 'Kaydetme',
    'new': 'Yeni',
    'copy': 'Kopyala',
    'cut': 'Kes',
    'paste': 'Yapıştır',
    'delete': 'Sil',
    'rename': 'Yeniden adlandır',
    'refresh': 'Yenile',
    'back': 'Geri',
    'up': 'Üst klasör',
    'next': 'Sonraki',
    'previous': 'Önceki',
    'more': 'Diğer',
    'select': 'Seç',
    'select_all': 'Tümünü seç',
    'clear_selection': 'Seçimi kaldır',
    'properties': 'Özellikler',
    'saved': 'Kaydedildi.',
    'saved_to': 'Kaydedildi: {path}',
    'copied': 'Panoya kopyalandı.',
    'file_read_error': 'Dosya okunamadı.',
    'file_write_error': 'Dosya kaydedilemedi.',
    'operation_failed': 'İşlem tamamlanamadı.',
    'invalid_name': 'Geçersiz ad.',
    'already_exists': 'Bu adda bir öğe zaten var.',
    'version': 'Sürüm',
    'stop': 'Durdur',
    'reset': 'Sıfırla',
    'clear': 'Temizle',
    'undo': 'Geri al',
    'redo': 'Yinele',
    'today': 'Bugün',

    // File manager and dialogs
    'locations': 'Konumlar',
    'loc_internal': 'Dahili depolama',
    'loc_downloads': 'İndirilenler',
    'loc_documents': 'Belgeler',
    'loc_pictures': 'Resimler',
    'loc_dcim': 'Kamera (DCIM)',
    'loc_music': 'Müzik',
    'loc_external': 'Harici depolama',
    'loc_home': 'Ev klasörü',
    'loc_root': 'Kök dizin',
    'loc_app': 'Uygulama klasörü',
    'new_folder': 'Yeni klasör',
    'new_text_file': 'Yeni metin belgesi',
    'file_name': 'Dosya adı',
    'empty_folder': 'Bu klasör boş.',
    'folder_unreadable': 'Bu klasör okunamadı. Depolama izni gerekebilir.',
    'storage_permission_needed': 'Tüm dosyaları görmek için depolama izni gerekli.',
    'grant': 'İzin ver',
    'go_to': 'Konuma git',
    'show_hidden': 'Gizli dosyaları göster',
    'grid_view': 'Simge görünümü',
    'sort_name': 'Ada göre sırala',
    'sort_size': 'Boyuta göre sırala',
    'sort_date': 'Tarihe göre sırala',
    'items': 'öğe',
    'selected_count': '{count} öğe seçili',
    'copy_done': '{count} öğe kopyalanmak üzere alındı.',
    'cut_done': '{count} öğe taşınmak üzere alındı.',
    'delete_confirm_one': '"{name}" kalıcı olarak silinsin mi?',
    'delete_confirm_many': '{count} öğe kalıcı olarak silinsin mi?',
    'open_new_window': 'Yeni pencerede aç',
    'open_with_notepad': 'Not Defteri ile aç',
    'name': 'Ad',
    'location': 'Konum',
    'type': 'Tür',
    'size': 'Boyut',
    'contents': 'İçerik',
    'modified': 'Değiştirilme',
    'permissions': 'İzinler',
    'folder': 'Klasör',
    'file': 'dosyası',

    // Notepad
    'untitled': 'Adsız',
    'menu_file': 'Dosya',
    'menu_edit': 'Düzen',
    'menu_view': 'Görünüm',
    'find': 'Bul',
    'find_next': 'Sonrakini bul',
    'not_found': '"{text}" bulunamadı.',
    'insert_date': 'Saat/Tarih ekle',
    'zoom_in': 'Yakınlaştır',
    'zoom_out': 'Uzaklaştır',
    'monospace': 'Sabit genişlikli yazı tipi',
    'line': 'Satır',
    'column': 'Sütun',
    'lines': 'satır',
    'chars': 'karakter',
    'unsaved_changes': '"{name}" dosyasındaki değişiklikler kaydedilsin mi?',

    // Calculator
    'calc_error': 'Hata',

    // System information
    'copy_report': 'Raporu kopyala',
    'sec_device': 'Cihaz',
    'sec_os': 'İşletim sistemi',
    'sec_cpu': 'İşlemci',
    'sec_memory': 'Bellek (RAM)',
    'sec_storage': 'Depolama',
    'sec_battery': 'Pil',
    'sec_display': 'Ekran',
    'sec_app': 'Uygulama',
    'manufacturer': 'Üretici',
    'model': 'Model',
    'brand': 'Marka',
    'device_code': 'Cihaz kodu',
    'os': 'Sürüm',
    'security_patch': 'Güvenlik yaması',
    'build': 'Yapı numarası',
    'kernel': 'Çekirdek',
    'uptime': 'Açık kalma süresi',
    'language': 'Dil',
    'cpu_model': 'Model',
    'cores': 'Çekirdek sayısı',
    'max_freq': 'En yüksek hız',
    'abis': 'Mimari',
    'total': 'Toplam',
    'available': 'Kullanılabilir',
    'used': 'Kullanılan',
    'free': 'Boş',
    'level': 'Doluluk',
    'status': 'Durum',
    'charging': 'Şarj oluyor',
    'discharging': 'Şarj olmuyor',
    'battery_full': 'Dolu',
    'temperature': 'Sıcaklık',
    'voltage': 'Gerilim',
    'technology': 'Teknoloji',
    'resolution': 'Çözünürlük',
    'logical_size': 'Mantıksal boyut',
    'density': 'Yoğunluk',
    'orientation': 'Yön',
    'portrait': 'Dikey',
    'landscape': 'Yatay',
    'open_windows': 'Açık pencere',
    'days_short': 'g',
    'hours_short': 'sa',
    'minutes_short': 'dk',

    // Paint
    'tool_pen': 'Kalem',
    'tool_line': 'Çizgi',
    'tool_rectangle': 'Dikdörtgen',
    'tool_ellipse': 'Elips',
    'tool_eraser': 'Silgi',
    'fill_shapes': 'Şekilleri doldur',
    'save_png': 'PNG olarak kaydet',
    'clear_confirm': 'Resmin tamamı silinsin mi?',
    'background_toggle': 'Arka planı değiştir (beyaz/siyah)',

    // Image viewer
    'open_image': 'Resim aç',
    'rotate': 'Döndür',
    'fit': 'Sığdır',
    'image_error': 'Resim açılamadı.',

    // Terminal
    'terminal_welcome': 'Mobile Desktop Komut İstemi\n'
        'Yardım için "help" yazın.',
    'terminal_help': 'Yerleşik komutlar:\n'
        '  cd <klasör>  Klasör değiştir\n'
        '  clear, cls   Ekranı temizle\n'
        '  help         Bu yardımı göster\n'
        '  exit         Pencereyi kapat\n'
        'Diğer komutlar sistem kabuğunda çalıştırılır (ls, cat, ps, df...).',
    'terminal_hint': 'Komut yazın',
    'no_such_folder': 'böyle bir klasör yok',
    'exit_code': 'çıkış kodu',
    'previous_command': 'Önceki komut',
    'run': 'Çalıştır',

    // Clock
    'clock': 'Saat',
    'stopwatch': 'Kronometre',
    'timer': 'Zamanlayıcı',
    'lap': 'Tur',
    'start_timer': 'Başlat',
    'pause': 'Duraklat',
    'time_is_up': 'Süre doldu!',

    // Calendar
    'add_note': 'Not ekle',
    'edit_note': 'Notu düzenle',
    'no_notes': 'Bu gün için not yok.\nEklemek için + düğmesine dokunun.',

    // Task manager
    'running_apps': 'Çalışan uygulamalar: {count}',
    'state_minimized': 'Simge durumunda',
    'state_maximized': 'Tam ekran',
    'state_normal': 'Çalışıyor',
    'this_window': 'bu pencere',
    'switch_to': 'Geçiş yap',
    'end_task': 'Görevi sonlandır',

    // Settings
    'appearance': 'Görünüm',
    'dark_theme': 'Koyu tema',
    'wallpaper_color': 'Duvar kağıdı rengi',
    'show_desktop_icons': 'Masaüstü simgelerini göster',
    'open_maximized': 'Pencereleri tam ekran aç',
    'language_and_time': 'Dil ve saat',
    'clock_24h': '24 saat biçimi',
    'show_seconds': 'Görev çubuğunda saniyeyi göster',
    'notepad_settings': 'Not Defteri',
    'font_size': 'Yazı boyutu',

    // About
    'about_description': 'Android için klasik masaüstü arayüzü: pencereler, '
        'görev çubuğu, Başlat menüsü ve yerleşik uygulamalar.',
    'license_mit': 'MIT Lisansı ile lisanslanmıştır.',
    'logo_notice': 'Uygulama logosu, kamu malı olarak yayımlanan Tango '
        'simge setinden alınmıştır.',
    'open_source_licenses': 'Açık kaynak lisansları',
  },
  'en': {
    // Desktop
    'start': 'Start',
    'minimize': 'Minimize',
    'maximize': 'Maximize',
    'restore': 'Restore',
    'close': 'Close',
    'exit_app': 'Exit app',
    'exit_confirm': 'Close Mobile Desktop? Unsaved data may be lost.',
    'show_desktop': 'Show desktop',
    'change_wallpaper': 'Change wallpaper',
    'ok': 'OK',
    'cancel': 'Cancel',

    // App names
    'app_files': 'File Manager',
    'app_notepad': 'Notepad',
    'app_calculator': 'Calculator',
    'app_sysinfo': 'System Information',
    'app_paint': 'Paint',
    'app_terminal': 'Command Prompt',
    'app_clock': 'Clock',
    'app_calendar': 'Calendar',
    'app_taskmgr': 'Task Manager',
    'app_imageviewer': 'Image Viewer',
    'app_settings': 'Settings',
    'app_about': 'About',

    // Common
    'open': 'Open',
    'save': 'Save',
    'save_as': 'Save as',
    'dont_save': "Don't save",
    'new': 'New',
    'copy': 'Copy',
    'cut': 'Cut',
    'paste': 'Paste',
    'delete': 'Delete',
    'rename': 'Rename',
    'refresh': 'Refresh',
    'back': 'Back',
    'up': 'Up one folder',
    'next': 'Next',
    'previous': 'Previous',
    'more': 'More',
    'select': 'Select',
    'select_all': 'Select all',
    'clear_selection': 'Clear selection',
    'properties': 'Properties',
    'saved': 'Saved.',
    'saved_to': 'Saved: {path}',
    'copied': 'Copied to clipboard.',
    'file_read_error': 'Could not read the file.',
    'file_write_error': 'Could not save the file.',
    'operation_failed': 'The operation could not be completed.',
    'invalid_name': 'Invalid name.',
    'already_exists': 'An item with this name already exists.',
    'version': 'Version',
    'stop': 'Stop',
    'reset': 'Reset',
    'clear': 'Clear',
    'undo': 'Undo',
    'redo': 'Redo',
    'today': 'Today',

    // File manager and dialogs
    'locations': 'Locations',
    'loc_internal': 'Internal storage',
    'loc_downloads': 'Downloads',
    'loc_documents': 'Documents',
    'loc_pictures': 'Pictures',
    'loc_dcim': 'Camera (DCIM)',
    'loc_music': 'Music',
    'loc_external': 'External storage',
    'loc_home': 'Home folder',
    'loc_root': 'Root',
    'loc_app': 'App folder',
    'new_folder': 'New folder',
    'new_text_file': 'New text document',
    'file_name': 'File name',
    'empty_folder': 'This folder is empty.',
    'folder_unreadable':
        'This folder could not be read. Storage permission may be needed.',
    'storage_permission_needed': 'Storage permission is needed to see all files.',
    'grant': 'Allow',
    'go_to': 'Go to location',
    'show_hidden': 'Show hidden files',
    'grid_view': 'Icon view',
    'sort_name': 'Sort by name',
    'sort_size': 'Sort by size',
    'sort_date': 'Sort by date',
    'items': 'items',
    'selected_count': '{count} items selected',
    'copy_done': '{count} items ready to copy.',
    'cut_done': '{count} items ready to move.',
    'delete_confirm_one': 'Permanently delete "{name}"?',
    'delete_confirm_many': 'Permanently delete {count} items?',
    'open_new_window': 'Open in new window',
    'open_with_notepad': 'Open with Notepad',
    'name': 'Name',
    'location': 'Location',
    'type': 'Type',
    'size': 'Size',
    'contents': 'Contents',
    'modified': 'Modified',
    'permissions': 'Permissions',
    'folder': 'Folder',
    'file': 'file',

    // Notepad
    'untitled': 'Untitled',
    'menu_file': 'File',
    'menu_edit': 'Edit',
    'menu_view': 'View',
    'find': 'Find',
    'find_next': 'Find next',
    'not_found': 'Cannot find "{text}".',
    'insert_date': 'Time/Date',
    'zoom_in': 'Zoom in',
    'zoom_out': 'Zoom out',
    'monospace': 'Monospace font',
    'line': 'Ln',
    'column': 'Col',
    'lines': 'lines',
    'chars': 'characters',
    'unsaved_changes': 'Do you want to save changes to "{name}"?',

    // Calculator
    'calc_error': 'Error',

    // System information
    'copy_report': 'Copy report',
    'sec_device': 'Device',
    'sec_os': 'Operating system',
    'sec_cpu': 'Processor',
    'sec_memory': 'Memory (RAM)',
    'sec_storage': 'Storage',
    'sec_battery': 'Battery',
    'sec_display': 'Display',
    'sec_app': 'App',
    'manufacturer': 'Manufacturer',
    'model': 'Model',
    'brand': 'Brand',
    'device_code': 'Device code',
    'os': 'Version',
    'security_patch': 'Security patch',
    'build': 'Build number',
    'kernel': 'Kernel',
    'uptime': 'Uptime',
    'language': 'Language',
    'cpu_model': 'Model',
    'cores': 'Cores',
    'max_freq': 'Max speed',
    'abis': 'Architecture',
    'total': 'Total',
    'available': 'Available',
    'used': 'Used',
    'free': 'Free',
    'level': 'Level',
    'status': 'Status',
    'charging': 'Charging',
    'discharging': 'Not charging',
    'battery_full': 'Full',
    'temperature': 'Temperature',
    'voltage': 'Voltage',
    'technology': 'Technology',
    'resolution': 'Resolution',
    'logical_size': 'Logical size',
    'density': 'Density',
    'orientation': 'Orientation',
    'portrait': 'Portrait',
    'landscape': 'Landscape',
    'open_windows': 'Open windows',
    'days_short': 'd',
    'hours_short': 'h',
    'minutes_short': 'min',

    // Paint
    'tool_pen': 'Pen',
    'tool_line': 'Line',
    'tool_rectangle': 'Rectangle',
    'tool_ellipse': 'Ellipse',
    'tool_eraser': 'Eraser',
    'fill_shapes': 'Fill shapes',
    'save_png': 'Save as PNG',
    'clear_confirm': 'Erase the whole picture?',
    'background_toggle': 'Toggle background (white/black)',

    // Image viewer
    'open_image': 'Open image',
    'rotate': 'Rotate',
    'fit': 'Fit',
    'image_error': 'Could not open the image.',

    // Terminal
    'terminal_welcome': 'Mobile Desktop Command Prompt\n'
        'Type "help" for help.',
    'terminal_help': 'Built-in commands:\n'
        '  cd <folder>  Change folder\n'
        '  clear, cls   Clear the screen\n'
        '  help         Show this help\n'
        '  exit         Close the window\n'
        'Other commands run in the system shell (ls, cat, ps, df...).',
    'terminal_hint': 'Type a command',
    'no_such_folder': 'no such folder',
    'exit_code': 'exit code',
    'previous_command': 'Previous command',
    'run': 'Run',

    // Clock
    'clock': 'Clock',
    'stopwatch': 'Stopwatch',
    'timer': 'Timer',
    'lap': 'Lap',
    'start_timer': 'Start',
    'pause': 'Pause',
    'time_is_up': "Time's up!",

    // Calendar
    'add_note': 'Add note',
    'edit_note': 'Edit note',
    'no_notes': 'No notes for this day.\nTap + to add one.',

    // Task manager
    'running_apps': 'Running apps: {count}',
    'state_minimized': 'Minimized',
    'state_maximized': 'Maximized',
    'state_normal': 'Running',
    'this_window': 'this window',
    'switch_to': 'Switch to',
    'end_task': 'End task',

    // Settings
    'appearance': 'Appearance',
    'dark_theme': 'Dark theme',
    'wallpaper_color': 'Wallpaper color',
    'show_desktop_icons': 'Show desktop icons',
    'open_maximized': 'Open windows maximized',
    'language_and_time': 'Language and time',
    'clock_24h': '24-hour clock',
    'show_seconds': 'Show seconds on the taskbar',
    'notepad_settings': 'Notepad',
    'font_size': 'Font size',

    // About
    'about_description': 'A classic desktop interface for Android: windows, '
        'a taskbar, a start menu and built-in apps.',
    'license_mit': 'Licensed under the MIT License.',
    'logo_notice': 'The app logo is borrowed from the Tango Icon Set, '
        'published as Public Domain.',
    'open_source_licenses': 'Open source licenses',
  },
};
