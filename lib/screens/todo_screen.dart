import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_constants.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/time_service.dart';
import '../widgets/task_card.dart';

String _pad2(int n) => n.toString().padLeft(2, '0');

String _formatDate(DateTime dt) =>
    '${_pad2(dt.day)}.${_pad2(dt.month)}.${dt.year}';

String _formatTime(DateTime dt) => '${_pad2(dt.hour)}:${_pad2(dt.minute)}';

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
  final _listController = ScrollController();
  TaskCategory _newCategory = TaskCategory.shopping;
  final _borderRadius = BorderRadius.circular(12);

  @override
  void dispose() {
    _textEditingController.dispose();
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
    final newCategoryStyle = categoryStyle(_newCategory);

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
                  Semantics(
                    label: 'Select all tasks',
                    child: SizedBox(
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
                    Semantics(
                      label:
                          'Task progress, ${taskProvider.doneCount} of '
                          '${taskProvider.totalCount} completed',
                      child: LinearProgressIndicator(
                        value: taskProvider.totalCount == 0
                            ? 0
                            : taskProvider.doneCount / taskProvider.totalCount,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
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
                      child: FilterChip(
                        label: Text(category.name),
                        avatar: Icon(
                          categoryStyle(category).$2,
                          size: 16,
                          color: categoryStyle(category).$1,
                        ),
                        selected: taskProvider.activeFilter == category,
                        onSelected: (_) =>
                            context.read<TaskProvider>().setFilter(category),
                        selectedColor: categoryStyle(category).$1.withAlpha(
                          20,
                        ),
                        side: BorderSide(
                          color: taskProvider.activeFilter == category
                              ? categoryStyle(category).$1
                              : colors.outline,
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.all(8),
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
                              child: TaskCard(
                                task: task,
                                index: index,
                                borderRadius: _borderRadius,
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
                    tooltip: 'Choose category for new task',
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
                                categoryStyle(category).$2,
                                size: 14,
                                color: categoryStyle(category).$1,
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
