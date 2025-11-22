import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Initialize and disable App Check for development
  Future<void> initialize() async {
    try {
      // Disable app verification for development
      await _auth.setSettings(
        appVerificationDisabledForTesting: true,
        forceRecaptchaFlow: false,
      );
      debugPrint("✅ Firebase Auth initialized with App Check disabled for development");
    } catch (e) {
      debugPrint("⚠️ Failed to configure Firebase Auth settings: $e");
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Get user email
  String? get userEmail => _auth.currentUser?.email;

  // Get user display name
  String? get userDisplayName => _auth.currentUser?.displayName;

  // Get user photo URL
  String? get userPhotoUrl => _auth.currentUser?.photoURL;

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      debugPrint("🔐 Attempting to sign up with email: $email");
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        await userCredential.user!.reload();
      }

      debugPrint("✅ Sign up successful: ${userCredential.user?.email}");
      return AuthResult(success: true, user: userCredential.user);
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Sign up error: ${e.code} - ${e.message}");
      return AuthResult(
        success: false,
        errorMessage: _getErrorMessage(e.code),
      );
    } catch (e) {
      debugPrint("❌ Unexpected sign up error: $e");
      return AuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint("🔐 Attempting to sign in with email: $email");
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint("✅ Sign in successful: ${userCredential.user?.email}");
      return AuthResult(success: true, user: userCredential.user);
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Sign in error: ${e.code} - ${e.message}");
      return AuthResult(
        success: false,
        errorMessage: _getErrorMessage(e.code),
      );
    } catch (e) {
      debugPrint("❌ Unexpected sign in error: $e");
      return AuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      debugPrint("🔐 Attempting to sign in with Google");
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint("⚠️ Google sign in cancelled by user");
        return AuthResult(
          success: false,
          errorMessage: 'Sign in cancelled',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);

      debugPrint("✅ Google sign in successful: ${userCredential.user?.email}");
      return AuthResult(success: true, user: userCredential.user);
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Google sign in error: ${e.code} - ${e.message}");
      return AuthResult(
        success: false,
        errorMessage: _getErrorMessage(e.code),
      );
    } catch (e) {
      debugPrint("❌ Unexpected Google sign in error: $e");
      return AuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      debugPrint("🔐 Signing out user: ${_auth.currentUser?.email}");
      
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Sign out from Firebase
      await _auth.signOut();
      
      debugPrint("✅ Sign out successful");
    } catch (e) {
      debugPrint("❌ Sign out error: $e");
      rethrow;
    }
  }

  /// Reset password
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      debugPrint("🔐 Sending password reset email to: $email");
      
      await _auth.sendPasswordResetEmail(email: email);
      
      debugPrint("✅ Password reset email sent");
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Password reset error: ${e.code} - ${e.message}");
      return AuthResult(
        success: false,
        errorMessage: _getErrorMessage(e.code),
      );
    } catch (e) {
      debugPrint("❌ Unexpected password reset error: $e");
      return AuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Delete user account
  Future<AuthResult> deleteAccount() async {
    try {
      debugPrint("🔐 Deleting user account: ${_auth.currentUser?.email}");
      
      await _auth.currentUser?.delete();
      
      debugPrint("✅ Account deleted successfully");
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Account deletion error: ${e.code} - ${e.message}");
      return AuthResult(
        success: false,
        errorMessage: _getErrorMessage(e.code),
      );
    } catch (e) {
      debugPrint("❌ Unexpected account deletion error: $e");
      return AuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Update display name
  Future<AuthResult> updateDisplayName(String displayName) async {
    try {
      debugPrint("🔐 Updating display name to: $displayName");
      
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.reload();
      
      debugPrint("✅ Display name updated");
      return AuthResult(success: true);
    } catch (e) {
      debugPrint("❌ Display name update error: $e");
      return AuthResult(
        success: false,
        errorMessage: 'Failed to update display name',
      );
    }
  }

  /// Get user-friendly error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool success;
  final User? user;
  final String? errorMessage;

  AuthResult({
    required this.success,
    this.user,
    this.errorMessage,
  });
}