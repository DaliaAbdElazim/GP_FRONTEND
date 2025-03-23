import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_app/screens/editProfile.dart';
import 'package:my_app/screens/splash_screens.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
//import 'package:firebase_auth/firebase_auth.dart';
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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to do something with background messages
  print("Handling a background message: ${message.messageId}");
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider(
      '6LempvMqAAAAACEX1cFlqcaGsYxEDHWryA8LF2UG',
    ),
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
          },
        );
      },
    );
  }
}
