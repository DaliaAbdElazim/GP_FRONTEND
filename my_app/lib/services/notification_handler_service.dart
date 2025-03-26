import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_app/Model/notification_model.dart';
import 'package:my_app/Repository/notification_repository.dart';
import 'package:my_app/firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationHandler {
  // Singleton pattern for easy access
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  final NotificationRepository _notificationRepository = NotificationRepository();

  // FlutterLocalNotificationsPlugin for foreground notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Method to open location in Google Maps
  Future<void> openLocationInMaps(double latitude, double longitude) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
   
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch $url');
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  // Method to handle notification tap from RemoteMessage
  Future<void> handleRemoteMessageTap(RemoteMessage message) async {
    if (message.data.containsKey('latitude') && message.data.containsKey('longitude')) {
      final double latitude = double.tryParse(message.data['latitude']?.toString() ?? '') ?? 0.0;
      final double longitude = double.tryParse(message.data['longitude']?.toString() ?? '') ?? 0.0;
      if (latitude != 0.0 && longitude != 0.0) {
        await openLocationInMaps(latitude, longitude);
      }
    }
  }

  // Method to handle notification tap from NotificationResponse
  Future<void> handleNotificationResponseTap(NotificationResponse notificationResponse) async {
    print('Notification tapped: ${notificationResponse.payload}');
   
    if (notificationResponse.payload == null) return;
    try {
      // Parse payload as JSON
      final Map<String, dynamic> data = json.decode(notificationResponse.payload!);
     
      final double latitude = double.tryParse(data['latitude']?.toString() ?? '') ?? 0.0;
      final double longitude = double.tryParse(data['longitude']?.toString() ?? '') ?? 0.0;
      if (latitude != 0.0 && longitude != 0.0) {
        await openLocationInMaps(latitude, longitude);
      }
    } catch (e) {
      print('Error parsing notification payload: $e');
    }
  }

  // Method to initialize local notifications
  Future<void> initLocalNotifications() async {
    // Android notification details
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS notification details
    // final DarwinInitializationSettings initializationSettingsIOS = 
    //     DarwinInitializationSettings(
    //   onDidReceiveLocalNotification: (id, title, body, payload) async {
    //     // Handle iOS foreground notifications
    //   },
    // );

    // Initialize settings
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    //  iOS: initializationSettingsIOS,
    );

    // Initialize plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: handleNotificationResponseTap,
    );
  }

  // Method to set up Firebase messaging for all scenarios
  Future<void> setupFirebaseMessaging() async {
    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Request notification permissions
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Initialize local notifications
      await initLocalNotifications();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundNotification(message);
      });

      // Handle background/terminated app message opens
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        handleRemoteMessageTap(message);
      });

      // Optional: Get the initial message if the app was terminated
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          handleRemoteMessageTap(message);
        }
      });

      // Optional: Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  }

Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (message.notification != null) {
      String? title = message.notification?.title;
      String? body = message.notification?.body;
      DateTime timestamp = DateTime.now();
      final double latitude = double.tryParse(message.data['latitude']?.toString() ?? '') ?? 0.0;
      final double longitude = double.tryParse(message.data['longitude']?.toString() ?? '') ?? 0.0;

      // Save to local storage
      await _notificationRepository.saveNotification(
        NotificationModel(
          title: title ?? 'No Title',
          body: body ?? 'No Body',
          timestamp: timestamp,
          latitude:latitude ,
          longitude:longitude , id: '',
        ),
      );

      // Show notification locally
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        notificationDetails,
      );
    }
  }
  

  // Background message handler
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print("Handling a background message: ${message.messageId}");
  }
}

