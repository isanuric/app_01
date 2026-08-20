enum TaskPriority { low, medium, high }

enum TaskCategory { work, personal, shopping, other }

class Task {
  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.shopping,
  });

  final String id;
  String title;
  bool isDone;
  TaskPriority priority;
  TaskCategory category;
}
