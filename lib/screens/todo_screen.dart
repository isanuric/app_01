import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_constants.dart';
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
            const Text(appName),
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
  final _listController = ScrollController();
  String? _editingTaskId;
  TaskCategory _newCategory = TaskCategory.shopping;
  final _borderRadius = BorderRadius.circular(12);

  @override
  void dispose() {
    _textEditingController.dispose();
    _editController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (!_listController.hasClients) return;
    _listController.animateTo(
      _listController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _submit() {
    context.read<TaskProvider>().addTask(
      _textEditingController.text,
      category: _newCategory,
    );
    _textEditingController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 250), _scrollToEnd);
    });
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
    final newCategoryStyle = _categoryStyle(_newCategory);

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
                      color: colors.error,
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
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: taskProvider.activeFilter == null,
                    onSelected: (_) =>
                        context.read<TaskProvider>().setFilter(null),
                  ),
                  for (final category in [
                    TaskCategory.shopping,
                    TaskCategory.personal,
                    TaskCategory.work,
                    TaskCategory.other,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: taskProvider.activeFilter == category
                                ? _categoryStyle(category).$1
                                : colors.outline,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: taskProvider.activeFilter == category
                              ? _categoryStyle(category).$1.withAlpha(20)
                              : Colors.transparent,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.read<TaskProvider>().setFilter(
                              category,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    _categoryStyle(category).$2,
                                    size: 16,
                                    color: _categoryStyle(category).$1,
                                  ),
                                ],
                              ),
                            ),
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
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      buildDefaultDragHandles: false,
                      scrollController: _listController,
                      itemCount: visibleTasks.length,
                      onReorderItem: context.read<TaskProvider>().reorderTask,
                      itemBuilder: (context, index) {
                        final task = visibleTasks[index];
                        return Padding(
                          key: ValueKey(task.id),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
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
                                    color: colors.error,
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
                                            color: colors.outlineVariant,
                                          )
                                        : BorderSide.none,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: _priorityColor(
                                              task.priority,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        Checkbox(
                                          value: task.isDone,
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          onChanged: (_) => context
                                              .read<TaskProvider>()
                                              .toggleDone(task.id),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _editingTaskId == task.id
                                                  ? TextField(
                                                      controller:
                                                          _editController,
                                                      autofocus: true,
                                                      style:
                                                          textTheme.bodyLarge,
                                                      decoration:
                                                          const InputDecoration(
                                                            isDense: true,
                                                            border: InputBorder
                                                                .none,
                                                          ),
                                                      onSubmitted: (_) =>
                                                          _finishEditing(
                                                            task.id,
                                                          ),
                                                      onTapOutside: (_) =>
                                                          _finishEditing(
                                                            task.id,
                                                          ),
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
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: textTheme
                                                            .bodyLarge
                                                            ?.copyWith(
                                                              decoration:
                                                                  task.isDone
                                                                  ? TextDecoration
                                                                        .lineThrough
                                                                  : null,
                                                              color: task.isDone
                                                                  ? colors
                                                                        .onSurfaceVariant
                                                                  : null,
                                                            ),
                                                      ),
                                                    ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: PopupMenuButton<TaskCategory>(
                                                      padding: EdgeInsets.zero,
                                                      tooltip:
                                                          'Change category',
                                                      enabled: !task.isDone,
                                                      onSelected: (category) =>
                                                          context
                                                              .read<
                                                                TaskProvider
                                                              >()
                                                              .setCategory(
                                                                task.id,
                                                                category,
                                                              ),
                                                      itemBuilder: (context) => [
                                                        for (final category
                                                            in TaskCategory
                                                                .values)
                                                          PopupMenuItem(
                                                            value: category,
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  _categoryStyle(
                                                                    category,
                                                                  ).$2,
                                                                  size: 18,
                                                                  color:
                                                                      _categoryStyle(
                                                                        category,
                                                                      ).$1,
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Text(
                                                                  category.name,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                      ],
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            _categoryStyle(
                                                              task.category,
                                                            ).$2,
                                                            size: 14,
                                                            color:
                                                                _categoryStyle(
                                                                  task.category,
                                                                ).$1,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Flexible(
                                                            child: Text(
                                                              task
                                                                  .category
                                                                  .name,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: textTheme
                                                                  .labelSmall
                                                                  ?.copyWith(
                                                                    color: _categoryStyle(
                                                                      task.category,
                                                                    ).$1,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child: PopupMenuButton<TaskPriority>(
                                                      padding: EdgeInsets.zero,
                                                      enabled: !task.isDone,
                                                      onSelected: (priority) =>
                                                          context
                                                              .read<
                                                                TaskProvider
                                                              >()
                                                              .setPriority(
                                                                task.id,
                                                                priority,
                                                              ),
                                                      itemBuilder: (context) => [
                                                        for (final priority
                                                            in TaskPriority
                                                                .values)
                                                          PopupMenuItem(
                                                            value: priority,
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Container(
                                                                  width: 12,
                                                                  height: 12,
                                                                  decoration: BoxDecoration(
                                                                    color: _priorityColor(
                                                                      priority,
                                                                    ),
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Text(
                                                                  priority.name,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                      ],
                                                      icon: Icon(
                                                        Icons.star_outline,
                                                        size: 16,
                                                        color: _priorityColor(
                                                          task.priority,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 4,
                                              top: 10,
                                            ),
                                            child: Icon(
                                              Icons.drag_handle,
                                              size: 18,
                                              color: colors.onSurface.withAlpha(
                                                120,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
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
                        suffixIcon: IconButton(
                          onPressed: _submit,
                          icon: const Icon(Icons.add, size: 20),
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
                      for (final category in [
                        TaskCategory.other,
                        TaskCategory.work,
                        TaskCategory.personal,
                        TaskCategory.shopping,
                      ])
                        PopupMenuItem(
                          value: category,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _categoryStyle(category).$2,
                                size: 14,
                                color: _categoryStyle(category).$1,
                              ),
                              const SizedBox(width: 8),
                              Text(category.name),
                            ],
                          ),
                        ),
                    ],
                    icon: Icon(
                      newCategoryStyle.$2,
                      size: 22,
                      color: newCategoryStyle.$1,
                    ),
                    padding: const EdgeInsets.all(4),
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
