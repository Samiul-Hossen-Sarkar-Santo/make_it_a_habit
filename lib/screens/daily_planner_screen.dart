import 'package:flutter/material.dart';
import 'package:make_it_a_habit/models/task.dart';
import 'package:make_it_a_habit/services/task_service.dart';

class DailyPlannerScreen extends StatefulWidget {
  const DailyPlannerScreen({super.key});

  @override
  State<DailyPlannerScreen> createState() => _DailyPlannerScreenState();
}

class _DailyPlannerScreenState extends State<DailyPlannerScreen> {
  List<Task> tasks = [];
  final TaskService taskService = TaskService();
  String sortMode = 'timeline'; // timeline, priority, manual
  double completionPercentage = 0.0;
  String motivationalMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final loadedTasks = await taskService.loadTasks();
    setState(() {
      tasks = loadedTasks;
      _updateCompletionPercentage();
    });
  }

  void _updateCompletionPercentage() {
    if (tasks.isEmpty) {
      setState(() {
        completionPercentage = 0.0;
        motivationalMessage = '';
      });
      return;
    }
    final completedTasks = tasks.where((task) => task.isDone).length;
    final percentage = (completedTasks / tasks.length) * 100;
    setState(() {
      completionPercentage = percentage;
      if (percentage >= 100) {
        motivationalMessage = 'Amazing job! You completed all tasks!';
      } else if (percentage >= 50) {
        motivationalMessage = 'Halfway there, keep going!';
      } else {
        motivationalMessage = '';
      }
    });
  }

  void _addTask(String name, TimeOfDay? dueTime, TaskPriority priority) async {
    final newTask = Task(name: name, dueTime: dueTime, priority: priority);
    setState(() {
      tasks.add(newTask);
      _updateCompletionPercentage();
    });
    await taskService.saveTasks(tasks);
  }

  void _toggleTaskDone(int index) async {
    setState(() {
      tasks[index].isDone = !tasks[index].isDone;
      _updateCompletionPercentage();
    });
    await taskService.saveTasks(tasks);
  }

  void _deleteTask(int index) async {
    setState(() {
      tasks.removeAt(index);
      _updateCompletionPercentage();
    });
    await taskService.saveTasks(tasks);
  }

  void _reorderTasks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final task = tasks.removeAt(oldIndex);
      tasks.insert(newIndex, task);
    });
    taskService.saveTasks(tasks);
  }

  void _sortTasks(String mode) {
    setState(() {
      sortMode = mode;
      if (mode == 'priority') {
        tasks.sort((a, b) => a.priority.index.compareTo(b.priority.index));
      } else if (mode == 'timeline') {
        tasks.sort((a, b) {
          if (a.dueTime == null && b.dueTime == null) return 0;
          if (a.dueTime == null) return 1;
          if (b.dueTime == null) return -1;
          final aMinutes = a.dueTime!.hour * 60 + a.dueTime!.minute;
          final bMinutes = b.dueTime!.hour * 60 + b.dueTime!.minute;
          return aMinutes.compareTo(bMinutes);
        });
      }
    });
    taskService.saveTasks(tasks);
  }

  void _showAddTaskDialog() {
    final nameController = TextEditingController();
    TimeOfDay? selectedTime;
    TaskPriority selectedPriority = TaskPriority.medium;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Task Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Due Time (Optional):'),
                      TextButton(
                        onPressed: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              selectedTime = pickedTime;
                            });
                          }
                        },
                        child: Text(
                          selectedTime?.format(context) ?? 'No Due',
                          style: TextStyle(
                            color: selectedTime == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Priority:'),
                      DropdownButton<TaskPriority>(
                        value: selectedPriority,
                        onChanged: (value) {
                          setState(() {
                            selectedPriority = value!;
                          });
                        },
                        items: TaskPriority.values
                            .map((priority) => DropdownMenuItem(
                                  value: priority,
                                  child: Text(
                                    priority
                                        .toString()
                                        .split('.')
                                        .last
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: priority == TaskPriority.high
                                          ? Colors.red
                                          : priority == TaskPriority.medium
                                              ? Colors.orange
                                              : Colors.green,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _addTask(nameController.text, selectedTime, selectedPriority);
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
        title: const Text(
          'Daily Planner',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _sortTasks(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'timeline', child: Text('Sort by Time')),
              const PopupMenuItem(
                  value: 'priority', child: Text('Sort by Priority')),
              const PopupMenuItem(value: 'manual', child: Text('Manual Sort')),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: completionPercentage / 100,
                    strokeWidth: 8,
                    color: const Color(0xFF90CAF9),
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                Text(
                  '${completionPercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (motivationalMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                motivationalMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFFFCA28), // Warm Yellow
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          // Timeline View
          Expanded(
            child: tasks.isEmpty
                ? const Center(
                    child: Text(
                      'No tasks yet. Add one to start!',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  )
                : sortMode == 'manual'
                    ? ReorderableListView(
                        onReorder: _reorderTasks,
                        children: tasks.map((task) {
                          return _buildTaskTile(task, tasks.indexOf(task));
                        }).toList(),
                      )
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return _buildTaskTile(tasks[index], index);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: const Color(0xFF90CAF9),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskTile(Task task, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      key: ValueKey(task),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Dot and Line
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isDone
                      ? const Color(0xFF90CAF9)
                      : const Color(0xFFFF7F50), // Coral for incomplete
                ),
              ),
              if (index < tasks.length - 1)
                Container(
                  width: 2,
                  height: 50,
                  color: Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Task Details
          Expanded(
            child: AnimatedOpacity(
              opacity: task.isDone ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: task.isDone,
                        onChanged: (value) => _toggleTaskDone(index),
                        activeColor: const Color(0xFF90CAF9),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.name,
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    task.isDone ? Colors.grey : Colors.black87,
                                decoration: task.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            Row(
                              children: [
                                if (task.dueTime != null)
                                  Text(
                                    'Due: ${task.dueTime!.format(context)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (task.dueTime == null)
                                  const Text(
                                    'No Due',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: task.priority == TaskPriority.high
                                        ? Colors.red[100]
                                        : task.priority == TaskPriority.medium
                                            ? Colors.orange[100]
                                            : Colors.green[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    task.priority
                                        .toString()
                                        .split('.')
                                        .last
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: task.priority == TaskPriority.high
                                          ? Colors.red
                                          : task.priority == TaskPriority.medium
                                              ? Colors.orange
                                              : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTask(index),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
