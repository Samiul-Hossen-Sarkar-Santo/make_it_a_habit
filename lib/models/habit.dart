import 'package:flutter/material.dart';

class Habit {
  final String name;
  final TimeOfDay reminderTime;
  bool isDoneToday;
  int streak;
  DateTime? lastCompletedDate;

  Habit({
    required this.name,
    required this.reminderTime,
    this.isDoneToday = false,
    this.streak = 0,
    this.lastCompletedDate,
  });

  // Convert Habit to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'reminderHour': reminderTime.hour,
      'reminderMinute': reminderTime.minute,
      'isDoneToday': isDoneToday,
      'streak': streak,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
    };
  }

  // Create Habit from JSON
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      name: json['name'],
      reminderTime: TimeOfDay(
        hour: json['reminderHour'],
        minute: json['reminderMinute'],
      ),
      isDoneToday: json['isDoneToday'],
      streak: json['streak'],
      lastCompletedDate: json['lastCompletedDate'] != null
          ? DateTime.parse(json['lastCompletedDate'])
          : null,
    );
  }
}
