import 'package:flutter/material.dart';

import 'package:felinefocused/Screens/appBlock.dart';
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
                Navigator.push(context,
                MaterialPageRoute(builder: (context) => const FocusScreen()),
                );
            },
            child: const Text('Focus'),
            ),

            
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AppBlock()),
                );
            },
            child: const Text('App Block'),
            ),

           


          ],
        ),
      ),
    );
  }
}