import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/task.dart';

class TaskStore {
  TaskStore._(this._file);

  /// Creates a store in the app's private support directory.
  ///
  /// This is the correct location on all platforms (Android, iOS, macOS,
  /// Windows, Linux). It throws if the platform directory cannot be resolved.
  static Future<TaskStore> create({String? fileName}) async {
    final dir = await getApplicationSupportDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}${fileName ?? 'tasks.json'}',
    );
    return TaskStore._(file);
  }

  /// Creates a store at a fixed, local path — only intended for tests.
  static TaskStore forTest(String fileName) {
    final home = Platform.environment['HOME'] ?? Directory.current.path;
    final sep = Platform.pathSeparator;
    final base = Platform.operatingSystem == 'macos'
        ? '$home${sep}Library${sep}Application Support${sep}Todorist'
        : '$home${sep}Todorist';
    return TaskStore._(File('$base$sep$fileName'));
  }

  final File _file;

  List<Task> loadSync() {
    try {
      if (!_file.existsSync()) return <Task>[];
      final json = _file.readAsStringSync();
      if (json.isEmpty) return <Task>[];
      final decoded = jsonDecode(json) as List<dynamic>;
      return [
        for (final entry in decoded)
          if (entry is Map)
            _fromJson(entry as Map<String, dynamic>),
      ];
    } catch (e) {
      return <Task>[];
    }
  }

  void saveSync(List<Task> tasks) {
    try {
      final dir = Directory(_file.path).parent;
      if (!dir.existsSync()) dir.createSync(recursive: true);
      _file.writeAsStringSync(_toJson(tasks));
    } catch (e) {
      // Ignore persistence failures (e.g. web builds without file access).
    }
  }

  void deleteTestFile() {
    try {
      if (_file.existsSync()) _file.deleteSync();
    } catch (e) {
      // Ignore cleanup failures.
    }
  }

  String _toJson(List<Task> tasks) => jsonEncode([
    for (final task in tasks) _toMap(task),
  ]);

  static Map<String, dynamic> _toMap(Task task) => {
    'id': task.id,
    'title': task.title,
    'isDone': task.isDone,
    'priority': task.priority.name,
    'category': task.category.name,
  };

  static Task _fromJson(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      isDone: map['isDone'] as bool,
      priority: _priorityByName(map['priority'] as String),
      category: _categoryByName(map['category'] as String),
    );
  }

  static TaskPriority _priorityByName(String name) {
    for (final priority in TaskPriority.values) {
      if (priority.name == name) return priority;
    }
    return TaskPriority.medium;
  }

  static TaskCategory _categoryByName(String name) {
    for (final category in TaskCategory.values) {
      if (category.name == name) return category;
    }
    return TaskCategory.shopping;
  }
}