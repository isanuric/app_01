import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../services/time_service.dart';

String _formatDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

String _formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _textEditingController = TextEditingController();
  final _timeService = const TimeService();
  late Future<DateTime> _dateTimeFuture;
  Timer? _timer;
  late Color _hintTextColor;
  late Color _doneTaskBorderColor;
  late Color _deleteIconColor;
  late Color _emptyStateIconColor;
  late Color _shadowColor;
  final _borderRadius = BorderRadius.circular(12);
  bool _colorsInitialized = false;

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

  void _initializeColors() {
    if (_colorsInitialized) return;
    final colors = Theme.of(context).colorScheme;
    _hintTextColor = colors.onSurface.withAlpha(100);
    _doneTaskBorderColor = Colors.grey.withAlpha(100);
    _deleteIconColor = Colors.red.withAlpha(150);
    _emptyStateIconColor = colors.primary.withAlpha(100);
    _shadowColor = colors.primary.withAlpha(100);
    _colorsInitialized = true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textEditingController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<TaskProvider>().addTask(_textEditingController.text);
    _textEditingController.clear();
  }

  @override
  Widget build(BuildContext context) {
    _initializeColors();
    final tasks = context.watch<TaskProvider>().tasks;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DateTime>(
          future: _dateTimeFuture,
          builder: (context, snapshot) {
            final dateTime = snapshot.data;
            final dateStr = dateTime == null ? 'Loading date...' : _formatDate(dateTime);
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
        ),
        elevation: 0,
        centerTitle: true,
      ),
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
                        hintStyle: TextStyle(
                          color: _hintTextColor,
                        ),
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
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _shadowColor,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 40,
                    child: Checkbox(
                      value: tasks.isNotEmpty && tasks.every((t) => t.isDone),
                      onChanged: tasks.isEmpty
                          ? null
                          : (value) => context
                              .read<TaskProvider>()
                              .setAllDone(value ?? false),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Select All'),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: _emptyStateIconColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks yet.',
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
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: _borderRadius,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: _borderRadius,
                                border: task.isDone
                                    ? Border.all(
                                        color: _doneTaskBorderColor,
                                      )
                                    : null,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Checkbox(
                                  value: task.isDone,
                                  onChanged: (_) => context
                                      .read<TaskProvider>()
                                      .toggleDone(task.id),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                title: Text(
                                  task.title,
                                  style: textTheme.bodyLarge?.copyWith(
                                    decoration: task.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: task.isDone ? Colors.grey : null,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: _deleteIconColor,
                                  ),
                                  onPressed: () => context
                                      .read<TaskProvider>()
                                      .deleteTask(task.id),
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
    );
  }
}

