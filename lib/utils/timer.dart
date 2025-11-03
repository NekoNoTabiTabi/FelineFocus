import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/timer_provider.dart'; // adjust path if needed

class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final timeProvider = Provider.of<TimeProvider>(context);

    return Column(


      mainAxisAlignment: MainAxisAlignment.center,


      children: [

        
        Stack(

          alignment: Alignment.center,

          children: [
            GestureDetector(
              onTap: () => _showTimePicker(context, timeProvider),
              child: Container(
                padding: const EdgeInsets.all(6), // Border thickness
                decoration: const BoxDecoration(
                color: Colors.green, // Border color
                shape: BoxShape.circle,
                ),
             child: ClipOval(
             child: ColoredBox(
             color: Color(0xFFC7E9C0),
             child: SizedBox(
               height: 250,
               width: 250,
               child: Center(
               child: Text(
              _formatTime(timeProvider.remainingTime),
               style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 45,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
)

],
),

    
/*
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
                  color: Colors.blue,
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
              onTap: timeProvider.resetTimer,
              child: Container(
                height: 50,
                width: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: const Icon(
                  Icons.stop,
                  size: 35,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),*/
      ],
    );
  }




  void _showTimePicker(BuildContext context, TimeProvider timerProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.white,
          height: 300,
          child: CupertinoTimerPicker(
            mode: CupertinoTimerPickerMode.hms,
            initialTimerDuration:
                Duration(seconds: timerProvider.remainingTime),
            onTimerDurationChanged: (Duration newDuration) {
              if (newDuration.inSeconds > 0) {
                timerProvider.setTime(newDuration.inSeconds);
              }
            },
          ),
        );
      },
    );
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }
}