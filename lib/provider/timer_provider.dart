import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/app_block_service.dart';
import '../service/completion_overlay_service.dart';
import '../service/focus_session_service.dart';
import '../models/blocked_app_section.dart';
import '../models/focus_session.dart';
import '../models/daily_stats.dart';

class TimeProvider extends ChangeNotifier {
  int _remainingTime = 0;
  int _initialTime = 0;
  bool _isRunning = false;
  Timer? _timer;
  
  void Function()? onTimerComplete;

  List<BlockedAppSection> _selectedAppSections = [];
  bool _blockReels = false;

  List<FocusSession> _sessionHistory = [];
  DateTime? _currentSessionStartTime;
  int _currentSessionElapsedSeconds = 0;

  // NEW: Current user ID
  String? _currentUserId;
  bool _isLoadingHistory = false;

  // SharedPreferences keys (for timer settings only, not sessions)
  static const String _keyInitialTime = 'initial_time';
  static const String _keySelectedAppSections = 'selected_app_sections';
  static const String _keyBlockReels = 'block_reels';

  int get remainingTime => _remainingTime;
  int get initialTime => _initialTime;
  bool get isRunning => _isRunning;
  List<BlockedAppSection> get selectedAppSections => _selectedAppSections;
  bool get blockReels => _blockReels;
  List<FocusSession> get sessionHistory => _sessionHistory;
  bool get isLoadingHistory => _isLoadingHistory;

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
        if (!session.completed) continue;
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (sessionDate.isBefore(checkDate)) {
        break;
      }
    }
    
    return streak;
  }

  Future<void> initialize() async {
    await _loadSavedData();
  }

  /// NEW: Set current user and load their history
  Future<void> setUser(String? userId) async {
    _currentUserId = userId;
    
    if (userId != null) {
      await loadUserHistory();
    } else {
      _sessionHistory.clear();
      notifyListeners();
    }
  }

  /// NEW: Load user's focus session history from Firestore
  Future<void> loadUserHistory() async {
    if (_currentUserId == null) return;
    
    _isLoadingHistory = true;
    notifyListeners();
    
    try {
      final sessions = await FocusSessionService.instance.getFocusSessions(_currentUserId!);
      _sessionHistory = sessions;
      debugPrint("📚 Loaded ${sessions.length} focus sessions from Firestore");
    } catch (e) {
      debugPrint("❌ Error loading history: $e");
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load timer settings (not sessions)
      final savedTime = prefs.getInt(_keyInitialTime) ?? 0;
      if (savedTime > 0) {
        _initialTime = savedTime;
        _remainingTime = savedTime;
        debugPrint("📂 Loaded saved timer: ${_formatTime(savedTime)}");
      }
      
      final savedSectionsJson = prefs.getStringList(_keySelectedAppSections) ?? [];
      if (savedSectionsJson.isNotEmpty) {
        _selectedAppSections = savedSectionsJson
            .map((json) => BlockedAppSection.fromJson(jsonDecode(json)))
            .toList();
        debugPrint("📂 Loaded ${_selectedAppSections.length} saved app sections");
      }
      
      _blockReels = prefs.getBool(_keyBlockReels) ?? false;
      debugPrint("📂 Loaded reels blocking: $_blockReels");
      
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error loading saved data: $e");
    }
  }

  Future<void> _saveInitialTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyInitialTime, _initialTime);
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
    } catch (e) {
      debugPrint("❌ Error saving selected app sections: $e");
    }
  }

  Future<void> _saveBlockReels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBlockReels, _blockReels);
    } catch (e) {
      debugPrint("❌ Error saving reels blocking: $e");
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
    _currentSessionStartTime = DateTime.now();
    _currentSessionElapsedSeconds = 0;
    
    AppBlockManager.instance.setBlockedAppSections(_selectedAppSections);
    AppBlockManager.instance.setBlockReels(_blockReels);
    await AppBlockManager.instance.enableBlocking();
    
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingTime > 0) {
        _remainingTime--;
        _currentSessionElapsedSeconds++;
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
    await _saveSession(completed: true);
    
    _remainingTime = _initialTime;
    notifyListeners();
    // Fire overlay but do not await it so navigation can happen immediately.
    // Completion overlay is designed to show outside the app; the service will
    // itself check whether it's appropriate to show the overlay (e.g. only
    // when the app is backgrounded). We purposely don't await the auto-close
    // to avoid delaying UI navigation.
    CompletionOverlayService.instance
        .showCompletionOverlayWithAutoClose(duration: const Duration(seconds: 10));

    // Trigger any UI callbacks (navigation) immediately so completion screen
    // appears without waiting for overlay work to finish.
    onTimerComplete?.call();
  }

  Future<void> stopTimer() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    
    if (_currentSessionStartTime != null && _currentSessionElapsedSeconds > 0) {
      await _saveSession(completed: false);
    }
    
    _remainingTime = _initialTime;
    await AppBlockManager.instance.disableBlocking();
    notifyListeners();
  }

  /// NEW: Save session to Firestore
  Future<void> _saveSession({required bool completed}) async {
    if (_currentSessionStartTime == null || _currentUserId == null) return;
    
    final session = FocusSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: _currentSessionStartTime!,
      endTime: DateTime.now(),
      plannedDuration: Duration(seconds: _initialTime),
      actualDuration: Duration(seconds: _currentSessionElapsedSeconds),
      completed: completed,
      blockedAppNames: _selectedAppSections.map((s) => s.appName).toList(),
    );
    
    try {
      // Save to Firestore
      await FocusSessionService.instance.saveFocusSession(_currentUserId!, session);
      
      // Add to local list
      _sessionHistory.insert(0, session);
      notifyListeners();
      
      debugPrint("💾 Saved ${completed ? 'completed' : 'incomplete'} session to Firestore");
    } catch (e) {
      debugPrint("❌ Error saving session: $e");
    }
    
    _currentSessionStartTime = null;
    _currentSessionElapsedSeconds = 0;
  }

  Future<void> resetTimer() async {
    _timer?.cancel();
    _isRunning = false;
    _remainingTime = 0;
    _initialTime = 0;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyInitialTime);
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
      
      _remainingTime = 0;
      _initialTime = 0;
      _selectedAppSections.clear();
      _blockReels = false;
      
      // NOTE: Don't clear Firestore history here - add separate method if needed
      
      debugPrint("🗑️ Cleared all saved data");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error clearing data: $e");
    }
  }

  /// NEW: Clear user history from Firestore
  Future<void> clearUserHistory() async {
    if (_currentUserId == null) return;
    
    try {
      await FocusSessionService.instance.deleteAllSessions(_currentUserId!);
      _sessionHistory.clear();
      notifyListeners();
      debugPrint("🗑️ Cleared user history from Firestore");
    } catch (e) {
      debugPrint("❌ Error clearing history: $e");
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
    
    final appCounts = <String, int>{};
    for (var session in sessionsForDate) {
      for (var app in session.blockedAppNames) {
        appCounts[app] = (appCounts[app] ?? 0) + 1;
      }
    }
    
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

  DailyStats get todayStats => getStatsForDate(DateTime.now());

  DailyStats get yesterdayStats => getStatsForDate(
    DateTime.now().subtract(const Duration(days: 1)),
  );

  List<DailyStats> get weekStats {
    final stats = <DailyStats>[];
    final today = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      stats.add(getStatsForDate(date));
    }
    
    return stats;
  }

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

  bool get focusedToday => todayStats.totalMinutes > 0;

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