import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:make_it_a_habit/models/task.dart';

class TaskService {
  static const String _tasksKey = 'tasks';

  // Load tasks from SharedPreferences
  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_tasksKey);
    if (tasksJson == null) return [];

    final List<dynamic> tasksList = jsonDecode(tasksJson);
    return tasksList.map((json) => Task.fromJson(json)).toList();
  }

  // Save tasks to SharedPreferences
  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = jsonEncode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_tasksKey, tasksJson);
  }
}
