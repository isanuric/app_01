import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class ThemeStore {
  ThemeStore({String? fileName}) {
    try {
      _file = ThemeStore._defaultFile(fileName);
    } catch (e) {
      _file = null;
    }
  }

  File? _file;

  static File _defaultFile(String? fileName) {
    final home = Platform.environment['HOME'] ?? Directory.current.path;
    final sep = Platform.pathSeparator;
    final base = Platform.operatingSystem == 'macos'
        ? '$home${sep}Library${sep}Application Support${sep}Todorist'
        : '$home${sep}Todorist';
    return File('$base$sep${fileName ?? 'theme.json'}');
  }

  ThemeMode load() {
    final file = _file;
    if (file == null) return ThemeMode.system;
    try {
      if (!file.existsSync()) return ThemeMode.system;
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return ThemeMode.values.firstWhere(
        (mode) => mode.name == data['mode'],
        orElse: () => ThemeMode.system,
      );
    } catch (e) {
      return ThemeMode.system;
    }
  }

  void save(ThemeMode mode) {
    final file = _file;
    if (file == null) return;
    try {
      final dir = Directory(file.path).parent;
      if (!dir.existsSync()) dir.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode({'mode': mode.name}));
    } catch (e) {
      // Ignore persistence failures on unsupported platforms (e.g. web).
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({ThemeStore? store}) : _store = store ?? ThemeStore() {
    _mode = _store.load();
  }

  final ThemeStore _store;
  late ThemeMode _mode;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _store.save(mode);
    notifyListeners();
  }

  void toggle() {
    setMode(switch (_mode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    });
  }
}