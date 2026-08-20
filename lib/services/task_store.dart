import 'dart:convert';
import 'dart:io';

import '../models/task.dart';

class TaskStore {
  TaskStore({String? fileName}) {
    try {
      _file = TaskStore._defaultFile(fileName);
    } catch (e) {
      // dart:io is unsupported on web; fall back to in-memory storage.
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
    return File('$base$sep${fileName ?? 'tasks.json'}');
  }

  static String get appStoreName => 'Todorist';

  List<Task> loadSync() {
    final file = _file;
    if (file == null) return <Task>[];
    try {
      if (!file.existsSync()) return <Task>[];
      final json = file.readAsStringSync();
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
    final file = _file;
    if (file == null) return;
    try {
      final dir = Directory(file.path).parent;
      if (!dir.existsSync()) dir.createSync(recursive: true);
      file.writeAsStringSync(_toJson(tasks));
    } catch (e) {
      // Ignore persistence failures (e.g. web builds without file access).
    }
  }

  void deleteTestFile() {
    final file = _file;
    if (file == null) return;
    try {
      if (file.existsSync()) file.deleteSync();
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