import 'package:flutter/foundation.dart';

import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];

  List<Task> get tasks => List.unmodifiable(_tasks);

  Task? _taskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  void addTask(String title, {TaskPriority priority = TaskPriority.medium}) {
    if (title.trim().isEmpty) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _tasks.add(Task(id: id, title: title.trim(), priority: priority));
    notifyListeners();
  }

  void setPriority(String id, TaskPriority priority) {
    final task = _taskById(id);
    if (task != null) {
      task.priority = priority;
      notifyListeners();
    }
  }

  void editTask(String id, String newTitle) {
    final task = _taskById(id);
    if (task != null && newTitle.trim().isNotEmpty) {
      task.title = newTitle.trim();
      notifyListeners();
    }
  }

  void toggleDone(String id) {
    final task = _taskById(id);
    if (task != null) {
      task.isDone = !task.isDone;
      notifyListeners();
    }
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