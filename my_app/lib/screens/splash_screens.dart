import 'package:flutter/material.dart';
import 'package:my_app/utils/session_manager.dart';
//import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Add a short delay for splash screen
    await Future.delayed(Duration(seconds: 2));

    // Check if user is logged in
    bool isLoggedIn = await SessionManager.isLoggedIn();

    if (isLoggedIn) {
      // If logged in, verify and refresh the token
      String? token = await SessionManager.refreshAuthToken();

      if (token != null) {
        // Valid session, go to home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Session expired, go to login
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // Not logged in, go to login screen
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo here
            FlutterLogo(size: 100),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
