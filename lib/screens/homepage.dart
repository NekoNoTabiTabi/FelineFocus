import 'package:flutter/material.dart';
import 'package:felinefocused/screens/setTimer.dart';
import 'package:felinefocused/screens/appBlock.dart';
import 'package:felinefocused/screens/focus.dart';


class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: 
      
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

           
            
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SetTimer()),
                );
            },
            child: const Text('Set Timer'),
            ),
            
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