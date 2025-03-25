// lib/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/Model/notification_model.dart';
import 'package:my_app/Repository/notification_repository.dart';
import 'package:url_launcher/url_launcher.dart';
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here
  print("Handling a background message: ${message.messageId}");
  
  // Optional: You can add logic to show a local notification
  // even when the app is in the background
  FlutterLocalNotificationsPlugin().show(
    message.hashCode,
    message.notification?.title,
    message.notification?.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel', // Use a consistent channel ID
        'High Importance Notifications',
        importance: Importance.high,
      ),
    ),
  );
}
class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final NotificationRepository _notificationRepository = NotificationRepository();
  String? _token;
  Position? _currentLocation;

  // Enhanced initialization method
  Future<void> initialize() async {
    // Request notification permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Check permission status
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permissions');
    } else {
      print('User declined or has not accepted notification permissions');
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidInitializationSettings = 
      AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitializationSettings = 
      DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle tap on notification
        _handleNotificationTap(details as RemoteMessage);
      },
    );

    // Setup background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Get and update token
    await getAndUpdateToken();

    // Setup foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      
      // Show local notification for foreground messages
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Handle when app is opened from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleInitialMessage(message);
      }
    });

    // Listen for token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _token = newToken;
      _saveTokenToPrefs(newToken);
    });
  }

  // Show local notification
  void _showLocalNotification(RemoteMessage message) {
    
    _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.high,
        ),
      ),
    );
    // Save notification to repository
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().toIso8601String(),
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      timestamp: DateTime.now(),
      additionalData: message.data,
    );

    _notificationRepository.saveNotification(notification);
  }
  void _openLocationInMaps(double latitude, double longitude) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }

    void _handleNotificationTap(RemoteMessage message) {
    if (message.data.containsKey('latitude') && message.data.containsKey('longitude')) {
      final double latitude = double.tryParse(message.data['latitude'] ?? '') ?? 0.0;
      final double longitude = double.tryParse(message.data['longitude'] ?? '') ?? 0.0;

      if (latitude != 0.0 && longitude != 0.0) {
        _openLocationInMaps(latitude, longitude);
      }
    }
    }
  // void navigateToNotifications(BuildContext context) {
  //   Navigator.of(context).pushNamed('/notification');
  // }
  // Handle initial message when app is opened from terminated state
  void _handleInitialMessage(RemoteMessage message) {
    print('App opened from terminated state with message: ${message.data}');
    // Implement any specific logic for initial message
  }
  

  // Store token in SharedPreferences for persistence
  Future<void> _saveTokenToPrefs(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  Future<String?> _getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  Future<Position?> getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // If permissions are granted, get current position
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _currentLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        return _currentLocation;
      }

      print('Location permissions not granted');
      return null;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
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
  Future<bool> sendTokenWithLocation({String? userId}) async {
    try {
      // Get FCM token
      String? token = await getAndUpdateToken();
      if (token == null) {
        print('FCM token is null');
        return false;
      }

      // Get current location
      Position? position = await getCurrentLocation();

      // Prepare location data (use default if location not available)
      double latitude = position?.latitude ?? 0.0;
      double longitude = position?.longitude ?? 0.0;
      print("######################################");
      print(token);
      print(longitude);
      print(latitude);
      print(userId);
      print("######################################");
      final response = await http.post(
        Uri.parse(
          'https://58ae-41-238-165-43.ngrok-free.app/active-users/update-location',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcmToken': token,
          'longitude': longitude,
          'latitude': latitude,
          'id': userId,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('FCM token and location sent successfully');
        return true;
      } else {
        print(
          'Failed to send FCM token and location: ${response.statusCode}, ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error sending FCM token and location: $e');
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
        print(
          'Failed to remove FCM token from backend: ${response.statusCode}, ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error removing FCM token from backend: $e');
      return false;
    }
  }
}
