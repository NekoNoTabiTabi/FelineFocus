import 'dart:async';
import 'package:flutter/material.dart';


class TimeProvider extends ChangeNotifier {
  int _remainingTime = 0;
  bool _isRunning = false;
  Timer? _timer;


  List<String> _selectedApps = []; // <-- store selected app package names

  int get remainingTime => _remainingTime;
  bool get isRunning => _isRunning;
  List<String> get selectedApps => _selectedApps;

  void setTime(int seconds) {
    _remainingTime = seconds;
    notifyListeners();
  }

  void updateSelectedApps(List<String> apps) {
    _selectedApps = apps;
    notifyListeners();
  }

  Future<void> startTimer() async {
    if (_remainingTime <= 0) return;

    _isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingTime > 0) {
        _remainingTime--;
        notifyListeners();
      } else {
        stopTimer();
      }
    });
  }

  Future<void> stopTimer() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;

   
  }

  Future<void> resetTimer() async {
    _timer?.cancel();
    _isRunning = false;
    _remainingTime = 0;
    notifyListeners();
  }
}
