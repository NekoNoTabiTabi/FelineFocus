import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../service/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  
  User? _user;
  bool _isLoading = true; // START as loading
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  
  String? get userEmail => _user?.email;
  String? get userDisplayName => _user?.displayName;
  String? get userPhotoUrl => _user?.photoURL;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Get initial user state
    _user = _authService.currentUser;
    
    debugPrint("👤 AuthProvider initialized - Current user: ${_user?.email ?? 'None'}");
    
    // Mark as done loading after getting initial state
    _isLoading = false;
    notifyListeners();
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      _isLoading = false; // Always stop loading after state change
      notifyListeners();
      
      if (user != null) {
        debugPrint("👤 User signed in: ${user.email}");
      } else {
        debugPrint("👤 User signed out");
      }
    });
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

    if (result.success) {
      _user = result.user;
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

    if (result.success) {
      _user = result.user;
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

    if (result.success) {
      _user = result.user;
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

    final result = await _authService.deleteAccount();

    if (result.success) {
      _user = null;
      _setLoading(false);
      return true;
    } else {
      _setError(result.errorMessage);
      _setLoading(false);
      return false;
    }
  }

  /// Update display name
  Future<bool> updateDisplayName(String displayName) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.updateDisplayName(displayName);

    if (result.success) {
      _user = _authService.currentUser;
      _setLoading(false);
      return true;
    } else {
      _setError(result.errorMessage);
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