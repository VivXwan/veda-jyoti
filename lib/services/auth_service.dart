import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('An account with this email already exists.');
        case 'weak-password':
          throw Exception('The password is too weak.');
        case 'invalid-email':
          throw Exception('The email address is invalid.');
        default:
          throw Exception('Failed to create account: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'wrong-password':
          throw Exception('Incorrect password.');
        case 'invalid-email':
          throw Exception('The email address is invalid.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        default:
          throw Exception('Failed to sign in: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      // For now, we'll use Firebase's built-in password reset
      // Later, this can be modified to use the backend endpoint
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'invalid-email':
          throw Exception('The email address is invalid.');
        default:
          throw Exception('Failed to send reset email: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<void> sendPasswordResetEmailViaBackend({required String email}) async {
    try {
      // This is for future integration with the backend endpoint
      const String backendUrl = 'YOUR_BACKEND_URL/users/send-password-reset-email';
      
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send password reset email');
      }
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
    }
  }
}