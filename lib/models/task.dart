enum TaskPriority { low, medium, high }

class Task {
  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    this.priority = TaskPriority.medium,
  });

  final String id;
  String title;
  bool isDone;
  TaskPriority priority;
}
