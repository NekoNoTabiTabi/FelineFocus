import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/timer_provider.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  @override
  void initState() {
    super.initState();

    // Start the timer automatically when this screen opens
    Future.microtask(() {
      final timeProvider = Provider.of<TimeProvider>(context, listen: false);
      
      // Validate before starting
      if (timeProvider.selectedApps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select apps to block first!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      if (timeProvider.remainingTime <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set a timer duration first!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      if (!timeProvider.isRunning) {
        timeProvider.startTimer();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }

  @override
  Widget build(BuildContext context) {
    final timeProvider = Provider.of<TimeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Session'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show blocking status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: timeProvider.isRunning 
                    ? Colors.green.withOpacity(0.2) 
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    timeProvider.isRunning 
                        ? "🔒 Focus Mode Active"
                        : "⏸️ Focus Paused",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: timeProvider.isRunning ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Blocking ${timeProvider.selectedApps.length} apps",
                    style: TextStyle(
                      fontSize: 14,
                      color: timeProvider.isRunning ? Colors.green.shade700 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            
            // Timer display
            Text(
              _formatTime(timeProvider.remainingTime),
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Play/Pause button
                GestureDetector(
                  onTap: timeProvider.isRunning
                      ? timeProvider.stopTimer
                      : timeProvider.startTimer,
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                    child: Icon(
                      timeProvider.isRunning ? Icons.pause : Icons.play_arrow,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 30),

                // Stop button
                GestureDetector(
                  onTap: () async {
                    await timeProvider.resetTimer();
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: const Icon(
                      Icons.stop,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}