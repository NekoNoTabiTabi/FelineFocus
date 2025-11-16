import 'dart:async';
import 'package:flutter/material.dart';
import '../service/app_block_service.dart';
import '../service/completion_overlay_service.dart';

class TimeProvider extends ChangeNotifier {
  int _remainingTime = 0;
  bool _isRunning = false;
  Timer? _timer;
  
  // Callback for when timer completes (in-app UI)
  void Function()? onTimerComplete;

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
        
        // Show system-wide completion overlay
        await CompletionOverlayService.instance.showCompletionOverlayWithAutoClose(
          duration: const Duration(seconds: 10),
        );
        
        // Also trigger in-app callback if available
        onTimerComplete?.call();
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
    
    // Close any active completion overlay
    await CompletionOverlayService.instance.hideCompletionOverlay();
    
    notifyListeners();
  }
}