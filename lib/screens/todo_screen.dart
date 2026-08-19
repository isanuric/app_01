import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/time_service.dart';

String _pad2(int n) => n.toString().padLeft(2, '0');

String _formatDate(DateTime dt) =>
    '${_pad2(dt.day)}.${_pad2(dt.month)}.${dt.year}';

String _formatTime(DateTime dt) => '${_pad2(dt.hour)}:${_pad2(dt.minute)}';

Color _priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.low => Colors.green,
  TaskPriority.medium => Colors.orange,
  TaskPriority.high => Colors.red,
};

(Color, IconData) _categoryStyle(TaskCategory category) => switch (category) {
  TaskCategory.work => (Colors.blue, Icons.work_outline),
  TaskCategory.personal => (Colors.purple, Icons.person_outline),
  TaskCategory.shopping => (Colors.teal, Icons.shopping_cart_outlined),
  TaskCategory.other => (Colors.grey, Icons.category_outlined),
};

final _doneTaskBorderColor = Colors.grey.withAlpha(100);
final _deleteIconColor = Colors.red.withAlpha(150);

class _ClockTitle extends StatefulWidget {
  const _ClockTitle();

  @override
  State<_ClockTitle> createState() => _ClockTitleState();
}

class _ClockTitleState extends State<_ClockTitle> {
  final _timeService = const TimeService();
  late Future<DateTime> _dateTimeFuture;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _dateTimeFuture = _timeService.fetchDateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {
        _dateTimeFuture = _timeService.fetchDateTime();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DateTime>(
      future: _dateTimeFuture,
      builder: (context, snapshot) {
        final dateTime = snapshot.data;
        final dateStr = dateTime == null
            ? 'Loading date...'
            : _formatDate(dateTime);
        final timeStr = dateTime == null ? '' : _formatTime(dateTime);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('My Tasks'),
            Text(
              '$dateStr $timeStr',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        );
      },
    );
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _textEditingController = TextEditingController();
  final _editController = TextEditingController();
  String? _editingTaskId;
  TaskCategory _newCategory = TaskCategory.other;
  final _borderRadius = BorderRadius.circular(12);

  @override
  void dispose() {
    _textEditingController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<TaskProvider>().addTask(
      _textEditingController.text,
      category: _newCategory,
    );
    _textEditingController.clear();
  }

  void _startEditing(String id, String title) {
    setState(() {
      _editingTaskId = id;
      _editController.text = title;
    });
  }

  void _finishEditing(String id) {
    final title = _editController.text.trim();
    if (_editingTaskId != id) return;
    if (title.isNotEmpty) {
      context.read<TaskProvider>().editTask(id, title);
    }
    setState(() {
      _editingTaskId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.tasks;
    final visibleTasks = taskProvider.filteredTasks;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final hintTextColor = colors.onSurface.withAlpha(100);
    final emptyStateIconColor = colors.primary.withAlpha(100);
    final shadowColor = colors.primary.withAlpha(100);

    return Scaffold(
      appBar: AppBar(title: const _ClockTitle(), centerTitle: true),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primary.withAlpha(10), colors.primary.withAlpha(5)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textEditingController,
                      style: TextStyle(color: colors.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Add new task',
                        hintStyle: TextStyle(color: hintTextColor),
                        border: OutlineInputBorder(borderRadius: _borderRadius),
                        filled: true,
                        fillColor: colors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  PopupMenuButton<TaskCategory>(
                    onSelected: (category) =>
                        setState(() => _newCategory = category),
                    itemBuilder: (context) => [
                      for (final category in TaskCategory.values)
                        PopupMenuItem(
                          value: category,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _categoryStyle(category).$2,
                                size: 18,
                                color: _categoryStyle(category).$1,
                              ),
                              const SizedBox(width: 8),
                              Text(category.name),
                            ],
                          ),
                        ),
                    ],
                    icon: Icon(
                      _categoryStyle(_newCategory).$2,
                      color: _categoryStyle(_newCategory).$1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton.filled(
                      onPressed: _submit,
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.surface.withAlpha(120),
                borderRadius: _borderRadius,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Checkbox(
                      value: taskProvider.allDone,
                      onChanged: tasks.isEmpty
                          ? null
                          : (value) => context.read<TaskProvider>().setAllDone(
                              value ?? false,
                            ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Select All'),
                  const Spacer(),
                  const Text('Delete All'),
                  IconButton(
                    onPressed: tasks.isEmpty
                        ? null
                        : () => context.read<TaskProvider>().deleteAll(),
                    icon: Icon(
                      Icons.delete_sweep_outlined,
                      color: _deleteIconColor,
                    ),
                    tooltip: 'Delete all',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            if (taskProvider.totalCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${taskProvider.doneCount}/${taskProvider.totalCount} done',
                          style: textTheme.labelMedium,
                        ),
                        const Spacer(),
                        Text(
                          '${(taskProvider.doneCount / taskProvider.totalCount * 100).round()}%',
                          style: textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: taskProvider.totalCount == 0
                          ? 0
                          : taskProvider.doneCount / taskProvider.totalCount,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RotatedBox(
                          quarterTurns: 3,
                          child: FilterChip(
                            label: const Text('All'),
                            selected: taskProvider.activeFilter == null,
                            onSelected: (_) =>
                                context.read<TaskProvider>().setFilter(null),
                          ),
                        ),
                        for (final category in [
                          TaskCategory.personal,
                          TaskCategory.shopping,
                          TaskCategory.work,
                          TaskCategory.other,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 64,
                                ),
                                child: FilterChip(
                                  avatar: Icon(
                                    _categoryStyle(category).$2,
                                    size: 16,
                                    color: _categoryStyle(category).$1,
                                  ),
                                  label: Text(category.name),
                                  selected:
                                      taskProvider.activeFilter == category,
                                  onSelected: (_) => context
                                      .read<TaskProvider>()
                                      .setFilter(category),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: visibleTasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: emptyStateIconColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  tasks.isEmpty
                                      ? 'No tasks yet.'
                                      : 'No tasks in this category.',
                                  style: textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add a new task to get started',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            buildDefaultDragHandles: false,
                            itemCount: visibleTasks.length,
                            onReorderItem: context
                                .read<TaskProvider>()
                                .reorderTask,
                            itemBuilder: (context, index) {
                              final task = visibleTasks[index];
                              return Padding(
                                key: ValueKey(task.id),
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Dismissible(
                                  key: ValueKey(task.id),
                                  direction: DismissDirection.horizontal,
                                  onDismissed: (_) {
                                    if (_editingTaskId == task.id) {
                                      _editingTaskId = null;
                                    }
                                    context.read<TaskProvider>().deleteTask(
                                      task.id,
                                    );
                                  },
                                  confirmDismiss: (direction) async {
                                    if (direction ==
                                        DismissDirection.startToEnd) {
                                      context.read<TaskProvider>().toggleDone(
                                        task.id,
                                      );
                                      return false;
                                    }
                                    return true;
                                  },
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: _borderRadius,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 20),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                  ),
                                  secondaryBackground: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: _borderRadius,
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: _borderRadius,
                                      side: task.isDone
                                          ? BorderSide(
                                              color: _doneTaskBorderColor,
                                            )
                                          : BorderSide.none,
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                      leading: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: _priorityColor(
                                                task.priority,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Checkbox(
                                            value: task.isDone,
                                            onChanged: (_) => context
                                                .read<TaskProvider>()
                                                .toggleDone(task.id),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ],
                                      ),
                                      title: _editingTaskId == task.id
                                          ? TextField(
                                              controller: _editController,
                                              autofocus: true,
                                              style: textTheme.bodyLarge,
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                border: InputBorder.none,
                                              ),
                                              onSubmitted: (_) =>
                                                  _finishEditing(task.id),
                                              onTapOutside: (_) =>
                                                  _finishEditing(task.id),
                                            )
                                          : GestureDetector(
                                              onTap: task.isDone
                                                  ? null
                                                  : () => _startEditing(
                                                      task.id,
                                                      task.title,
                                                    ),
                                              child: Text(
                                                task.title,
                                                style: textTheme.bodyLarge
                                                    ?.copyWith(
                                                      decoration: task.isDone
                                                          ? TextDecoration
                                                                .lineThrough
                                                          : null,
                                                      color: task.isDone
                                                          ? Colors.grey
                                                          : null,
                                                    ),
                                              ),
                                            ),
                                      subtitle: PopupMenuButton<TaskCategory>(
                                        padding: EdgeInsets.zero,
                                        tooltip: 'Change category',
                                        enabled: !task.isDone,
                                        onSelected: (category) => context
                                            .read<TaskProvider>()
                                            .setCategory(task.id, category),
                                        itemBuilder: (context) => [
                                          for (final category
                                              in TaskCategory.values)
                                            PopupMenuItem(
                                              value: category,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    _categoryStyle(category).$2,
                                                    size: 18,
                                                    color: _categoryStyle(
                                                      category,
                                                    ).$1,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(category.name),
                                                ],
                                              ),
                                            ),
                                        ],
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _categoryStyle(task.category).$2,
                                              size: 14,
                                              color: _categoryStyle(
                                                task.category,
                                              ).$1,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              task.category.name,
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: _categoryStyle(
                                                      task.category,
                                                    ).$1,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          PopupMenuButton<TaskPriority>(
                                            enabled: !task.isDone,
                                            onSelected: (priority) => context
                                                .read<TaskProvider>()
                                                .setPriority(task.id, priority),
                                            itemBuilder: (context) => [
                                              for (final priority
                                                  in TaskPriority.values)
                                                PopupMenuItem(
                                                  value: priority,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 12,
                                                        height: 12,
                                                        decoration:
                                                            BoxDecoration(
                                                              color:
                                                                  _priorityColor(
                                                                    priority,
                                                                  ),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(priority.name),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                            icon: Icon(
                                              Icons.star_outline,
                                              size: 20,
                                              color: _priorityColor(
                                                task.priority,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: Icon(
                                              Icons.drag_handle,
                                              color: colors.onSurface.withAlpha(
                                                120,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
