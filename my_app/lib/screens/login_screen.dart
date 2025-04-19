import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/services/api_service.dart';
import 'package:my_app/utils/session_manager.dart';
import 'package:my_app/widgets/navigation_drawer.dart';

class LoginScreen extends StatefulWidget {
  static final String currentRoute = '/login';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _resetEmailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isResettingPassword = false;
  String? _errorMessage;
  String? _resetMessage;
  bool _isFromAnonymous = false;

  @override
  void initState() {
    super.initState();
    // Check if user is already logged in
    _checkLoginStatus();
    
    // Get arguments to check if coming from anonymous profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('fromAnonymous')) {
        setState(() {
          _isFromAnonymous = args['fromAnonymous'] == true;
        });
        debugPrint("Login from anonymous: $_isFromAnonymous");
      }
    });
  }

  Future<void> _checkLoginStatus() async {
    setState(() {
      _isLoading = true;
    });

    bool isLoggedIn = await SessionManager.isLoggedIn();
    bool isAnonymous = await SessionManager.isAnonymous();
    
    if (isLoggedIn && !isAnonymous) {
      // User is already logged in (and not anonymous), redirect to home
      Navigator.pushReplacementNamed(context, '/home');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if we're coming from an anonymous account
      if (_isFromAnonymous) {
        debugPrint("Signing in with existing account from anonymous mode");
        bool success = await SessionManager.signInWithExisting(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        if (success) {
          _isFromAnonymous=false;
          debugPrint("Successfully signed in with existing account. Navigating to home.");
          Navigator.pushReplacementNamed(context, '/home');
          return;
        } else {
          throw Exception("Failed to sign in with existing account");
        }
      }
      
      // Standard login flow
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String? token = await userCredential.user?.getIdToken();

      if (token != null && userCredential.user != null) {
        // Send data to backend
        try {
          await sendUserDataToBackend(token);
        } catch (e) {
          debugPrint("Backend sign-in failed, but continuing: $e");
        }

        // Save the session data
        await SessionManager.saveUserSession(userCredential.user!, token, true);
        
        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Error Code: ${e.code}");
      debugPrint("Firebase Auth Error Message: ${e.message}");
      setState(() {
        _errorMessage = _getMessageFromErrorCode(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Login failed. Please check your credentials.";
      });
      debugPrint("Login error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to provide user-friendly error messages
  String _getMessageFromErrorCode(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'An error occurred: $errorCode';
    }
  }

  Future<void> sendUserDataToBackend(String? token) async {
    try {
      final response = await http.post(
        Uri.parse("https://446d-154-176-127-20.ngrok-free.app/user/sign-in"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 201) {
        debugPrint("User successfully signed in on backend");
      } else {
        debugPrint("Failed to sign in user on backend: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error sending sign-in data to backend: $e");
    }
  }

  // Add the forgot password functionality
  Future<bool> forgotPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true; // Return true on success
    } catch (e) {
      debugPrint("Password reset email error: $e");
      return false; // Return false on failure
    }
  }

  // Show the forgot password dialog
  void _showForgotPasswordDialog() {
    // Pre-fill with the email from the login form if available
    _resetEmailController.text = _emailController.text;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Enter your email address to receive a password reset link.'),
                  SizedBox(height: 16),
                  TextField(
                    controller: _resetEmailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isResettingPassword,
                  ),
                  if (_resetMessage != null) ...[
                    SizedBox(height: 16),
                    Text(
                      _resetMessage!,
                      style: TextStyle(
                        color: _resetMessage!.contains('sent') ? Colors.green : Colors.red,
                      ),
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isResettingPassword ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isResettingPassword ? null : () async {
                    if (_resetEmailController.text.trim().isEmpty) {
                      setDialogState(() {
                        _resetMessage = 'Please enter your email address.';
                      });
                      return;
                    }
                    
                    setDialogState(() {
                      _isResettingPassword = true;
                      _resetMessage = null;
                    });
                    
                    bool success = await forgotPassword(_resetEmailController.text.trim());
                    
                    setDialogState(() {
                      _isResettingPassword = false;
                      if (success) {
                        _resetMessage = 'Password reset email sent. Please check your inbox.';
                      } else {
                        _resetMessage = 'Failed to send password reset email. Please try again.';
                      }
                    });
                    
                    // Close dialog after successful send after a short delay
                    if (success) {
                      Future.delayed(Duration(seconds: 2), () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      });
                    }
                  },
                  child: _isResettingPassword
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Send Reset Link'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isFromAnonymous ? 'Sign in with Existing Account' : 'Login')
      ),
      drawer: CustomNavigationDrawer(currentRoute: LoginScreen.currentRoute),
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Link to Existing Account',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sign in with your existing account to save your current progress.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
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
              if (_errorMessage != null) ...[
                SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                child:
                  _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_isFromAnonymous ? 'Link Account' : 'Login'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context, 
                        '/registration',
                        arguments: _isFromAnonymous ? {'fromAnonymous': true} : null,
                      );
                    },
                    child: Text('Don\'t have an account? Register'),
                  ),
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text('Forgot Password?'),
                  ),
                ],
              ),
              if (_isFromAnonymous) ...[
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Continue as guest'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}