
import 'package:flutter/material.dart';

class SetTimer extends StatelessWidget {
  const SetTimer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Timer'),
      ),
      body: const Center(
        child: Text('Welcome to the Set Timer Page!'),
      ),
    );
  }
}