import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';

Color priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.low => Colors.green,
  TaskPriority.medium => Colors.orange,
  TaskPriority.high => Colors.red,
};

(Color, IconData) categoryStyle(TaskCategory category) => switch (category) {
  TaskCategory.work => (Colors.blue, Icons.work_outline),
  TaskCategory.personal => (Colors.purple, Icons.person_outline),
  TaskCategory.shopping => (Colors.teal, Icons.shopping_cart_outlined),
  TaskCategory.other => (Colors.grey, Icons.category_outlined),
};

class TaskCard extends StatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.borderRadius,
  });

  final Task task;
  final int index;
  final BorderRadius borderRadius;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  final _editController = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEditing(String title) {
    setState(() {
      _editController.text = title;
      _editing = true;
    });
  }

  void _finishEditing() {
    final title = _editController.text.trim();
    if (title.isNotEmpty) {
      context.read<TaskProvider>().editTask(widget.task.id, title);
    }
    setState(() {
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final radius = widget.borderRadius;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        _editing = false;
        context.read<TaskProvider>().deleteTask(task.id);
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          context.read<TaskProvider>().toggleDone(task.id);
          return false;
        }
        return true;
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: radius,
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: radius,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: task.isDone
              ? BorderSide(color: colors.outlineVariant)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: priorityColor(task.priority),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Checkbox(
                value: task.isDone,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (_) =>
                    context.read<TaskProvider>().toggleDone(task.id),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _editing
                        ? TextField(
                            controller: _editController,
                            autofocus: true,
                            style: textTheme.bodyLarge,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _finishEditing(),
                            onTapOutside: (_) => _finishEditing(),
                          )
                        : GestureDetector(
                            onTap: task.isDone
                                ? null
                                : () => _startEditing(task.title),
                            child: Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyLarge?.copyWith(
                                decoration: task.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isDone
                                    ? colors.onSurfaceVariant
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
                            tooltip: 'Change category',
                            enabled: !task.isDone,
                            onSelected: (category) =>
                                context.read<TaskProvider>().setCategory(
                                  task.id,
                                  category,
                                ),
                            itemBuilder: (context) => [
                              for (final category in TaskCategory.values)
                                PopupMenuItem(
                                  value: category,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        categoryStyle(category).$2,
                                        size: 18,
                                        color: categoryStyle(category).$1,
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
                                  categoryStyle(task.category).$2,
                                  size: 14,
                                  color: categoryStyle(task.category).$1,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    task.category.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: categoryStyle(
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
                                context.read<TaskProvider>().setPriority(
                                  task.id,
                                  priority,
                                ),
                            itemBuilder: (context) => [
                              for (final priority in TaskPriority.values)
                                PopupMenuItem(
                                  value: priority,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: priorityColor(priority),
                                          shape: BoxShape.circle,
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
                              size: 16,
                              color: priorityColor(task.priority),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ReorderableDragStartListener(
                index: widget.index,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, top: 10),
                  child: Icon(
                    Icons.drag_handle,
                    size: 18,
                    color: colors.onSurface.withAlpha(120),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}