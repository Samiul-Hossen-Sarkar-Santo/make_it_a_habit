import 'dart:async';
import 'package:flutter/material.dart';
import 'package:make_it_a_habit/models/habit.dart';
import 'package:make_it_a_habit/services/habit_service.dart';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  List<Habit> habits = [];
  final HabitService habitService = HabitService();
  Timer? reminderTimer;

  @override
  void initState() {
    super.initState();
    _loadHabits();
    _startReminderTimer();
  }

  @override
  void dispose() {
    reminderTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    final loadedHabits = await habitService.loadHabits();
    setState(() {
      habits = loadedHabits;
    });
    _resetHabitsForNewDay();
  }

  void _startReminderTimer() {
    reminderTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = TimeOfDay.now();
      for (var habit in habits) {
        if (!habit.isDoneToday &&
            habit.reminderTime.hour == now.hour &&
            habit.reminderTime.minute == now.minute) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder: Time to do "${habit.name}"!'),
              backgroundColor: const Color(0xFFFFCA28), // Warm Yellow
            ),
          );
        }
      }
    });
  }

  Future<void> _resetHabitsForNewDay() async {
    await habitService.resetDailyHabits();
    await _loadHabits();
  }

  void _addHabit(String name, TimeOfDay reminderTime) async {
    final newHabit = Habit(name: name, reminderTime: reminderTime);
    setState(() {
      habits.add(newHabit);
    });
    await habitService.saveHabits(habits);
  }

  void _deleteHabit(int index) async {
    setState(() {
      habits.removeAt(index);
    });
    await habitService.saveHabits(habits);
  }

  void _toggleHabitDone(int index) async {
    setState(() {
      final habit = habits[index];
      habit.isDoneToday = !habit.isDoneToday;
      final now = DateTime.now();
      if (habit.isDoneToday) {
        final lastCompleted = habit.lastCompletedDate;
        if (lastCompleted == null ||
            lastCompleted.difference(now).inDays.abs() >= 1) {
          // Check if completed yesterday or earlier
          if (lastCompleted != null &&
              lastCompleted.day == now.subtract(const Duration(days: 1)).day) {
            habit.streak++;
          } else {
            habit.streak = 1;
          }
        }
        habit.lastCompletedDate = now;
      } else {
        habit.streak = 0; // Reset streak if unchecked
        habit.lastCompletedDate = null;
      }
    });
    await habitService.saveHabits(habits);
  }

  void _showAddHabitDialog() {
    final nameController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Habit Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Reminder Time:'),
                  TextButton(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedTime = pickedTime;
                        });
                      }
                    },
                    child: Text(selectedTime.format(context)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _addHabit(nameController.text, selectedTime);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: habits.isEmpty
            ? const Center(
                child: Text(
                  'No habits yet. Add one to start!',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              )
            : ListView.builder(
                itemCount: habits.length,
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Checkbox(
                        value: habit.isDoneToday,
                        onChanged: (value) => _toggleHabitDone(index),
                        activeColor: const Color(0xFF90CAF9),
                      ),
                      title: Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              habit.isDoneToday ? Colors.grey : Colors.black87,
                          decoration: habit.isDoneToday
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        'Reminder: ${habit.reminderTime.format(context)}\nStreak: ${habit.streak} day${habit.streak == 1 ? '' : 's'}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteHabit(index),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        backgroundColor: const Color(0xFF90CAF9),
        child: const Icon(Icons.add),
      ),
    );
  }
}
