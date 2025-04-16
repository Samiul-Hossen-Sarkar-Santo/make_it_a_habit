import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:just_audio/just_audio.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  // Default values for focus, break, and cycles
  int focusTime = 25; // in minutes
  int breakTime = 5; // in minutes
  int cycles = 4;
  int currentCycle = 1;
  int remainingSeconds = 0;
  bool isFocusPhase = true;
  bool isRunning = false;
  Timer? timer;
  String motivationalMessage = '';
  final AudioPlayer audioPlayer = AudioPlayer();

  // Controllers for TextFields
  late final TextEditingController focusController;
  late final TextEditingController breakController;
  late final TextEditingController cyclesController;

  // List of motivational messages
  final List<String> messages = [
    'Stay focused and keep going!',
    'You’re doing amazing!',
    'One step at a time!',
    'Great job, keep it up!',
  ];

  @override
  void initState() {
    super.initState();
    remainingSeconds = focusTime * 60; // Initialize with focus time in seconds

    // Initialize controllers with default values
    focusController = TextEditingController(text: focusTime.toString());
    breakController = TextEditingController(text: breakTime.toString());
    cyclesController = TextEditingController(text: cycles.toString());
  }

  @override
  void dispose() {
    // Dispose controllers to free resources
    focusController.dispose();
    breakController.dispose();
    cyclesController.dispose();
    timer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> playSound(String soundPath) async {
    try {
      await audioPlayer.setAsset(soundPath);
      await audioPlayer.play();
    } catch (error) {
      debugPrint('Error playing sound: $error');
    }
  }

  void triggerAlarm() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate();
    } else {
      debugPrint('Vibration not supported on this device.');
    }
    playSound('assets/sounds/alarm.mp3');
  }

  void playCompletionSound() {
    playSound('sounds/congratulations.mp3');
  }

  void startTimer() {
    if (!isRunning) {
      setState(() {
        isRunning = true;
      });
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (remainingSeconds > 0) {
            remainingSeconds--;
          } else {
            // Switch between focus and break
            if (isFocusPhase) {
              triggerAlarm();
              isFocusPhase = false;
              remainingSeconds = breakTime * 60;
              setState(() {
                motivationalMessage = messages[currentCycle % messages.length];
              });
            } else {
              triggerAlarm();
              currentCycle++;
              if (currentCycle > cycles) {
                playCompletionSound();
                resetTimer();
                return;
              }
              isFocusPhase = true;
              remainingSeconds = focusTime * 60;
              setState(() {
                motivationalMessage = '';
              });
            }
          }
        });
      });
    }
  }

  void pauseTimer() {
    if (isRunning) {
      timer?.cancel();
      setState(() {
        isRunning = false;
      });
    }
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      isRunning = false;
      isFocusPhase = true;
      currentCycle = 1;
      remainingSeconds = focusTime * 60;
      motivationalMessage = '';
    });
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Inputs for focus time, break time, and cycles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Focus Time Input
                SizedBox(
                  width: 100,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Focus (min)',
                      labelStyle: const TextStyle(fontSize: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !isRunning,
                    onChanged: (value) {
                      setState(() {
                        focusTime = int.tryParse(value) ?? 25;
                        if (!isRunning && isFocusPhase) {
                          remainingSeconds = focusTime * 60;
                        }
                      });
                    },
                    controller: focusController,
                  ),
                ),
                // Break Time Input
                SizedBox(
                  width: 100,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Break (min)',
                      labelStyle: const TextStyle(fontSize: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !isRunning,
                    onChanged: (value) {
                      setState(() {
                        breakTime = int.tryParse(value) ?? 5;
                        if (!isRunning && !isFocusPhase) {
                          remainingSeconds = breakTime * 60;
                        }
                      });
                    },
                    controller: breakController,
                  ),
                ),
                // Cycles Input
                SizedBox(
                  width: 100,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Cycles',
                      labelStyle: const TextStyle(fontSize: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !isRunning,
                    onChanged: (value) {
                      setState(() {
                        cycles = int.tryParse(value) ?? 4;
                      });
                    },
                    controller: cyclesController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Circular Timer Display
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: remainingSeconds /
                        (isFocusPhase ? focusTime * 60 : breakTime * 60),
                    strokeWidth: 8,
                    color: isFocusPhase ? Colors.blue : Colors.green,
                  ),
                ),
                Text(
                  formatTime(remainingSeconds),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Phase and Cycle Info
            Text(
              isFocusPhase
                  ? 'Focus - Cycle $currentCycle of $cycles'
                  : 'Break - Cycle $currentCycle of $cycles',
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            // Motivational Message
            if (motivationalMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  motivationalMessage,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFFFFCA28), // Warm Yellow for motivation
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isRunning ? pauseTimer : startTimer,
                  child: Text(isRunning ? 'Pause' : 'Start'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: resetTimer,
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/habit_tracker');
                  },
                  child: const Text('Go to Habit Tracker'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
