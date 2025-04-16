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
  double dailyCompletionPercentage = 0.0;
  String motivationalMessage = '';
  int longestStreak = 0;
  int totalDaysTracked = 0;

  @override
  void initState() {
    super.initState();
    _loadHabits();
    _startReminderTimer();
    _calculateMetrics();
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
      _updateCompletionPercentage();
      _calculateMetrics();
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

  void _updateCompletionPercentage() {
    if (habits.isEmpty) {
      setState(() {
        dailyCompletionPercentage = 0.0;
        motivationalMessage = '';
      });
      return;
    }
    final completedHabits = habits.where((habit) => habit.isDoneToday).length;
    final percentage = (completedHabits / habits.length) * 100;
    setState(() {
      dailyCompletionPercentage = percentage;
      if (percentage >= 100) {
        motivationalMessage = 'Fantastic! You’ve completed all habits today!';
      } else if (percentage >= 50) {
        motivationalMessage = 'Great progress—keep it up!';
      } else {
        motivationalMessage = '';
      }
    });
  }

  void _calculateMetrics() {
    if (habits.isEmpty) {
      longestStreak = 0;
      totalDaysTracked = 0;
      return;
    }
    longestStreak = habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
    totalDaysTracked =
        habits.fold(0, (sum, h) => sum + (h.lastCompletedDate != null ? 1 : 0));
  }

  void _addHabit(String name, TimeOfDay reminderTime) async {
    final newHabit = Habit(name: name, reminderTime: reminderTime);
    setState(() {
      habits.add(newHabit);
      _updateCompletionPercentage();
      _calculateMetrics();
    });
    await habitService.saveHabits(habits);
  }

  void _deleteHabit(int index) async {
    setState(() {
      habits.removeAt(index);
      _updateCompletionPercentage();
      _calculateMetrics();
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
          if (lastCompleted != null &&
              lastCompleted.day == now.subtract(const Duration(days: 1)).day) {
            habit.streak++;
          } else {
            habit.streak = 1;
          }
        }
        habit.lastCompletedDate = now;
      } else {
        habit.streak = 0;
        habit.lastCompletedDate = null;
      }
      _updateCompletionPercentage();
      _calculateMetrics();
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

  void _showEditHabitDialog(int index) {
    final habit = habits[index];
    final nameController = TextEditingController(text: habit.name);
    TimeOfDay selectedTime = habit.reminderTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Habit'),
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
                  setState(() {
                    habits[index].name = nameController.text;
                    habits[index].reminderTime = selectedTime;
                  });
                  habitService.saveHabits(habits);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
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
        title: const Text(
          'Habit Tracker',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(
          color: Colors.white, // Change the color of the back button
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetricCard('Total Habits',
                            habits.length.toString(), Colors.teal),
                        const SizedBox(height: 8),
                        _buildMetricCard('Longest Streak',
                            '$longestStreak days', Colors.orange),
                        const SizedBox(height: 8),
                        _buildMetricCard(
                            'Days Tracked', '$totalDaysTracked', Colors.grey),
                      ],
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: dailyCompletionPercentage / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey[200],
                            color: Colors.teal,
                          ),
                        ),
                        Text(
                          '${dailyCompletionPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                if (motivationalMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      motivationalMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.teal,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Text(
                      'Tip: Consistency beats perfection—start small!',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
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
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: ListTile(
                          leading: Icon(
                            habit.isDoneToday
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color:
                                habit.isDoneToday ? Colors.teal : Colors.grey,
                          ),
                          title: Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: habit.isDoneToday
                                  ? Colors.grey
                                  : Colors.black87,
                              decoration: habit.isDoneToday
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Reminder: ${habit.reminderTime.format(context)}'),
                              Text(
                                habit.lastCompletedDate != null
                                    ? 'Last: ${habit.lastCompletedDate!.day}/${habit.lastCompletedDate!.month}/${habit.lastCompletedDate!.year}'
                                    : 'Never',
                              ),
                              Text('Streak: ${habit.streak} days'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.teal),
                                onPressed: () => _showEditHabitDialog(index),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Habit'),
                                      content: const Text(
                                          'Are you sure you want to delete this habit?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            _deleteHabit(index);
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () => _toggleHabitDone(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        backgroundColor: Colors.teal,
        elevation: 6,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 16, color: color),
          const SizedBox(width: 4),
          Text('$title: $value', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
