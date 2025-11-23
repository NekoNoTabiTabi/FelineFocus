import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/app_block_service.dart';
import '../service/completion_overlay_service.dart';
import '../models/blocked_app_section.dart';
import '../models/focus_session.dart'; // ADD THIS
import '../models/daily_stats.dart';

class TimeProvider extends ChangeNotifier {
  int _remainingTime = 0;
  int _initialTime = 0;
  bool _isRunning = false;
  Timer? _timer;
  
  void Function()? onTimerComplete;

  List<BlockedAppSection> _selectedAppSections = [];
  bool _blockReels = false;

  // ADD THESE NEW FIELDS
  List<FocusSession> _sessionHistory = [];
  DateTime? _currentSessionStartTime;
  int _currentSessionElapsedSeconds = 0;

  // SharedPreferences keys
  static const String _keyInitialTime = 'initial_time';
  static const String _keySelectedAppSections = 'selected_app_sections';
  static const String _keyBlockReels = 'block_reels';
  static const String _keySessionHistory = 'session_history'; // ADD THIS

  int get remainingTime => _remainingTime;
  int get initialTime => _initialTime;
  bool get isRunning => _isRunning;
  List<BlockedAppSection> get selectedAppSections => _selectedAppSections;
  bool get blockReels => _blockReels;
  List<FocusSession> get sessionHistory => _sessionHistory; // ADD THIS

  // ADD THESE GETTERS FOR STATS
  int get totalSessions => _sessionHistory.length;
  
  int get completedSessions => _sessionHistory.where((s) => s.completed).length;
  
  Duration get totalFocusTime {
    return _sessionHistory.fold(
      Duration.zero,
      (sum, session) => sum + session.actualDuration,
    );
  }
  
  int get currentStreak {
    if (_sessionHistory.isEmpty) return 0;
    
    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Sort sessions by date (newest first)
    final sortedSessions = List<FocusSession>.from(_sessionHistory)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    
    DateTime checkDate = today;
    
    for (var session in sortedSessions) {
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      
      if (sessionDate == checkDate) {
        if (!session.completed) continue; // Only count completed sessions
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (sessionDate.isBefore(checkDate)) {
        // Gap in streak
        break;
      }
    }
    
    return streak;
  }

  Future<void> initialize() async {
    await _loadSavedData();
  }

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
      
      // Load reels blocking preference
      _blockReels = prefs.getBool(_keyBlockReels) ?? false;
      debugPrint("📂 Loaded reels blocking: $_blockReels");
      
      // ADD THIS - Load session history
      final savedHistoryJson = prefs.getStringList(_keySessionHistory) ?? [];
      if (savedHistoryJson.isNotEmpty) {
        _sessionHistory = savedHistoryJson
            .map((json) => FocusSession.fromJson(jsonDecode(json)))
            .toList();
        debugPrint("📂 Loaded ${_sessionHistory.length} focus sessions");
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error loading saved data: $e");
    }
  }

  Future<void> _saveInitialTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyInitialTime, _initialTime);
      debugPrint("💾 Saved initial time: ${_formatTime(_initialTime)}");
    } catch (e) {
      debugPrint("❌ Error saving initial time: $e");
    }
  }

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

  Future<void> _saveBlockReels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBlockReels, _blockReels);
      debugPrint("💾 Saved reels blocking: $_blockReels");
    } catch (e) {
      debugPrint("❌ Error saving reels blocking: $e");
    }
  }

  // ADD THIS - Save session history
  Future<void> _saveSessionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _sessionHistory
          .map((session) => jsonEncode(session.toJson()))
          .toList();
      await prefs.setStringList(_keySessionHistory, jsonList);
      debugPrint("💾 Saved ${_sessionHistory.length} focus sessions");
    } catch (e) {
      debugPrint("❌ Error saving session history: $e");
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

  Future<void> setBlockReels(bool value) async {
    _blockReels = value;
    await _saveBlockReels();
    notifyListeners();
  }

  Future<void> startTimer() async {
    if (_remainingTime <= 0) return;

    _isRunning = true;
    
    // ADD THIS - Track session start
    _currentSessionStartTime = DateTime.now();
    _currentSessionElapsedSeconds = 0;
    
    AppBlockManager.instance.setBlockedAppSections(_selectedAppSections);
    AppBlockManager.instance.setBlockReels(_blockReels);
    await AppBlockManager.instance.enableBlocking();
    
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingTime > 0) {
        _remainingTime--;
        _currentSessionElapsedSeconds++; // ADD THIS
        notifyListeners();
      } else {
        await _onTimerComplete();
      }
    });
  }

  Future<void> _onTimerComplete() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;

    await AppBlockManager.instance.disableBlocking();
    
    // ADD THIS - Save completed session
    await _saveSession(completed: true);
    
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
    
    // ADD THIS - Save incomplete session
    if (_currentSessionStartTime != null && _currentSessionElapsedSeconds > 0) {
      await _saveSession(completed: false);
    }
    
    _remainingTime = _initialTime;
    await AppBlockManager.instance.disableBlocking();
    notifyListeners();
  }

  // ADD THIS NEW METHOD
  Future<void> _saveSession({required bool completed}) async {
    if (_currentSessionStartTime == null) return;
    
    final session = FocusSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: _currentSessionStartTime!,
      endTime: DateTime.now(),
      plannedDuration: Duration(seconds: _initialTime),
      actualDuration: Duration(seconds: _currentSessionElapsedSeconds),
      completed: completed,
      blockedAppNames: _selectedAppSections.map((s) => s.appName).toList(),
    );
    
    _sessionHistory.insert(0, session); // Add to beginning (newest first)
    await _saveSessionHistory();
    
    _currentSessionStartTime = null;
    _currentSessionElapsedSeconds = 0;
    
    debugPrint("💾 Saved ${completed ? 'completed' : 'incomplete'} session: ${session.durationText}");
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
      await prefs.remove(_keyBlockReels);
      await prefs.remove(_keySessionHistory); // ADD THIS
      
      _remainingTime = 0;
      _initialTime = 0;
      _selectedAppSections.clear();
      _blockReels = false;
      _sessionHistory.clear(); // ADD THIS
      
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

 DailyStats getStatsForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    final sessionsForDate = _sessionHistory.where((session) {
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      return sessionDate == normalizedDate;
    }).toList();
    
    final totalMinutes = sessionsForDate.fold<int>(
      0,
      (sum, session) => sum + session.actualDuration.inMinutes,
    );
    
    final completed = sessionsForDate.where((s) => s.completed).length;
    final started = sessionsForDate.length;
    
    // Count blocked apps
    final appCounts = <String, int>{};
    for (var session in sessionsForDate) {
      for (var app in session.blockedAppNames) {
        appCounts[app] = (appCounts[app] ?? 0) + 1;
      }
    }
    
    // Get top 3 most blocked apps
    final sortedApps = appCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topApps = sortedApps.take(3).map((e) => e.key).toList();
    
    return DailyStats(
      date: normalizedDate,
      totalMinutes: totalMinutes,
      sessionsCompleted: completed,
      sessionsStarted: started,
      mostBlockedApps: topApps,
    );
  }

  // Get today's stats
  DailyStats get todayStats => getStatsForDate(DateTime.now());

  // Get yesterday's stats
  DailyStats get yesterdayStats => getStatsForDate(
    DateTime.now().subtract(const Duration(days: 1)),
  );

  // Get last 7 days of stats
  List<DailyStats> get weekStats {
    final stats = <DailyStats>[];
    final today = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      stats.add(getStatsForDate(date));
    }
    
    return stats;
  }

  // Get weekly summary
  String get weekSummary {
    final weeklyMinutes = weekStats.fold<int>(
      0,
      (sum, day) => sum + day.totalMinutes,
    );
    
    final hours = weeklyMinutes ~/ 60;
    final minutes = weeklyMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m this week';
    } else {
      return '${minutes}m this week';
    }
  }

  // Check if user focused today
  bool get focusedToday => todayStats.totalMinutes > 0;

  // Get best day this week (most minutes)
  DailyStats? get bestDayThisWeek {
    if (weekStats.isEmpty) return null;
    
    var best = weekStats.first;
    for (var day in weekStats) {
      if (day.totalMinutes > best.totalMinutes) {
        best = day;
      }
    }
    
    return best.totalMinutes > 0 ? best : null;
  }

}