import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/focus_session.dart';

class FocusSessionService {
  FocusSessionService._();
  static final FocusSessionService instance = FocusSessionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get reference to user's sessions collection
  CollectionReference _getUserSessionsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('focus_sessions');
  }

  /// Save a focus session
  Future<void> saveFocusSession(String uid, FocusSession session) async {
    try {
      debugPrint("💾 Saving focus session for user: $uid");
      
      await _getUserSessionsCollection(uid)
          .doc(session.id)
          .set(session.toJson());
      
      debugPrint("✅ Focus session saved");
    } catch (e) {
      debugPrint("❌ Error saving focus session: $e");
      rethrow;
    }
  }

  /// Get all focus sessions for a user
  Future<List<FocusSession>> getFocusSessions(String uid) async {
    try {
      debugPrint("📖 Fetching focus sessions for user: $uid");
      
      final snapshot = await _getUserSessionsCollection(uid)
          .orderBy('startTime', descending: true)
          .get();
      
      final sessions = snapshot.docs
          .map((doc) => FocusSession.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      debugPrint("✅ Loaded ${sessions.length} focus sessions");
      return sessions;
    } catch (e) {
      debugPrint("❌ Error fetching focus sessions: $e");
      return [];
    }
  }

  /// Get focus sessions for a specific date range
  Future<List<FocusSession>> getFocusSessionsInRange(
    String uid,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      debugPrint("📖 Fetching sessions from $startDate to $endDate");
      
      final snapshot = await _getUserSessionsCollection(uid)
          .where('startTime', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('startTime', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('startTime', descending: true)
          .get();
      
      final sessions = snapshot.docs
          .map((doc) => FocusSession.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      debugPrint("✅ Loaded ${sessions.length} sessions in range");
      return sessions;
    } catch (e) {
      debugPrint("❌ Error fetching sessions in range: $e");
      return [];
    }
  }

  /// Get today's focus sessions
  Future<List<FocusSession>> getTodaysSessions(String uid) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return getFocusSessionsInRange(uid, startOfDay, endOfDay);
  }

  /// Get this week's focus sessions
  Future<List<FocusSession>> getWeekSessions(String uid) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: 6));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return getFocusSessionsInRange(uid, startDate, endDate);
  }

  /// Delete a focus session
  Future<void> deleteFocusSession(String uid, String sessionId) async {
    try {
      debugPrint("🗑️ Deleting focus session: $sessionId");
      
      await _getUserSessionsCollection(uid).doc(sessionId).delete();
      
      debugPrint("✅ Focus session deleted");
    } catch (e) {
      debugPrint("❌ Error deleting focus session: $e");
      rethrow;
    }
  }

  /// Delete all focus sessions for a user
  Future<void> deleteAllSessions(String uid) async {
    try {
      debugPrint("🗑️ Deleting all focus sessions for user: $uid");
      
      final snapshot = await _getUserSessionsCollection(uid).get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      debugPrint("✅ All focus sessions deleted");
    } catch (e) {
      debugPrint("❌ Error deleting all sessions: $e");
      rethrow;
    }
  }

  /// Stream of focus sessions (real-time updates)
  Stream<List<FocusSession>> streamFocusSessions(String uid) {
    return _getUserSessionsCollection(uid)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FocusSession.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }
}