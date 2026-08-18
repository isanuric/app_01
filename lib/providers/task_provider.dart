import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];

  List<Task> get tasks => UnmodifiableListView(_tasks);

  bool get allDone => _tasks.isNotEmpty && _tasks.every((t) => t.isDone);

  Task? _taskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  void _update(String id, bool Function(Task task) mutate) {
    final task = _taskById(id);
    if (task == null) return;
    if (mutate(task)) notifyListeners();
  }

  void addTask(String title, {TaskPriority priority = TaskPriority.medium}) {
    if (title.trim().isEmpty) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _tasks.add(Task(id: id, title: title.trim(), priority: priority));
    notifyListeners();
  }

  void setPriority(String id, TaskPriority priority) {
    _update(id, (task) {
      if (task.isDone) return false;
      task.priority = priority;
      return true;
    });
  }

  void editTask(String id, String newTitle) {
    final title = newTitle.trim();
    if (title.isEmpty) return;
    _update(id, (task) {
      if (task.isDone) return false;
      task.title = title;
      return true;
    });
  }

  void toggleDone(String id) {
    _update(id, (task) {
      task.isDone = !task.isDone;
      return true;
    });
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }

  void reorderTask(int oldIndex, int newIndex) {
    final task = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, task);
    notifyListeners();
  }

  void setAllDone(bool done) {
    for (final task in _tasks) {
      task.isDone = done;
    }
    notifyListeners();
  }

  void deleteAll() {
    _tasks.clear();
    notifyListeners();
  }
}
