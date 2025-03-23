import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'fcm_service.dart';

class PermissionService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final FCMService _fcmService = FCMService();
  bool _notificationsInitialized = false;
 
// Add camera permission methods
// Add to PermissionService.dart
Future<bool> isCameraPermissionGranted() async {
  return await Permission.camera.isGranted || await Permission.camera.isLimited;
}

Future<bool> requestCameraPermission() async {
  var status = await Permission.camera.request();
  return status.isGranted || status.isLimited;
}
  // Initialize services
Future<bool> initializeNotifications() async {
  try {
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
   
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
   
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
   
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );
   
    // Initialize FCM - don't try to capture the return value
    await _fcmService.initialize();
    
    _notificationsInitialized = true;
    return true;
  } catch (e) {
    print('Error initializing notifications: $e');
    _notificationsInitialized = false;
    return false;
  }
}
 
  // Request notification permission
  Future<bool> requestNotificationPermission() async {
    var status = await Permission.notification.request();
    return status.isGranted || status.isLimited ;
  }
 
  // Check if notification permission is granted
  Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted || await Permission.notification.isLimited;

  }
 
  // Request location permission
  Future<bool> requestLocationPermission() async {
    var status = await Permission.location.request();
    return status.isGranted || status.isLimited;
  }
 
  // Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    return await Permission.location.isGranted ||await Permission.location.isLimited;
  }
 
  // Open app settings
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
 
  // Show a test notification
  Future<bool> showTestNotification() async {
    try {
      if (!_notificationsInitialized) {
        return false;
      }
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Channel for test notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
     
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();
     
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
     
      await _notificationsPlugin.show(
        0,
        'Test Notification',
        'This is a test notification from your app',
        platformChannelSpecifics,
      );
      
      return true;
    } catch (e) {
      print('Error showing test notification: $e');
      return false;
    }
  }
 
  // Get FCM token
  Future<String?> getFCMToken() async {
    return await _fcmService.getAndUpdateToken();
  }
 
  // Send FCM token to backend
  Future<bool> sendFCMTokenToBackend({String? userId}) async {
    try {
      final token = await getFCMToken();
      
      if (token == null) {
        print('Failed to get FCM token');
        return false;
      }
      print(token);
      return await _fcmService.sendTokenToBackend(token, userId: userId);
    } catch (e) {
      print('Error sending FCM token to backend: $e');
      return false;
    }
  }
  
  // // Clean up resources
  Future<void> dispose() async {
    // Clean up any listeners or resources
    await _fcmService.cleanUp();
  }
  
  // Unregister FCM token
  Future<bool> unregisterFCMToken() async {
    try {
      final token = await getFCMToken();
      if (token == null) return false;
      
      return await _fcmService.removeTokenFromBackend(token);
    } catch (e) {
      print('Error unregistering FCM token: $e');
      return false;
    }
  }
}