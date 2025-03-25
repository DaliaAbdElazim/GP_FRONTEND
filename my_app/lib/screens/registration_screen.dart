import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/utils/api_service.dart';
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
  bool _isFromAnonymous = false;

  @override
  void initState() {
    super.initState();
    debugPrint("RegistrationScreen initialized");
    
    // Get arguments to check if coming from anonymous profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('fromAnonymous')) {
        setState(() {
          _isFromAnonymous = args['fromAnonymous'] == true;
        });
        debugPrint("Registration from anonymous: $_isFromAnonymous");
      }
    });
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
        Uri.parse("https://58ae-41-238-165-43.ngrok-free.app/user/sign-up"),
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
      // Check if we're converting an anonymous account
      if (_isFromAnonymous) {
        debugPrint("Attempting to link anonymous account with email");
        bool success = await SessionManager.linkAnonymousWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim()
        );
        
        if (success) {
          // Update the user's display name
          User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await currentUser.updateDisplayName(_nameController.text.trim());
            
            // Get the token for backend registration
            String? token = await currentUser.getIdToken();
            if (token != null) {
              try {
                Map<String, dynamic> requestBody = {
                  'uid': currentUser.uid,
                  'email': _emailController.text.trim(), 
                  'fullName':_nameController.text.trim(), 
                };
                ApiService.post("user/upgrade-guest", requestBody);
              
              } catch (e) {
                debugPrint("Backend registration failed, but continuing: $e");
              }
            }
          }
          _isFromAnonymous=false;
          debugPrint("Anonymous account successfully linked. Navigating to home.");
          Navigator.pushReplacementNamed(context, '/home');
          return;
        } else {
          // If linking fails, we'll fall back to regular registration
          debugPrint("Failed to link anonymous account, falling back to standard registration");
          setState(() {
            _errorMessage = "Unable to link your guest account. Creating a new account instead.";
          });
        }
      }
      
      // Standard registration flow
      debugPrint("Attempting Firebase authentication");
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user == null) {
        debugPrint("⚠️ User creation failed! Check Firebase settings.");
        throw Exception("User creation returned null user");
      }

      // Update display name
      await userCredential.user!.updateDisplayName(_nameController.text.trim());

      String uid = userCredential.user!.uid;
      String email = userCredential.user!.email!;
      String name = _nameController.text.trim();
      
      debugPrint("User created with UID: $uid");
      debugPrint("Requesting ID token");
      
      String? token = await userCredential.user?.getIdToken();
      
      if (token != null) {
        debugPrint("Token received successfully");
        
        // Save user session
        try {
          await SessionManager.saveUserSession(userCredential.user!, token, true);
          debugPrint("User session saved successfully");
        } catch (sessionError) {
          debugPrint("Error saving session, but continuing: $sessionError");
          // Continue anyway since Firebase auth was successful
        }
        
        // Try to send data to backend but don't fail if it doesn't work
        try {
          await sendUserDataToBackend(uid, email, name, token);
        } catch (backendError) {
          debugPrint("Backend registration failed, but continuing: $backendError");
          // Continue anyway since Firebase auth was successful
        }
        
        debugPrint("Registration completed. Navigating to home screen.");
        
        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        throw Exception("Failed to get ID token");
      }
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
      appBar: AppBar(
        title: Text(_isFromAnonymous ? 'Create Account' : 'Registration'),
      ),
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
              if (_isFromAnonymous) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Convert Guest Account',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Create an account to save your progress and data.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
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
                    : Text(_isFromAnonymous ? 'Create Account' : 'Register'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context, 
                    '/login',
                    arguments: _isFromAnonymous ? {'fromAnonymous': true} : null,
                  );
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
