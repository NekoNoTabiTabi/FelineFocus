import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/app_block_service.dart';
import '../service/completion_overlay_service.dart';

class TimeProvider extends ChangeNotifier {
  int _remainingTime = 0;
  int _initialTime = 0;
  bool _isRunning = false;
  Timer? _timer;
  
  // Callback for when timer completes (in-app UI)
  void Function()? onTimerComplete;

  List<String> _selectedApps = [];

  // SharedPreferences keys
  static const String _keyInitialTime = 'initial_time';
  static const String _keySelectedApps = 'selected_apps';

  int get remainingTime => _remainingTime;
  int get initialTime => _initialTime;
  bool get isRunning => _isRunning;
  List<String> get selectedApps => _selectedApps;

  /// Initialize and load saved data
  Future<void> initialize() async {
    await _loadSavedData();
  }

  /// Load saved timer and apps data
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load initial time
      final savedTime = prefs.getInt(_keyInitialTime) ?? 0;
      if (savedTime > 0) {
        _initialTime = savedTime;
        _remainingTime = savedTime;
        debugPrint("📂 Loaded saved timer: ${_formatTime(savedTime)}");
      }
      
      // Load selected apps
      final savedApps = prefs.getStringList(_keySelectedApps) ?? [];
      if (savedApps.isNotEmpty) {
        _selectedApps = savedApps;
        debugPrint("📂 Loaded ${savedApps.length} saved apps");
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error loading saved data: $e");
    }
  }

  /// Save initial time to preferences
  Future<void> _saveInitialTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyInitialTime, _initialTime);
      debugPrint("💾 Saved initial time: ${_formatTime(_initialTime)}");
    } catch (e) {
      debugPrint("❌ Error saving initial time: $e");
    }
  }

  /// Save selected apps to preferences
  Future<void> _saveSelectedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keySelectedApps, _selectedApps);
      debugPrint("💾 Saved ${_selectedApps.length} selected apps");
    } catch (e) {
      debugPrint("❌ Error saving selected apps: $e");
    }
  }

  void setTime(int seconds) {
    _remainingTime = seconds;
    _initialTime = seconds;
    _saveInitialTime(); // Save to preferences
    notifyListeners();
  }

  void updateSelectedApps(List<String> apps) {
    _selectedApps = apps;
    _saveSelectedApps(); // Save to preferences
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
        // Timer completed - stop but don't reset values
        await _onTimerComplete();
      }
    });
  }

  /// Called when timer reaches 0
  Future<void> _onTimerComplete() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;

    // Disable app blocking
    await AppBlockManager.instance.disableBlocking();
    
    // Reset remaining time to initial value (NOT to 0)
    _remainingTime = _initialTime;
    
    notifyListeners();
    
    // Show system-wide completion overlay
    await CompletionOverlayService.instance.showCompletionOverlayWithAutoClose(
      duration: const Duration(seconds: 10),
    );
    
    // Also trigger in-app callback if available
    onTimerComplete?.call();
  }

  /// Stop/Pause timer - resets to initial value but keeps the setting
  Future<void> stopTimer() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;

    // Reset remaining time to initial value (ready for next session)
    _remainingTime = _initialTime;

    // Disable app blocking when timer stops
    await AppBlockManager.instance.disableBlocking();
    
    notifyListeners();
  }

  /// Completely reset and clear the timer (only used when intentionally clearing)
  Future<void> resetTimer() async {
    _timer?.cancel();
    _isRunning = false;
    _remainingTime = 0;
    _initialTime = 0;
    
    // Clear saved time
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyInitialTime);
      debugPrint("🗑️ Cleared saved timer");
    } catch (e) {
      debugPrint("❌ Error clearing saved timer: $e");
    }
    
    // Disable app blocking when timer resets
    await AppBlockManager.instance.disableBlocking();
    
    // Close any active completion overlay
    await CompletionOverlayService.instance.hideCompletionOverlay();
    
    notifyListeners();
  }

  /// Restart timer with the same initial duration
  Future<void> restartTimer() async {
    _timer?.cancel();
    _isRunning = false;
    _remainingTime = _initialTime;
    
    notifyListeners();
    
    // Start the timer again
    await startTimer();
  }

  /// Clear all saved data (useful for settings/reset)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyInitialTime);
      await prefs.remove(_keySelectedApps);
      
      _remainingTime = 0;
      _initialTime = 0;
      _selectedApps.clear();
      
      debugPrint("🗑️ Cleared all saved data");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error clearing data: $e");
    }
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }
}