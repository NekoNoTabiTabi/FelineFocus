import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/timer_provider.dart'; // adjust path if needed

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
      
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(timeProvider.remainingTime),
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

             Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: timeProvider.isRunning
                  ? timeProvider.pauseTimer
                  : timeProvider.startTimer,
              child: Container(
                height: 50,
                width: 50,
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
            const SizedBox(width: 20),


            GestureDetector(
              onTap: (){ 
                timeProvider.resetTimer();
                Navigator.pop(context);

              },
              child: Container(
                height: 50,
                width: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
                child: const Icon(
                  Icons.stop,
                  size: 35,
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
