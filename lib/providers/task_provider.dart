import 'package:flutter/foundation.dart';

import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  final Map<String, Task> _tasks = {};

  List<Task> get tasks => _tasks.values.toList();

  void addTask(String title, {TaskPriority priority = TaskPriority.medium}) {
    if (title.trim().isEmpty) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _tasks[id] = Task(id: id, title: title.trim(), priority: priority);
    notifyListeners();
  }

  void setPriority(String id, TaskPriority priority) {
    final task = _tasks[id];
    if (task != null) {
      task.priority = priority;
      notifyListeners();
    }
  }

  void toggleDone(String id) {
    final task = _tasks[id];
    if (task != null) {
      task.isDone = !task.isDone;
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _tasks.remove(id);
    notifyListeners();
  }

  void setAllDone(bool done) {
    for (final task in _tasks.values) {
      task.isDone = done;
    }
    notifyListeners();
  }

  void deleteAll() {
    _tasks.clear();
    notifyListeners();
  }
}
