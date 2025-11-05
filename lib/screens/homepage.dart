
import 'package:flutter/material.dart';
import 'package:felinefocused/service/app_block_service.dart';
import 'package:felinefocused/Screens/app_block_settings.dart';
import 'package:felinefocused/Screens/focus.dart';
import 'package:felinefocused/utils/timer.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: 
      
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [           
            // Set Timer
            TimerDisplay(),

            const SizedBox(height: 50),
            
             ElevatedButton(
             onPressed: () {
             Navigator.push(
             context,
             MaterialPageRoute(builder: (context) => const FocusScreen()),
             );

             
             },
           style: ElevatedButton.styleFrom(
           backgroundColor: Colors.green,
           shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(30),
          ),
           ),
           child: const Text(
           "Start Focus",
           style: TextStyle(fontSize: 18, color: Colors.white),
           ),
           ),
              
            const SizedBox(height: 20),
           
            ElevatedButton(
              onPressed: () {           
                Navigator.push(context,
                MaterialPageRoute(builder: (context) => const InstalledAppsTestScreen()),
                );
              },


            style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
           ),

            child: const Text('App Block', style: TextStyle(fontSize: 18, color: Colors.white)),

            ),

           



          ],
        ),
      ),
    );
  }
}