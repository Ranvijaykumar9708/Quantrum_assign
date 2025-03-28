import 'package:uuid/uuid.dart';

enum TaskPriority {
  low,
  medium,
  high
}

class Task {
  final String id;
  String title;
  String description;
  TaskPriority priority;
  DateTime createdAt;
  DateTime? dueDate;
  bool isCompleted;

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.low,
    DateTime? createdAt,
    this.dueDate,
    this.isCompleted = false,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      priority: TaskPriority.values[map['priority']],
      createdAt: DateTime.parse(map['createdAt']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isCompleted: map['isCompleted'] == 1,
    );
  }

  Task copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}