import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../services/time_service.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _textEditingController = TextEditingController();
  final _timeService = const TimeService();
  late final Future<DateTime> _dateTimeFuture;

  @override
  void initState() {
    super.initState();
    _dateTimeFuture = _timeService.fetchDateTime();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<TaskProvider>().addTask(_textEditingController.text);
    _textEditingController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().tasks;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final borderRadius = BorderRadius.circular(12);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DateTime>(
          future: _dateTimeFuture,
          builder: (context, snapshot) {
            final dateTime = snapshot.data;
            final date = dateTime == null
                ? 'Datum wird geladen ...'
                : '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
            final time = dateTime == null
                ? ''
                : '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} Uhr';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('My Tasks'),
                Text(
                  '$date $time',
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
                        hintText: 'Neue Aufgabe hinzufügen',
                        hintStyle: TextStyle(
                          color: colors.onSurface.withAlpha(100),
                        ),
                        border: OutlineInputBorder(borderRadius: borderRadius),
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
                          color: colors.primary.withAlpha(100),
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
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: colors.primary.withAlpha(100),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Noch keine Aufgaben.',
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Füge eine neue Aufgabe hinzu, um zu beginnen',
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
                              borderRadius: borderRadius,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: borderRadius,
                                border: task.isDone
                                    ? Border.all(
                                        color: Colors.grey.withAlpha(100),
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
                                  style: task.isDone
                                      ? textTheme.bodyLarge?.copyWith(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey,
                                        )
                                      : textTheme.bodyLarge,
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red.withAlpha(150),
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
