import 'package:flutter/material.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Page'),
      ),
      body: const Center(
        child: Text('Welcome to the Focus Page!'),
      ),
    );
  }
}