import 'package:flutter/material.dart';

class AppBlock extends StatelessWidget {
  const AppBlock({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Block'),
      ),
      body: const Center(
        child: Text('Welcome to the App Block!'),
      ),
    );
  }
}