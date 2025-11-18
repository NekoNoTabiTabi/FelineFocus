import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/timer_provider.dart';
import 'timer_complete_overlay.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();

    // Set up timer completion callback for in-app overlay
    Future.microtask(() {
      final timeProvider = Provider.of<TimeProvider>(context, listen: false);
      
      // Set callback for when timer completes (in-app overlay)
      timeProvider.onTimerComplete = () {
        // Only show in-app overlay if user is still in the app
        if (mounted) {
          _showTimerCompleteOverlay();
        }
      };
      
     
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

  @override
  void dispose() {
    // Clear callback and remove overlay when screen is disposed
    final timeProvider = Provider.of<TimeProvider>(context, listen: false);
    timeProvider.onTimerComplete = null;
    _removeOverlay();
    super.dispose();
  }

  void _showTimerCompleteOverlay() {
    if (_overlayEntry != null) return; // Prevent duplicate overlays

    _overlayEntry = OverlayEntry(
      builder: (context) => TimerCompleteOverlay(
        onDismiss: () {
          _removeOverlay();
          Navigator.of(context).pop(); // Go back to homepage
        },
        onStartAnother: () {
          _removeOverlay();
          final timeProvider = Provider.of<TimeProvider>(context, listen: false);
          // Restart with the same duration using restartTimer
          timeProvider.restartTimer();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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

    return WillPopScope(
  onWillPop: () async {
    // Show confirmation dialog when user tries to leave during active session
    if (timeProvider.isRunning) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('End Focus Session?'),
          content: const Text(
            'Are you sure you want to end your focus session early? Your timer will be reset to the start.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await timeProvider.stopTimer(); // Use stopTimer instead of resetTimer
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'End Session',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  },
      child: Scaffold(
      
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
              
              // Show initial duration hint
              if (timeProvider.initialTime > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'of ${_formatTime(timeProvider.initialTime)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
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
    if (timeProvider.isRunning) {
      final shouldStop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('End Session?'),
          content: const Text(
            'Are you sure you want to end your focus session? Your timer will be reset to the start.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'End',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      
      if (shouldStop == true) {
        await timeProvider.stopTimer(); // Use stopTimer instead of resetTimer
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } else {
      await timeProvider.stopTimer(); // Use stopTimer instead of resetTimer
      if (mounted) {
        Navigator.pop(context);
      }
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
      ),
    );
  }
}