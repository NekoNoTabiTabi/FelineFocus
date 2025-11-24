import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastUpdated;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

class UserProfileService {
  UserProfileService._();
  static final UserProfileService instance = UserProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create or update user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      debugPrint("💾 Saving user profile for: ${profile.email}");
      
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toJson(), SetOptions(merge: true));
      
      debugPrint("✅ User profile saved");
    } catch (e) {
      debugPrint("❌ Error saving user profile: $e");
      rethrow;
    }
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      debugPrint("📖 Fetching user profile for: $uid");
      
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        debugPrint("⚠️ User profile not found");
        return null;
      }
      
      final profile = UserProfile.fromJson(doc.data()!);
      debugPrint("✅ User profile loaded: ${profile.displayName}");
      return profile;
    } catch (e) {
      debugPrint("❌ Error fetching user profile: $e");
      return null;
    }
  }

  /// Update display name
  Future<void> updateDisplayName(String uid, String displayName) async {
    try {
      debugPrint("📝 Updating display name for: $uid");
      
      await _firestore.collection('users').doc(uid).update({
        'displayName': displayName,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      
      debugPrint("✅ Display name updated");
    } catch (e) {
      debugPrint("❌ Error updating display name: $e");
      rethrow;
    }
  }

  /// Update photo URL
  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'photoUrl': photoUrl,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("❌ Error updating photo URL: $e");
      rethrow;
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    try {
      debugPrint("🗑️ Deleting user profile: $uid");
      await _firestore.collection('users').doc(uid).delete();
      debugPrint("✅ User profile deleted");
    } catch (e) {
      debugPrint("❌ Error deleting user profile: $e");
      rethrow;
    }
  }
}