import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionManager {
  static const String KEY_AUTH_TOKEN = "auth_token";
  static const String KEY_USER_ID = "user_id";
  static const String KEY_DISPLAY_NAME = "display_name";
  static const String KEY_EMAIL = "email";
  static const String KEY_IS_LOGGED_IN = "is_logged_in";
  static const String KEY_IS_ANONYMOUS = "is_anonymous";

  // Save user session data
  static Future<void> saveUserSession(User user, String token, bool getByEmail) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save token from parameters
    await prefs.setString(KEY_AUTH_TOKEN, token);
    
    // Save user ID directly from Firebase user
    await prefs.setString(KEY_USER_ID, user.uid);
    
    // Save email from the parameter (might be null for anonymous users)
    await prefs.setString(KEY_EMAIL, user.email ?? "");
    
    // Set anonymous status
    await prefs.setBool(KEY_IS_ANONYMOUS, user.isAnonymous);
    
    // Set logged in status (true for both regular and anonymous users)
    await prefs.setBool(KEY_IS_LOGGED_IN, true);

    // For non-anonymous users, fetch additional data from API
    if (!user.isAnonymous) {
      String route;
      if (getByEmail) {
        route = "user/email/${user.email ?? ""}";
      } else {
        route = "user/id/${user.uid ?? ""}";
      }

      try {
        // Make the API request and store the response
        final userData = await ApiService.get(route);
        
        // Save display name from response
        if (userData['fullName'] != null) {
          await prefs.setString(KEY_DISPLAY_NAME, userData['fullName']);
        }
        
        // Save any other fields from the response as needed
      } catch (e) {
        print("Error fetching user data: $e");
        // Set a default display name if API call fails
        await prefs.setString(KEY_DISPLAY_NAME, user.displayName ?? "User");
      }
    } else {
      // For anonymous users, set a default display name
      await prefs.setString(KEY_DISPLAY_NAME, "Guest User");
    }
  }

  // Get the auth token
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_AUTH_TOKEN);
  }

  static Future<String?> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_DISPLAY_NAME);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KEY_IS_LOGGED_IN) ?? false;
  }
  
  // Check if user is anonymous
  static Future<bool> isAnonymous() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KEY_IS_ANONYMOUS) ?? false;
  }

  // Clear session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Link anonymous account with email and password
  static Future<bool> linkAnonymousWithEmail(String email, String password) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null && currentUser.isAnonymous) {
        // Create email credential
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password
        );
        
        // Link anonymous account with credential
        UserCredential result = await currentUser.linkWithCredential(credential);
        
        // Update session with the new non-anonymous user
        String? token = await result.user?.getIdToken();
        if (result.user != null && token != null) {
          await saveUserSession(result.user!, token, true);
        }
        
        return true;
      }
      return false;
    } catch (e) {
      print("Error linking anonymous account: $e");
      return false;
    }
  }

  // Sign in anonymous user with existing account
  static Future<bool> signInWithExisting(String email, String password) async {
    try {
      // First sign out the anonymous user
      await FirebaseAuth.instance.signOut();
      
      // Then sign in with the provided credentials
      UserCredential result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save session
      String? token = await result.user?.getIdToken();
      if (result.user != null && token != null) {
        await saveUserSession(result.user!, token, true);
      }
      
      return true;
    } catch (e) {
      print("Error signing in with existing account: $e");
      return false;
    }
  }

  // Refresh token periodically or when needed
  static Future<String?> refreshAuthToken() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Force token refresh
        String? newToken = await currentUser.getIdToken(true);
        if (newToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(KEY_AUTH_TOKEN, newToken);
          return newToken;
        }
      }
      return null;
    } catch (e) {
      print("Error refreshing token: $e");
      return null;
    }
  }

  // Log in anonymously
  static Future<bool> loginAnonymously() async {
    try {
      // Sign in anonymously with Firebase
      UserCredential result = await FirebaseAuth.instance.signInAnonymously();
      
      if (result.user != null) {
        // Get token for the anonymous user
        String? token = await result.user?.getIdToken();
        if (token != null) {
          // Save session data
          await saveUserSession(result.user!, token, false);
          Map<String, dynamic> requestBody = {
            'uid': result.user?.uid
          };
          ApiService.post("user/create-guest", requestBody);

          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error during anonymous login: $e");
      return false;
    }
  }

  // Logout method (now navigates to welcome instead of login)
  static Future<void> logout(BuildContext context) async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // Clear local session data
      await clearSession();
      
      // Navigate to welcome screen
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/welcome', 
        (Route<dynamic> route) => false
      );
    } catch (e) {
      print("Error during logout: $e");
    }
  }
}
