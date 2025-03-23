import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/base_screen.dart';
import '../utils/session_manager.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
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

      if (isLoggedIn) {
        // Get current user from Firebase
        User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          setState(() {
            _isLoggedIn = true;
            _userEmail = currentUser.email ?? 'No email provided';
            _userName = currentUser.displayName ?? 'User';

            // If display name is not set, try to get name from shared preferences
            if (currentUser.displayName == null) {
              _getUserNameFromPrefs();
            }
          });
        } else {
          // Firebase says no user is logged in, update local session
          await SessionManager.clearSession();
          setState(() {
            _isLoggedIn = false;
          });
        }
      } else {
        setState(() {
          _isLoggedIn = false;
        });
      }
    } catch (e) {
      print("Error checking login status: $e");
      setState(() {
        _isLoggedIn = false;
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
      await SessionManager.logout(context);
      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to login screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/welcome',
        (Route<dynamic> route) => false,
      );
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

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Profile',
      currentRoute: '/profile',
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: EdgeInsets.all(16.0),
                child:
                    _isLoggedIn
                        ? _buildLoggedInProfile(context)
                        : _buildGuestProfile(context),
              ),
    );
  }

  Widget _buildLoggedInProfile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.person, size: 80, color: Colors.blue),
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
        Divider(),
        ListTile(
          leading: Icon(Icons.lock),
          title: Text('Change Password'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Change password action
            Navigator.pushNamed(context, '/change-password');
          },
        ),
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
          'Guest User',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'Create an account to save your progress',
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
