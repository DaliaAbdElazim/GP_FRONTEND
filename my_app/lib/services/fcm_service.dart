// lib/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _token;
  
  // Store token in SharedPreferences for persistence
  Future<void> _saveTokenToPrefs(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }
  
  Future<String?> _getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  // Initialize FCM
  Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Get the token
    await getAndUpdateToken();
    
    // Listen for token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _token = newToken;
      _saveTokenToPrefs(newToken);
    });

  }

  // Get current token
  Future<String?> getAndUpdateToken() async {
    try {
      _token = await _firebaseMessaging.getToken();
      if (_token != null) {
        await _saveTokenToPrefs(_token!);
      } else {
        // Try to get from cache if Firebase returns null
        _token = await _getTokenFromPrefs();
      }
      return _token;

    } catch (e) {
      print('Error getting FCM token: $e');
      // Try to get from cache if Firebase throws error
      _token = await _getTokenFromPrefs();
      return _token;
    }
  }

  // Get current token (getter)
  String? get token => _token;

  // Send token to your backend
  Future<bool> sendTokenToBackend(String? token, {String? userId}) async {
    if (token == null) return false;
    
    try {
      // Replace with your actual backend endpoint
      print(userId);
      final response = await http.post(
        Uri.parse('https://cd16-102-44-10-244.ngrok-free.app/active-users'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header if needed
          // 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fcmToken': token,
          'longitude':73.5,
          'latitude':25,
          'id': userId, // Optional, pass user ID if available
        }),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('FCM token sent successfully');
        return true;
      } else {
        print('Failed to send FCM token: ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending FCM token to backend: $e');
      return false;
    }
  }

Future<void> cleanUp() async {
  try {
    // Unregister listeners
    // Note: FirebaseMessaging's onTokenRefresh is an auto-disposing stream,
    // but if you've created any custom listeners or subscriptions, you'd cancel them here
    
    // Clear stored token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
    
    // Reset the token variable
    _token = null;
    
    print('FCM service cleaned up successfully');
  } catch (e) {
    print('Error cleaning up FCM service: $e');
  }
}

Future<bool> removeTokenFromBackend(String token) async {
  try {
    // Replace with your actual backend endpoint for token removal
    final response = await http.delete(
      Uri.parse('https://your-api.com/api/fcm-tokens/$token'),
      headers: {
        'Content-Type': 'application/json',
        // Add authorization header if needed
        // 'Authorization': 'Bearer $authToken',
      },
    );
    
    // Alternative implementation if your API requires a POST/PUT with deletion flag
    /*
    final response = await http.post(
      Uri.parse('https://your-api.com/api/fcm-tokens/delete'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fcm_token': token,
      }),
    );
    */
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('FCM token removed from backend successfully');
      
      // Also clear from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      
      // Reset the token variable if it matches the one being removed
      if (_token == token) {
        _token = null;
      }
      
      return true;
    } else {
      print('Failed to remove FCM token from backend: ${response.statusCode}, ${response.body}');
      return false;
    }
  } catch (e) {
    print('Error removing FCM token from backend: $e');
    return false;
  }
}
}