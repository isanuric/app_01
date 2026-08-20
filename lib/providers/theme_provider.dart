import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ThemeStore {
  ThemeStore._(this._file);

  /// Creates a store in the app's private support directory.
  static Future<ThemeStore> create({String? fileName}) async {
    final dir = await getApplicationSupportDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}${fileName ?? 'theme.json'}',
    );
    return ThemeStore._(file);
  }

  /// Creates a store at a fixed, local path — only intended for tests.
  static ThemeStore forTest(String fileName) {
    final home = Platform.environment['HOME'] ?? Directory.current.path;
    final sep = Platform.pathSeparator;
    final base = Platform.operatingSystem == 'macos'
        ? '$home${sep}Library${sep}Application Support${sep}Todorist'
        : '$home${sep}Todorist';
    return ThemeStore._(File('$base$sep$fileName'));
  }

  final File _file;

  ThemeMode load() {
    try {
      if (!_file.existsSync()) return ThemeMode.system;
      final data = jsonDecode(_file.readAsStringSync()) as Map<String, dynamic>;
      return ThemeMode.values.firstWhere(
        (mode) => mode.name == data['mode'],
        orElse: () => ThemeMode.system,
      );
    } catch (e) {
      return ThemeMode.system;
    }
  }

  void save(ThemeMode mode) {
    try {
      final dir = Directory(_file.path).parent;
      if (!dir.existsSync()) dir.createSync(recursive: true);
      _file.writeAsStringSync(jsonEncode({'mode': mode.name}));
    } catch (e) {
      // Ignore persistence failures on unsupported platforms (e.g. web).
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({ThemeStore? store})
    : _store = store ?? ThemeStore.forTest('theme.json') {
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