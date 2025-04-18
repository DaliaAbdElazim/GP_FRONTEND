import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/front_end_helper/curved_clipper.dart';
import 'package:my_app/widgets/navigation_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/session_manager.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isAnonymous = false;
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool isLoggedIn = await SessionManager.isLoggedIn();
      bool isAnonymous = await SessionManager.isAnonymous();

      if (isLoggedIn) {
        // Get current user from Firebase
        User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          setState(() {
            _isLoggedIn = true;
            _isAnonymous = currentUser.isAnonymous;
            _userEmail = currentUser.email ?? 'No email provided';
            
            if (_isAnonymous) {
              _userName = 'Guest User';
            } else {
              _userName = currentUser.displayName ?? 'User';
              // If display name is not set, try to get name from shared preferences
              if (currentUser.displayName == null) {
                _getUserNameFromPrefs();
              }
            }
          });
        } else {
          // Firebase says no user is logged in, update local session
          await SessionManager.clearSession();
          setState(() {
            _isLoggedIn = false;
            _isAnonymous = false;
          });
        }
      } else {
        setState(() {
          _isLoggedIn = false;
          _isAnonymous = false;
        });
      }
    } catch (e) {
      print("Error checking login status: $e");
      setState(() {
        _isLoggedIn = false;
        _isAnonymous = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getUserNameFromPrefs() async {
    // Try to get name from shared preferences if available
    final prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('display_name');
    if (name != null && name.isNotEmpty) {
      setState(() {
        _userName = name;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );
      
      await SessionManager.logout(context);
      
      // Navigator pop is handled in the SessionManager.logout method
    } catch (e) {
      // Close loading dialog if still showing
      Navigator.of(context, rootNavigator: true).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed. Please try again.')),
      );
      print("Error during logout: $e");
    }
  }

  Future<void> _loginAsGuest(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );
      
      bool success = await SessionManager.loginAnonymously();
      
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      if (success) {
        // Refresh the profile screen
        _checkLoginStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guest login failed. Please try again.')),
        );
      }
    } catch (e) {
      // Close loading dialog if still showing
      Navigator.of(context, rootNavigator: true).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guest login failed. Please try again.')),
      );
      print("Error during guest login: $e");
    }
  }

  // Navigate to login screen for account linking
  void _navigateToLogin(BuildContext context) {
    // Pass a parameter to indicate we're coming from an anonymous account
    Navigator.pushNamed(
      context, 
      '/login',
      arguments: {'fromAnonymous': true},
    );
  }

  // Navigate to registration screen for account creation
  void _navigateToRegistration(BuildContext context) {
    // Pass a parameter to indicate we're coming from an anonymous account
    Navigator.pushNamed(
      context, 
      '/registration',
      arguments: {'fromAnonymous': true},
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Profile', style: TextStyle(color: Colors.white)),
      backgroundColor:Color(0xFFBE0000),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    drawer: CustomNavigationDrawer(currentRoute: '/profile'),
    body: Stack(
      children: [
        // Curved red bar at the top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipPath(
            clipper: CurvedBottomClipper(),
            child: Container(
              height: 20,
              color: Color(0xFFBE0000),
            ),
          ),
        ),
        
        // Main content
        _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Space to push content below the red bar
                SizedBox(height: 30),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.0),
                    child: _isLoggedIn
                      ? (_isAnonymous 
                          ? _buildAnonymousProfile(context)
                          : _buildLoggedInProfile(context))
                      : _buildGuestProfile(context),
                  ),
                ),
              ],
            ),
      ],
    ),
  );
}

  Widget _buildLoggedInProfile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 20),
       CircleAvatar(
          radius: 70, // Optional: controls size
          backgroundColor: Colors.white, // or any color that fits
          child: Image.asset(
            'assets/images/user_icon.png',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 20),
        Text(
          _userName,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(_userEmail, style: TextStyle(fontSize: 16, color: Colors.grey)),
        SizedBox(height: 30),
        ListTile(
          leading: Icon(Icons.edit),
          title: Text('Edit Profile'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Edit profile action
            Navigator.pushNamed(context, '/edit-profile');
          },
        ),
       // Divider(),
        // ListTile(
        //   leading: Icon(Icons.lock),
        //   title: Text('Change Password'),
        //   trailing: Icon(Icons.arrow_forward_ios, size: 16),
        //   onTap: () {
        //     // Change password action
        //     Navigator.pushNamed(context, '/change-password');
        //   },
        // ),
        Divider(),
        SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => _logout(context),
          child: Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            minimumSize: Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildAnonymousProfile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.amber.shade100,
          child: Icon(Icons.person, size: 80, color: Colors.amber),
        ),
        SizedBox(height: 20),
        Text(
          'Guest User',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text('Anonymous account', style: TextStyle(fontSize: 16, color: Colors.grey)),
        SizedBox(height: 30),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                'Create an Account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Sign up to save your progress and access all features.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => _navigateToRegistration(context),
                child: Text('Create Account'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        ListTile(
          leading: Icon(Icons.login),
          title: Text('Log in with existing account'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _navigateToLogin(context),
        ),
        Divider(),
        SizedBox(height: 20),
        Text(
          'You are currently browsing as a guest. Your progress will not be saved between sessions.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 40),
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.shade200,
          child: Icon(Icons.person_outline, size: 80, color: Colors.grey),
        ),
        SizedBox(height: 30),
        Text(
          'Welcome',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'Create an account or continue as guest',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 50),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
          child: Text('Login'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            minimumSize: Size(double.infinity, 50),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/registration');
          },
          child: Text('Register'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            minimumSize: Size(double.infinity, 50),
          ),
        ),
        SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => _loginAsGuest(context),
          child: Text('Continue as Guest'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            minimumSize: Size(double.infinity, 50),
          ),
        ),
        SizedBox(height: 30),
        Text(
          'Sign in to access your personalized profile, save preferences, and more.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}