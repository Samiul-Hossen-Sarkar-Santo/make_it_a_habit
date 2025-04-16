import 'package:flutter/material.dart';
import 'package:make_it_a_habit/models/habit.dart';
import 'package:make_it_a_habit/models/task.dart';
import 'package:make_it_a_habit/screens/daily_planner_screen.dart';
import 'package:make_it_a_habit/screens/focus_timer_screen.dart';
import 'package:make_it_a_habit/screens/habit_tracker_screen.dart';
import 'package:make_it_a_habit/services/habit_service.dart';
import 'package:make_it_a_habit/services/task_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const HomeDashboard(),
    const FocusTimerScreen(),
    const HabitTrackerScreen(),
    const DailyPlannerScreen(),
  ];
  final HabitService habitService = HabitService();
  final TaskService taskService = TaskService();
  int habitsCompleted = 0;
  int totalHabits = 0;
  int tasksCompleted = 0;
  int totalTasks = 0;
  int focusSessions = 0; // Placeholder for now

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  Future<void> _loadSummaryData() async {
    final loadedHabits = await habitService.loadHabits();
    final loadedTasks = await taskService.loadTasks();
    setState(() {
      totalHabits = loadedHabits.length;
      habitsCompleted = loadedHabits.where((h) => h.isDoneToday).length;
      totalTasks = loadedTasks.length;
      tasksCompleted = loadedTasks.where((t) => t.isDone).length;
      // focusSessions will be integrated later when FocusTimer state is tracked
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0
          ? Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Home Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.teal,
                centerTitle: true,
              ),
              body: _screens[_selectedIndex],
            )
          : _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Focus'),
          BottomNavigationBarItem(
              icon: Icon(Icons.track_changes_rounded), label: 'Habits'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tasks'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final HabitService habitService = HabitService();
  final TaskService taskService = TaskService();
  int habitsCompleted = 0;
  int totalHabits = 0;
  int tasksCompleted = 0;
  int totalTasks = 0;
  int focusSessions = 0; // Placeholder for now

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  Future<void> _loadSummaryData() async {
    final loadedHabits = await habitService.loadHabits();
    final loadedTasks = await taskService.loadTasks();
    setState(() {
      totalHabits = loadedHabits.length;
      habitsCompleted = loadedHabits.where((h) => h.isDoneToday).length;
      totalTasks = loadedTasks.length;
      tasksCompleted = loadedTasks.where((t) => t.isDone).length;
      // focusSessions will be integrated later
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitPercentage =
        totalHabits > 0 ? (habitsCompleted / totalHabits) * 100 : 0.0;
    final taskPercentage =
        totalTasks > 0 ? (tasksCompleted / totalTasks) * 100 : 0.0;
    String motivationalMessage = '';
    if (habitPercentage >= 100 && taskPercentage >= 100) {
      motivationalMessage = 'Incredible! You’ve crushed it today!';
    } else if (habitPercentage >= 50 || taskPercentage >= 50) {
      motivationalMessage = 'Good work—keep the momentum!';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today’s Progress',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProgressCard(
                      'Habits', habitsCompleted, totalHabits, habitPercentage),
                  const SizedBox(height: 16),
                  _buildProgressCard(
                      'Tasks', tasksCompleted, totalTasks, taskPercentage),
                  const SizedBox(height: 16),
                  _buildProgressCard('Focus Sessions', focusSessions, 0, 0.0,
                      isPlaceholder: true), // Placeholder
                ],
              ),
            ),
          ),
          if (motivationalMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                motivationalMessage,
                style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFFFCA28),
                    fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _loadSummaryData(); // Refresh data
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
      String title, int completed, int total, double percentage,
      {bool isPlaceholder = false}) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 16, color: Colors.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500)),
              Text(
                isPlaceholder
                    ? 'Tracking to be added'
                    : '$completed of $total completed (${percentage.toStringAsFixed(0)}%)',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
        if (!isPlaceholder)
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 6,
            color: Colors.teal,
            backgroundColor: Colors.grey[200],
          ),
      ],
    );
  }
}
