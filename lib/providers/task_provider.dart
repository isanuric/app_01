import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/task_store.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider({TaskStore? store})
    : _store = store ?? TaskStore() {
    _tasks.addAll(_store.loadSync());
  }

  final List<Task> _tasks = [];
  final TaskStore _store;

  TaskCategory? activeFilter;

  List<Task> get tasks => UnmodifiableListView(_tasks);

  List<Task> get filteredTasks => activeFilter == null
      ? tasks
      : UnmodifiableListView(_tasks.where((t) => t.category == activeFilter));

  bool get allDone => _tasks.isNotEmpty && _tasks.every((t) => t.isDone);

  int get totalCount => _tasks.length;

  int get doneCount => _tasks.where((t) => t.isDone).length;

  Task? _taskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  void _update(String id, bool Function(Task task) mutate) {
    final task = _taskById(id);
    if (task == null) return;
    if (mutate(task)) {
      notifyListeners();
      _persist();
    }
  }

  void _persist() => _store.saveSync(_tasks);

  void addTask(
    String title, {
    TaskPriority priority = TaskPriority.medium,
    TaskCategory category = TaskCategory.shopping,
  }) {
    if (title.trim().isEmpty) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _tasks.add(
      Task(id: id, title: title.trim(), priority: priority, category: category),
    );
    notifyListeners();
    _persist();
  }

  void setPriority(String id, TaskPriority priority) {
    _update(id, (task) {
      if (task.isDone) return false;
      task.priority = priority;
      return true;
    });
  }

  void setCategory(String id, TaskCategory category) {
    _update(id, (task) {
      if (task.isDone) return false;
      task.category = category;
      return true;
    });
  }

  void setFilter(TaskCategory? category) {
    activeFilter = category;
    notifyListeners();
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
    _persist();
  }

  void reorderTask(int oldIndex, int newIndex) {
    final visible = filteredTasks;
    if (oldIndex < 0 ||
        oldIndex >= visible.length ||
        newIndex < 0 ||
        newIndex >= visible.length) {
      return;
    }
    if (activeFilter == null) {
      final task = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, task);
    } else {
      final moved = visible[oldIndex];
      _tasks.remove(moved);
      _tasks.insert(
        _tasks.indexWhere((t) => t.id == visible[newIndex].id),
        moved,
      );
    }
    notifyListeners();
    _persist();
  }

  void setAllDone(bool done) {
    for (final task in _tasks) {
      task.isDone = done;
    }
    notifyListeners();
    _persist();
  }

  void deleteAll() {
    _tasks.clear();
    notifyListeners();
    _persist();
  }
}
