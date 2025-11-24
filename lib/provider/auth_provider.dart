import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../service/user_profile_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  final UserProfileService _profileService = UserProfileService.instance;
  
  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  
  String? get userEmail => _user?.email;
  String? get userDisplayName => _userProfile?.displayName ?? _user?.displayName;
  String? get userPhotoUrl => _userProfile?.photoUrl ?? _user?.photoURL;

  AuthProvider() {
    _init();
  }

  void _init() async {
    // Get initial user state
    _user = _authService.currentUser;
    
    // Load user profile from Firestore if user exists
    if (_user != null) {
      await _loadUserProfile(_user!.uid);
    }
    
    debugPrint("👤 AuthProvider initialized - Current user: ${_user?.email ?? 'None'}");
    debugPrint("👤 Display name: ${userDisplayName ?? 'None'}");
    
    // Mark as done loading after getting initial state
    _isLoading = false;
    notifyListeners();
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      
      // Load user profile when user signs in
      if (user != null) {
        await _loadUserProfile(user.uid);
        debugPrint("👤 User signed in: ${user.email}");
        debugPrint("👤 Display name: ${userDisplayName ?? 'None'}");
      } else {
        _userProfile = null;
        debugPrint("👤 User signed out");
      }
      
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile(String uid) async {
    try {
      _userProfile = await _profileService.getUserProfile(uid);
      notifyListeners();
    } catch (e) {
      debugPrint("⚠️ Could not load user profile: $e");
    }
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );

    if (result.success && result.user != null) {
      _user = result.user;
      
      // Create user profile in Firestore
      final profile = UserProfile(
        uid: result.user!.uid,
        email: result.user!.email!,
        displayName: displayName ?? email.split('@')[0],
        photoUrl: null,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      
      try {
        await _profileService.saveUserProfile(profile);
        _userProfile = profile;
        debugPrint("✅ User profile created in Firestore");
      } catch (e) {
        debugPrint("⚠️ Could not save user profile: $e");
      }
      
      _setLoading(false);
      return true;
    } else {
      _setError(result.errorMessage);
      _setLoading(false);
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    if (result.success && result.user != null) {
      _user = result.user;
      await _loadUserProfile(result.user!.uid);
      _setLoading(false);
      return true;
    } else {
      _setError(result.errorMessage);
      _setLoading(false);
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    final result = await _authService.signInWithGoogle();

    if (result.success && result.user != null) {
      _user = result.user;
      
      // Check if profile exists, create if not
      var profile = await _profileService.getUserProfile(result.user!.uid);
      
      if (profile == null) {
        // Create profile for Google sign-in users
        profile = UserProfile(
          uid: result.user!.uid,
          email: result.user!.email!,
          displayName: result.user!.displayName ?? result.user!.email!.split('@')[0],
          photoUrl: result.user!.photoURL,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
        await _profileService.saveUserProfile(profile);
      }
      
      _userProfile = profile;
      _setLoading(false);
      return true;
    } else {
      _setError(result.errorMessage);
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _user = null;
      _userProfile = null;
    } catch (e) {
      _setError('Failed to sign out. Please try again.');
    }

    _setLoading(false);
  }

  /// Reset password
  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.resetPassword(email: email);

    if (result.success) {
      _setLoading(false);
      return true;
    } else {
      _setError(result.errorMessage);
      _setLoading(false);
      return false;
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      // Delete Firestore profile first
      if (_user != null) {
        await _profileService.deleteUserProfile(_user!.uid);
      }
      
      // Then delete auth account
      final result = await _authService.deleteAccount();

      if (result.success) {
        _user = null;
        _userProfile = null;
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete account. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Update display name
  Future<bool> updateDisplayName(String displayName) async {
    if (_user == null) return false;
    
    _setLoading(true);
    _clearError();

    try {
      // Update in Firestore
      await _profileService.updateDisplayName(_user!.uid, displayName);
      
      // Reload profile
      await _loadUserProfile(_user!.uid);
      
      // Try to update in Auth too (might fail due to bug, but that's okay)
      await _authService.updateDisplayName(displayName);
      
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint("❌ Error updating display name: $e");
      _setError('Failed to update display name');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message manually
  void clearError() {
    _clearError();
  }
}