class DailyStats {
  final DateTime date;
  final int totalMinutes;
  final int sessionsCompleted;
  final int sessionsStarted;
  final List<String> mostBlockedApps;

  DailyStats({
    required this.date,
    required this.totalMinutes,
    required this.sessionsCompleted,
    required this.sessionsStarted,
    required this.mostBlockedApps,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalMinutes': totalMinutes,
      'sessionsCompleted': sessionsCompleted,
      'sessionsStarted': sessionsStarted,
      'mostBlockedApps': mostBlockedApps,
    };
  }

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: DateTime.parse(json['date'] as String),
      totalMinutes: json['totalMinutes'] as int,
      sessionsCompleted: json['sessionsCompleted'] as int,
      sessionsStarted: json['sessionsStarted'] as int,
      mostBlockedApps: List<String>.from(json['mostBlockedApps'] as List),
    );
  }

  String get dateText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisDate = DateTime(date.year, date.month, date.day);
    
    if (thisDate == today) {
      return 'Today';
    } else if (thisDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  String get timeText {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  double get completionRate {
    if (sessionsStarted == 0) return 0.0;
    return sessionsCompleted / sessionsStarted;
  }

  String get completionRateText {
    return '${(completionRate * 100).toInt()}%';
  }
}