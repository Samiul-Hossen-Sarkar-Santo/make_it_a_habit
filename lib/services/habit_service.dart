import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:make_it_a_habit/models/habit.dart';

class HabitService {
  static const String _habitsKey = 'habits';

  // Load habits from SharedPreferences
  Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = prefs.getString(_habitsKey);
    if (habitsJson == null) return [];

    final List<dynamic> habitsList = jsonDecode(habitsJson);
    return habitsList.map((json) => Habit.fromJson(json)).toList();
  }

  // Save habits to SharedPreferences
  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson =
        jsonEncode(habits.map((habit) => habit.toJson()).toList());
    await prefs.setString(_habitsKey, habitsJson);
  }

  // Reset habits for a new day (called at midnight)
  Future<void> resetDailyHabits() async {
    final habits = await loadHabits();
    final now = DateTime.now();
    for (var habit in habits) {
      if (habit.isDoneToday) {
        final lastCompleted = habit.lastCompletedDate ?? now;
        final daysDifference = now.difference(lastCompleted).inDays;
        if (daysDifference >= 1) {
          habit.isDoneToday = false;
        }
      }
    }
    await saveHabits(habits);
  }
}
