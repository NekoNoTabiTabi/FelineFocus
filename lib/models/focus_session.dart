class FocusSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration plannedDuration;
  final Duration actualDuration;
  final bool completed;
  final List<String> blockedAppNames;

  FocusSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.plannedDuration,
    required this.actualDuration,
    required this.completed,
    required this.blockedAppNames,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'plannedDuration': plannedDuration.inSeconds,
      'actualDuration': actualDuration.inSeconds,
      'completed': completed,
      'blockedAppNames': blockedAppNames,
    };
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime'] as String) 
          : null,
      plannedDuration: Duration(seconds: json['plannedDuration'] as int),
      actualDuration: Duration(seconds: json['actualDuration'] as int),
      completed: json['completed'] as bool,
      blockedAppNames: List<String>.from(json['blockedAppNames'] as List),
    );
  }

  String get durationText {
    final hours = actualDuration.inHours;
    final minutes = actualDuration.inMinutes.remainder(60);
    final seconds = actualDuration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get dateText {
    final now = DateTime.now();
    final difference = now.difference(startTime);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${startTime.month}/${startTime.day}/${startTime.year}';
    }
  }

  String get timeText {
    final hour = startTime.hour;
    final minute = startTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}