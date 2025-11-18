import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/app_block_service.dart';
import '../service/completion_overlay_service.dart';
import '../models/blocked_app_section.dart';

class TimeProvider extends ChangeNotifier {
  int _remainingTime = 0;
  int _initialTime = 0;
  bool _isRunning = false;
  Timer? _timer;
  
  // Callback for when timer completes (in-app UI)
  void Function()? onTimerComplete;

  List<BlockedAppSection> _selectedAppSections = [];

  // SharedPreferences keys
  static const String _keyInitialTime = 'initial_time';
  static const String _keySelectedAppSections = 'selected_app_sections';

  int get remainingTime => _remainingTime;
  int get initialTime => _initialTime;
  bool get isRunning => _isRunning;
  List<BlockedAppSection> get selectedAppSections => _selectedAppSections;

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
      
      // Load selected app sections
      final savedSectionsJson = prefs.getStringList(_keySelectedAppSections) ?? [];
      if (savedSectionsJson.isNotEmpty) {
        _selectedAppSections = savedSectionsJson
            .map((json) => BlockedAppSection.fromJson(jsonDecode(json)))
            .toList();
        debugPrint("📂 Loaded ${_selectedAppSections.length} saved app sections");
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

  /// Save selected app sections to preferences
  Future<void> _saveSelectedAppSections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _selectedAppSections
          .map((section) => jsonEncode(section.toJson()))
          .toList();
      await prefs.setStringList(_keySelectedAppSections, jsonList);
      debugPrint("💾 Saved ${_selectedAppSections.length} selected app sections");
    } catch (e) {
      debugPrint("❌ Error saving selected app sections: $e");
    }
  }

  void setTime(int seconds) {
    _remainingTime = seconds;
    _initialTime = seconds;
    _saveInitialTime();
    notifyListeners();
  }

  void updateSelectedAppSections(List<BlockedAppSection> sections) {
    _selectedAppSections = sections;
    _saveSelectedAppSections();
    notifyListeners();
  }

  Future<void> startTimer() async {
    if (_remainingTime <= 0) return;

    _isRunning = true;
    
    // Enable app blocking when timer starts
    AppBlockManager.instance.setBlockedAppSections(_selectedAppSections);
    await AppBlockManager.instance.enableBlocking();
    
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingTime > 0) {
        _remainingTime--;
        notifyListeners();
      } else {
        await _onTimerComplete();
      }
    });
  }

  /// Called when timer reaches 0
  Future<void> _onTimerComplete() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;

    await AppBlockManager.instance.disableBlocking();
    _remainingTime = _initialTime;
    
    notifyListeners();
    
    await CompletionOverlayService.instance.showCompletionOverlayWithAutoClose(
      duration: const Duration(seconds: 10),
    );
    
    onTimerComplete?.call();
  }

  Future<void> stopTimer() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _remainingTime = _initialTime;
    await AppBlockManager.instance.disableBlocking();
    notifyListeners();
  }

  Future<void> resetTimer() async {
    _timer?.cancel();
    _isRunning = false;
    _remainingTime = 0;
    _initialTime = 0;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyInitialTime);
      debugPrint("🗑️ Cleared saved timer");
    } catch (e) {
      debugPrint("❌ Error clearing saved timer: $e");
    }
    
    await AppBlockManager.instance.disableBlocking();
    await CompletionOverlayService.instance.hideCompletionOverlay();
    notifyListeners();
  }

  Future<void> restartTimer() async {
    _timer?.cancel();
    _isRunning = false;
    _remainingTime = _initialTime;
    notifyListeners();
    await startTimer();
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyInitialTime);
      await prefs.remove(_keySelectedAppSections);
      
      _remainingTime = 0;
      _initialTime = 0;
      _selectedAppSections.clear();
      
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