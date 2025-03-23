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
  
  // Save user session data
  static Future<void> saveUserSession(User user, String token) async {
    try {
      debugPrint("Starting to save user session");
      final prefs = await SharedPreferences.getInstance();
      
      // Save basic user data first - this ensures minimal session data is saved
      // even if the API call fails
      await prefs.setString(KEY_AUTH_TOKEN, token);
      await prefs.setString(KEY_EMAIL, user.email ?? "");
      await prefs.setString(KEY_USER_ID, user.uid);
      await prefs.setBool(KEY_IS_LOGGED_IN, true);
      
      // Use display name from Firebase as a fallback
      if (user.displayName != null) {
        await prefs.setString(KEY_DISPLAY_NAME, user.displayName!);
      }
      
      debugPrint("Basic user session saved with UID: ${user.uid}");
      
      // Skip API call for now due to App Check issues
      // Once App Check is properly configured, you can uncomment this section
      
      /*
      try {
        String route = "user/${user.email ?? ""}";
        debugPrint("Fetching additional user data from API at route: $route");
        
        final response = await ApiService.get(route);
        
        // Handle the response safely
        if (response is Map<String, dynamic>) {
          if (response['uid'] != null) {
            await prefs.setString(KEY_USER_ID, response['uid'].toString());
          }
          
          if (response['fullName'] != null) {
            await prefs.setString(KEY_DISPLAY_NAME, response['fullName'].toString());
          }
        } 
        else if (response is List && response.isNotEmpty) {
          final userData = response[0];
          if (userData is Map<String, dynamic>) {
            if (userData['uid'] != null) {
              await prefs.setString(KEY_USER_ID, userData['uid'].toString());
            }
            
            if (userData['fullName'] != null) {
              await prefs.setString(KEY_DISPLAY_NAME, userData['fullName'].toString());
            }
          }
        }
      } catch (apiError) {
        debugPrint("Error fetching user data from API: $apiError");
        // Continue with session - we already saved the basic data
      }
      */
      
      debugPrint("User session saved successfully");
    } catch (e) {
      debugPrint("Critical error saving user session: $e");
      rethrow;
    }
  }

  // Get the auth token
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_AUTH_TOKEN);
  }
  
  static Future<String?> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_DISPLAY_NAME) ?? "User";  // Fallback name
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KEY_IS_LOGGED_IN) ?? false;
  }

  // Clear session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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
      debugPrint("Error refreshing token: $e");
      return null;
    }
  }
  
  // Logout function
  static Future<void> logout(BuildContext context) async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // Clear local session data
      await clearSession();
      
      // Navigate to login screen
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/login', 
        (Route<dynamic> route) => false
      );
    } catch (e) {
      debugPrint("Error during logout: $e");
    }
  }
}