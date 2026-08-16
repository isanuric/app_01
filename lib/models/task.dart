class Task {
  Task({required this.id, required this.title, this.isDone = false});

  final String id;
  final String title;
  bool isDone;
}
