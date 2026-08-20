import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:task_manager/models/task.dart';
import 'package:task_manager/providers/task_provider.dart';
import 'package:task_manager/services/task_store.dart';

void main() {
  test('Tasks are persisted across provider instances', () {
    final fileName =
        'test_tasks_${DateTime.now().microsecondsSinceEpoch}.json';
    final store = TaskStore(fileName: fileName);

    final provider = TaskProvider(store: store);
    provider.addTask('Persist me', category: TaskCategory.work);
    provider.setPriority(provider.tasks.first.id, TaskPriority.high);
    provider.toggleDone(provider.tasks.first.id);

    final reloaded = TaskProvider(store: store);
    expect(reloaded.tasks.length, 1);
    expect(reloaded.tasks.first.title, 'Persist me');
    expect(reloaded.tasks.first.category, TaskCategory.work);
    expect(reloaded.tasks.first.priority, TaskPriority.high);
    expect(reloaded.tasks.first.isDone, isTrue);

    final file = File(
      '${Platform.environment['HOME']}${Platform.pathSeparator}'
      'Todorist${Platform.pathSeparator}$fileName',
    );
    if (file.existsSync()) file.deleteSync();
  });
}