import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low }

class Task {
  final String name;
  final TimeOfDay? dueTime;
  bool isDone;
  TaskPriority priority;

  Task({
    required this.name,
    this.dueTime,
    this.isDone = false,
    this.priority = TaskPriority.medium,
  });

  // Convert Task to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dueHour': dueTime?.hour,
      'dueMinute': dueTime?.minute,
      'isDone': isDone,
      'priority': priority.toString(),
    };
  }

  // Create Task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      name: json['name'],
      dueTime: json['dueHour'] != null && json['dueMinute'] != null
          ? TimeOfDay(hour: json['dueHour'], minute: json['dueMinute'])
          : null,
      isDone: json['isDone'],
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
    );
  }
}
