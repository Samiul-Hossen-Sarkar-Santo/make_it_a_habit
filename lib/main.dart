import 'package:flutter/material.dart';
import 'package:make_it_a_habit/screens/focus_timer_screen.dart';
import 'package:make_it_a_habit/screens/habit_tracker_screen.dart';

void main() {
  runApp(const ProductivityApp());
}

class ProductivityApp extends StatelessWidget {
  const ProductivityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productivity App',
      theme: ThemeData(
        primaryColor: const Color(0xFF90CAF9), // Soft Blue
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Off-white
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF90CAF9), // Soft Blue for buttons
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          headlineMedium: TextStyle(
            color: Color(0xFF90CAF9),
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const FocusTimerScreen(),
      routes: {
        '/habit_tracker': (context) => const HabitTrackerScreen(),
      },
    );
  }
}
