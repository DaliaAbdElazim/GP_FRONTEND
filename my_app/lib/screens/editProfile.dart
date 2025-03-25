import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/base_screen.dart';
import '../utils/session_manager.dart';
import '../utils/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user data from SharedPreferences
      String? email = prefs.getString(SessionManager.KEY_EMAIL);
      String? displayName = prefs.getString(SessionManager.KEY_DISPLAY_NAME);
      String? phoneNumber = prefs.getString('phone_number'); // Assuming you'll add this key

      // Set values to controllers
      _emailController.text = email ?? '';
      _fullNameController.text = displayName ?? '';
      _phoneController.text = phoneNumber ?? '';
      
    } catch (e) {
      print("Error loading user data: $e");
      _showMessage('Failed to load profile data');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SessionManager.KEY_DISPLAY_NAME, _fullNameController.text.trim());
      await prefs.setString('phone_number', _phoneController.text.trim());
      
      // Optional: Send updated data to backend
      await _syncWithBackend();
      
      _showMessage('Profile updated successfully');
      Navigator.pop(context, true); // Return true to indicate successful update
    } catch (e) {
      print("Error saving profile data: $e");
      _showMessage('Failed to update profile');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _syncWithBackend() async {
    try {
      // Get email from SharedPreferences to construct the route
      final prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString(SessionManager.KEY_EMAIL);
      String? userId = prefs.getString(SessionManager.KEY_USER_ID);
      
      if (email == null || email.isEmpty || userId == null || userId.isEmpty) {
        throw Exception("Missing user email or ID");
      }
      
      // Prepare the data to send to backend
      Map<String, dynamic> userData = {
        'fullName': _fullNameController.text.trim(),
        'email': email,
        'phoneNumber': _phoneController.text.trim(),
      };
      
      // Send update to backend
      // You can adjust the route and payload as needed
      
      await ApiService.put('user/$userId/update', userData);
      
    } catch (e) {
      print("Error syncing with backend: $e");
      // Don't throw the error - we want to keep the SharedPreferences updates
      // even if the backend sync fails
      _showMessage('Profile saved locally but failed to sync with server');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Edit Profile',
      currentRoute: '/edit-profile',
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: _buildEditForm(context),
              ),
            ),
    );
  }

  Widget _buildEditForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blue.shade100,
            child: Icon(Icons.person, size: 80, color: Colors.blue),
          ),
          SizedBox(height: 30),
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
              enabled: false, // Email is read-only
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Saving...'),
                    ],
                  )
                : Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              minimumSize: Size(double.infinity, 50),
            ),
          ),
          SizedBox(height: 20),
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: Text('Cancel'),
            style: TextButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}
