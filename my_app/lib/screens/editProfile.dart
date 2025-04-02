import 'package:flutter/material.dart';
import 'package:my_app/firebase_authentication/firebase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/base_screen.dart';
import '../utils/session_manager.dart';
import '../utils/api_service.dart';
 // Import the FirebaseAuthService

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  final FirebaseAuthService _authService = FirebaseAuthService(); // Create instance

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // New controllers for password and email change
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();

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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newEmailController.dispose();
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

  // Change password dialog
Future<void> _showChangePasswordDialog() async {
  _currentPasswordController.clear();
  _newPasswordController.clear();
  _confirmPasswordController.clear();

  final _dialogFormKey = GlobalKey<FormState>();

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {  // Use a separate context
      return AlertDialog(
        title: Text('Change Password'),
        content: SingleChildScrollView(
          child: Form(
            key: _dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          TextButton(
            child: Text('Change'),
            onPressed: () async {
              if (_dialogFormKey.currentState!.validate()) {
                // Close the input dialog first
                Navigator.of(dialogContext).pop();
                
                // After dialog is closed, check if still mounted before proceeding
                if (!mounted) return;
                
                // Show loading dialog using the main context
                bool isLoadingShown = false;
                try {
                  _showLoadingDialog('Changing password...');
                  isLoadingShown = true;
                  
                  bool success = await _authService.changePassword(
                    _currentPasswordController.text,
                    _newPasswordController.text,
                  );
                  
                  // Check mounted status again after async operation
                  if (!mounted) return;
                  
                  // Dismiss loading dialog safely
                  if (isLoadingShown && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                    isLoadingShown = false;
                  }
                  
                  if (success) {
                    _showMessage('Password changed successfully');
                  }
                } catch (e) {
                  // Check mounted status after error
                  if (!mounted) return;
                  
                  // Dismiss loading dialog safely
                  if (isLoadingShown && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                  
                  _showMessage('Failed to change password: ${e.toString()}');
                }
              }
            },
          ),
        ],
      );
    },
  );
}


  // Change email dialog
//  Future<void> _showChangeEmailDialog() async {
//   _currentPasswordController.clear();
//   _newEmailController.clear();
  
//   // Create a dedicated form key for the dialog
//   final _emailDialogFormKey = GlobalKey<FormState>();

//   return showDialog<void>(
//     context: context,
//     barrierDismissible: false,
//     builder: (BuildContext dialogContext) {  // Use a separate context variable
//       return AlertDialog(
//         title: Text('Change Email'),
//         content: SingleChildScrollView(
//           child: Form(
//             key: _emailDialogFormKey,  // Use the dedicated form key
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: <Widget>[
//                 TextFormField(
//                   controller: _currentPasswordController,
//                   decoration: InputDecoration(
//                     labelText: 'Current Password',
//                     border: OutlineInputBorder(),
//                   ),
//                   obscureText: true,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your password';
//                     }
//                     return null;
//                   },
//                 ),
//                 SizedBox(height: 16),
//                 TextFormField(
//                   controller: _newEmailController,
//                   decoration: InputDecoration(
//                     labelText: 'New Email',
//                     border: OutlineInputBorder(),
//                   ),
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a new email';
//                     }
//                     if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//                       return 'Please enter a valid email';
//                     }
//                     return null;
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actions: <Widget>[
//           TextButton(
//             child: Text('Cancel'),
//             onPressed: () {
//               Navigator.of(dialogContext).pop();
//             },
//           ),
//           TextButton(
//             child: Text('Change'),
//             onPressed: () async {
//               // Validate form using the form key
//               if (_emailDialogFormKey.currentState!.validate()) {
//                 try {
//                   Navigator.of(dialogContext).pop(); // Close dialog
                  
//                   // Show loading indicator
//                   _showLoadingDialog('Changing email...');
                  
//                   // Change email using Firebase
//                   bool success = await _authService.changeEmail(
//                     _currentPasswordController.text,
//                     _newEmailController.text,
//                   );
                  
//                   if (success) {
//                     // Update email in SharedPreferences and UI
//                     final prefs = await SharedPreferences.getInstance();
//                     await prefs.setString(SessionManager.KEY_EMAIL, _newEmailController.text);
//                     setState(() {
//                       _emailController.text = _newEmailController.text;
//                     });
                    
//                     // Hide loading indicator and show success message
//                     Navigator.of(context).pop();
//                     _showMessage('Email changed successfully');
//                   } else {
//                     // Hide loading indicator
//                     Navigator.of(context).pop();
//                     _showMessage('Failed to change email');
//                   }
//                 } catch (e) {
//                   // Hide loading indicator if showing
//                   if (Navigator.of(context).canPop()) {
//                     Navigator.of(context).pop();
//                   }
//                   _showMessage('Failed to change email: ${e.toString()}');
//                 }
//               }
//             },
//           ),
//         ],
//       );
//     },
//   );
// }

  // Forgot password / Reset password functionality


  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
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
          // Email field with change button
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    enabled: false, // Email is read-only
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              SizedBox(width: 10),
              // ElevatedButton(
              //   onPressed: _showChangeEmailDialog,
              //   child: Text('Change'),
              //   style: ElevatedButton.styleFrom(
              //     minimumSize: Size(100, 56),
              //   ),
              // ),
            ],
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
          SizedBox(height: 30),
          
          // Password management section
          Divider(),
          SizedBox(height: 10),
          Text(
            'Password Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.lock),
                  label: Text('Change Password'),
                  onPressed: _showChangePasswordDialog,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              SizedBox(width: 10),
              // Expanded(
              //   child: OutlinedButton.icon(
              //     icon: Icon(Icons.password),
              //     label: Text('Reset Password'),
              //     onPressed: _showForgotPasswordDialog,
              //     style: OutlinedButton.styleFrom(
              //       padding: EdgeInsets.symmetric(vertical: 15),
              //     ),
              //   ),
              // ),
            ],
          ),
          SizedBox(height: 40),
          
          // Save/Cancel buttons
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