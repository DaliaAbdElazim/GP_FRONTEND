import 'dart:convert';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_app/screens/editProfile.dart';
import 'package:my_app/screens/notification_collection_screen.dart';
import 'package:my_app/screens/splash_screens.dart';
import 'package:my_app/services/fcm_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';

// Providers
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';

// Localization
import 'l10n/app_localizations.dart';

// Screens
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/support_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/notification_collection_screen.dart' as NF;

class NotificationHandler {
  // Singleton pattern for easy access
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  // Method to open location in Google Maps
  Future<void> openLocationInMaps(double latitude, double longitude) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    
    print("#####################################################");
    print("in the main");
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

  // Method to set up Firebase messaging background handler
  Future<void> setupFirebaseMessaging() async {
    // Handle messages when app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleRemoteMessageTap(message);
    });

    // Optional: Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Background message handler
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print("Handling a background message: ${message.messageId}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Activate Firebase App Check
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider(
      '6LempvMqAAAAACEX1cFlqcaGsYxEDHWryA8LF2UG',
    ),
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );

  // Initialize FCM Service
  final fcmService = FCMService();
  await fcmService.initialize();

  // Initialize NotificationHandler
  final notificationHandler = NotificationHandler();

  // Setup local notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid = 
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
      notificationHandler.handleNotificationResponseTap(notificationResponse);
    },
  );

  // Setup Firebase messaging
  await notificationHandler.setupFirebaseMessaging();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp(
          title: 'My App',
          theme: themeProvider.currentTheme.copyWith(
            textTheme: themeProvider.textTheme,
          ),
          locale: languageProvider.locale,
          localizationsDelegates: [
            const AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: languageProvider.supportedLanguages.values.toList(),
          initialRoute: '/',
          routes: {
            '/': (context) => SplashScreen(),
            '/edit-profile': (context) => EditProfileScreen(),
            '/welcome': (context) => WelcomeScreen(),
            '/login': (context) => LoginScreen(),
            '/registration': (context) => RegistrationScreen(),
            '/home': (context) => HomeScreen(),
            '/profile': (context) => ProfileScreen(),
            '/settings': (context) => SettingsScreen(),
            '/contact': (context) => ContactScreen(),
            '/support': (context) => SupportScreen(),
            '/chatbot': (context) => ChatbotScreen(),
            '/notification': (context) => NotificationsScreen(),
          },
          // Added navigation observer to help with debugging
          navigatorObservers: [
            RouteObserver(),
          ],
        );
      },
    );
  }
}
