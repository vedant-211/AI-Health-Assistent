import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).user;
});

// Auth result with error handling
class AuthResult {
  final UserCredential? credential;
  final String? error;

  AuthResult({this.credential, this.error});

  bool get isSuccess => credential != null && error == null;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Stream of auth state changes
  Stream<User?> get user => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Helper to parse Firebase Auth errors
  String _getErrorMessage(FirebaseAuthException e) {
    debugPrint('🛑 Raw Firebase Auth Error: [${e.code}] - ${e.message}');
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'operation-not-allowed':
        return 'Sign-up is disabled in Firebase Console. Please enable "Email/Password" in Auth settings.';
      case 'too-many-requests':
        return 'Too many login attempts. Try again later';
      case 'network-request-failed':
        return 'Network error. Attempting to reconnect...';
      case 'project-not-found':
        return 'Firebase project not found. Check your Project ID.';
      case 'api-key-not-valid':
        return 'Invalid API Key. Please verify your .env and Firebase config.';
      default:
        return 'Auth Error (${e.code}): ${e.message ?? "Authentication failed"}';
    }
  }

  Future<AuthResult> _retryWithBackoff(Future<AuthResult> Function() action, {int maxRetries = 2}) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      final result = await action();
      if (result.isSuccess) return result;
      if (result.error != null && !result.error!.contains('Network error')) return result;
      
      retryCount++;
      debugPrint('🔄 Retrying AuthService action (Attempt $retryCount/$maxRetries)...');
      await Future.delayed(Duration(seconds: 2 * retryCount));
    }
    return action();
  }


  // Sign in with email and password
  Future<AuthResult> signIn(String email, String password) async {
    try {
      debugPrint('🏥 Attempting Clinical SignIn for: $email');
      
      // Check if Firebase is ready
      if (Firebase.apps.isEmpty) {
        debugPrint('⚠️ Firebase Apps list is empty during SignIn attempt');
        return AuthResult(error: 'Firebase not initialized. Please refresh the page.');
      }

      return _retryWithBackoff(() async {
        final credential = await _auth
            .signInWithEmailAndPassword(email: email, password: password)
            .timeout(const Duration(seconds: 15)); // Step 5: Timeout
        debugPrint('✅ SignIn successful: ${credential.user?.email}');
        return AuthResult(credential: credential);
      });
    } on FirebaseAuthException catch (e) {
      final errorMsg = _getErrorMessage(e);
      debugPrint('❌ Auth Error (SignIn): ${e.code} - $errorMsg');
      return AuthResult(error: errorMsg);
    } catch (e) {
      debugPrint('❌ Unexpected Auth Error: $e');
      return AuthResult(error: 'Connection error. Please try again or check Firebase settings.');
    }
  }

  // Sign up with email and password
  Future<AuthResult> signUp(String email, String password, {String name = "User"}) async {
    try {
      debugPrint('🔐 Starting Clinical SignUp for: $email');
      
      if (Firebase.apps.isEmpty) {
        debugPrint('⚠️ Firebase Apps list is empty during SignUp attempt');
        return AuthResult(error: 'Firebase not ready. Please refresh the page.');
      }

      return _retryWithBackoff(() async {
        UserCredential credential = await _auth
            .createUserWithEmailAndPassword(email: email, password: password)
            .timeout(const Duration(seconds: 15)); // Step 5: Timeout
        debugPrint('✅ SignUp successful: ${credential.user?.email}');
        
        if (credential.user != null) {
          try {
            // Create user profile in Firestore
            await _firestoreService.createUserProfile(UserModel(
              uid: credential.user!.uid,
              email: email,
              name: name,
              createdAt: DateTime.now(),
            )).timeout(const Duration(seconds: 10)); // Timeout for Firestore too
            debugPrint('✅ User profile created in Firestore');
          } catch (firestoreError) {
            debugPrint('⚠️ Firestore Sync Warning during signup (non-blocking): $firestoreError');
          }
        }
        return AuthResult(credential: credential);
      });
    } on FirebaseAuthException catch (e) {
      final errorMsg = _getErrorMessage(e);
      debugPrint('❌ Auth Error (SignUp): ${e.code} - $errorMsg - ${e.message}');
      
      // Specific log for 'operation-not-allowed' which means Email/Password is disabled
      if (e.code == 'operation-not-allowed') {
        debugPrint('💡 TIP: Enable Email/Password in the Firebase Console (Build > Authentication > Sign-in method)');
      }
      
      return AuthResult(error: errorMsg);
    } catch (e) {
      debugPrint('❌ Unexpected Auth Error during signup: $e');
      
      if (e.toString().contains('MissingPluginException')) {
        return AuthResult(error: 'Firebase Service failed to start. Please restart the application.');
      }
      
      return AuthResult(error: 'Ecosystem synchronization failed. Please check your internet and try again.');
    }
  }


  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

