import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../global/common/toast.dart';

class FirebaseAuthService {
  FirebaseAuth _auth = FirebaseAuth.instance;
  final String? baseUrl;
  
  // Constructor with optional baseUrl parameter
  FirebaseAuthService({this.baseUrl});

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showToast(message: 'The email address is already in use.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
      }
    }
    return null;
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        showToast(message: 'Invalid email or password.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
      }
    }
    return null;
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        showToast(message: 'User not logged in');
        return false;
      }

      if (user.email == null) {
        showToast(message: 'User has no email');
        return false;
      }

      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      showToast(message: 'Password updated successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        showToast(message: 'Current password is incorrect');
      } else if (e.code == 'weak-password') {
        showToast(message: 'The password is too weak');
      } else if (e.code == 'requires-recent-login') {
        showToast(message: 'Please login again before changing your password');
      } else {
        showToast(message: 'Error changing password: ${e.code}');
      }
      return false;
    } catch (e) {
      showToast(message: 'Error changing password: $e');
      return false;
    }
  }

  // Change email
  Future<bool> changeEmail(String currentPassword, String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        showToast(message: 'User not logged in');
        return false;
      }

      if (user.email == null) {
        showToast(message: 'User has no email');
        return false;
      }

      // Re-authenticate user before changing email
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updateEmail(newEmail);
      showToast(message: 'Email updated successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        showToast(message: 'Current password is incorrect');
      } else if (e.code == 'email-already-in-use') {
        showToast(message: 'The email is already in use by another account');
      } else if (e.code == 'invalid-email') {
        showToast(message: 'The email address is not valid');
      } else if (e.code == 'requires-recent-login') {
        showToast(message: 'Please login again before changing your email');
      } else {
        showToast(message: 'Error changing email: ${e.code}');
      }
      return false;
    } catch (e) {
      showToast(message: 'Error changing email: $e');
      return false;
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      showToast(message: 'Password reset email sent');
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showToast(message: 'No user found with this email');
      } else if (e.code == 'invalid-email') {
        showToast(message: 'The email address is not valid');
      } else {
        showToast(message: 'Error sending password reset email: ${e.code}');
      }
      return false;
    } catch (e) {
      showToast(message: 'Error sending password reset email: $e');
      return false;
    }
  }

  // Forgot password - same as sendPasswordResetEmail but named differently
  Future<bool> forgotPassword(String email) async {
    return await sendPasswordResetEmail(email);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get fresh Firebase ID token
  Future<String?> _getIdToken() async {
    return await _auth.currentUser?.getIdToken(true);
  }
  
  // Helper to create authenticated headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }
  
  // GET request
  Future<http.Response> get(String endpoint) async {
    if (baseUrl == null) {
      throw Exception('baseUrl is not defined');
    }
    final headers = await _getAuthHeaders();
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
  }
  
  // POST request
  Future<http.Response> post(String endpoint, {dynamic body}) async {
    if (baseUrl == null) {
      throw Exception('baseUrl is not defined');
    }
    final headers = await _getAuthHeaders();
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }
  
  // PUT request
  Future<http.Response> put(String endpoint, {dynamic body}) async {
    if (baseUrl == null) {
      throw Exception('baseUrl is not defined');
    }
    final headers = await _getAuthHeaders();
    return http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }
  
  // DELETE request
  Future<http.Response> delete(String endpoint) async {
    if (baseUrl == null) {
      throw Exception('baseUrl is not defined');
    }
    final headers = await _getAuthHeaders();
    return http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
  }
}
