import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/widgets/navigation_drawer.dart';
import 'package:my_app/utils/session_manager.dart';

class RegistrationScreen extends StatefulWidget {
  static const String currentRoute = '/registration';

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint("RegistrationScreen initialized");
  }

  Future<void> sendUserDataToBackend(
    String uid,
    String email,
    String name,
    String token,
  ) async {
    debugPrint("Attempting to send user data to backend");
    try {
      final response = await http.post(
        Uri.parse("https://cd16-102-44-10-244.ngrok-free.app/user/sign-up"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"uid": uid, "email": email, "fullName": name}),
      );

      debugPrint("Backend response status: ${response.statusCode}");
      
      if (response.statusCode == 201) {
        debugPrint("User successfully registered in backend");
      } else {
        debugPrint("Backend registration failed: ${response.body}");
        // Don't throw an exception here - we'll continue with Firebase auth only
      }
    } catch (e) {
      debugPrint("Exception during backend registration: $e");
      // Don't rethrow - we'll continue with Firebase auth only
    }
  }

  Future<void> _register() async {
    print("Register button pressed");
    
    // Validate inputs
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Please enter your name.";
      });
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Please enter your email.";
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a password.";
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Passwords do not match.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint("Attempting Firebase authentication");
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // if (userCredential.user == null) {
      //   debugPrint("⚠️ User creation failed! Check Firebase settings.");
      //   throw Exception("User creation returned null user");
      // }

      // String uid = userCredential.user!.uid;
      // String email = userCredential.user!.email!;
      // String name = _nameController.text.trim();
      
      // debugPrint("User created with UID: $uid");
      // debugPrint("Requesting ID token");
      
      // String? token = await userCredential.user?.getIdToken();
      
      // if (token != null) {
      //   debugPrint("Token received successfully");
        
        // Save basic user session first
        // try {
        // //  await SessionManager.saveUserSession(userCredential.user!, token);
        //   debugPrint("User session saved successfully");
        // } catch (sessionError) {
        //   debugPrint("Error saving session, but continuing: $sessionError");
        //   // Continue anyway since Firebase auth was successful
        // }
        
        // // Try to send data to backend but don't fail if it doesn't work
        // try {
        //   await sendUserDataToBackend(uid, email, name, token);
        // } catch (backendError) {
        //   debugPrint("Backend registration failed, but continuing: $backendError");
        //   // Continue anyway since Firebase auth was successful
        // }
        
        debugPrint("Registration completed. Navigating to home screen.");
        
        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      // } else {
      //   throw Exception("Failed to get ID token");
      // }
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Error Code: ${e.code}");
      debugPrint("Firebase Auth Error Message: ${e.message}");
      setState(() {
        _errorMessage = _getMessageFromErrorCode(e.code);
      });
    } catch (e) {
      debugPrint("Registration error: $e");
      setState(() {
        // Show the error message without trying to truncate it
        _errorMessage = "Registration failed: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to provide user-friendly error messages
  String _getMessageFromErrorCode(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'An error occurred: $errorCode';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registration')),
      drawer: CustomNavigationDrawer(
        currentRoute: RegistrationScreen.currentRoute,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('Register'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}