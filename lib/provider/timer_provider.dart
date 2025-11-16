import 'dart:async';
import 'package:flutter/material.dart';
import '../service/app_block_service.dart'; // Add this import

class TimeProvider extends ChangeNotifier {
  int _remainingTime = 0;
  bool _isRunning = false;
  Timer? _timer;

  List<String> _selectedApps = [];

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
    
    // Enable app blocking when timer starts
    AppBlockManager.instance.setBlockedApps(_selectedApps);
    await AppBlockManager.instance.enableBlocking();
    
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingTime > 0) {
        _remainingTime--;
        notifyListeners();
      } else {
        await stopTimer();
      }
    });
  }

  Future<void> stopTimer() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;

    // Disable app blocking when timer stops
    await AppBlockManager.instance.disableBlocking();
    
    notifyListeners();
  }

  Future<void> resetTimer() async {
    _timer?.cancel();
    _isRunning = false;
    _remainingTime = 0;
    
    // Disable app blocking when timer resets
    await AppBlockManager.instance.disableBlocking();
    
    notifyListeners();
  }
}