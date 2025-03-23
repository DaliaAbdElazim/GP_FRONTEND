import 'package:flutter/material.dart';
import '../widgets/base_screen.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/services/permission_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<File> _capturedImages = [];
  final int _minImages = 3;
  final int _maxImages = 7;
  final PermissionService _permissionService = PermissionService();
  
  @override
  void initState() {
    super.initState();
    // Check if this is the first launch and show permissions dialog
    _checkFirstLaunch();
  }

  // Check if this is the first app launch
  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    
    if (isFirstLaunch) {
      // Mark as no longer first launch for future app opens
      await prefs.setBool('isFirstLaunch', false);
      
      // Allow UI to load before showing dialog
      Future.delayed(Duration(milliseconds: 500), () {
        _showPermissionsDialog();
      });
    }
  }
  void _showCameraPermissionDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Camera Permission Required'),
        content: Text('To capture photos, you need to grant camera permission in your device settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _permissionService.openSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      );
    },
  );
}
  // Show the permissions dialog on first launch
  void _showPermissionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Welcome to the App!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To provide you with the best experience, we need permission to:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              _buildPermissionItem(
                Icons.notifications, 
                'Notifications', 
                'Get updates on your captured images and processing'
              ),
              SizedBox(height: 8),
              _buildPermissionItem(
                Icons.location_on, 
                'Location', 
                'Add location data to your captured images'
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermissions();
              },
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }
  
  // Helper to build permission items in the dialog
  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Request permissions sequentially
  Future<void> _requestPermissions() async {
    // Request notification permission first
    final notificationGranted = await _permissionService.requestNotificationPermission();
    
    // If notification permission is granted, send FCM token to backend
    if (notificationGranted) {
      await _permissionService.sendFCMTokenToBackend();
    }
    
    // Then request location permission
    await _permissionService.requestLocationPermission();
  }

  // Mock camera functionality since we can't use image_picker
Future<void> _simulateCameraCapture() async {
  if (_capturedImages.length >= _maxImages) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Maximum $_maxImages images allowed')),
    );
    return;
  }

  // Always check permission before capture - this handles "only this time" permissions
  bool hasCameraPermission = await _permissionService.requestCameraPermission();
  
  if (!hasCameraPermission) {
    // Show dialog if permission denied
    _showCameraPermissionDialog();
    return;
  }

  // Continue with camera capture if permission granted
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator()),
  );

  await Future.delayed(Duration(seconds: 1));
  Navigator.pop(context); // Close the loading dialog

  setState(() {
    _capturedImages.add(
      File('simulated_image_${_capturedImages.length}.jpg'),
    );
  });
}


  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  void _confirmImages() {
    if (_capturedImages.length < _minImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please capture at least $_minImages images')),
      );
      return;
    }

    // Navigate to confirmation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ConfirmationScreen(imageCount: _capturedImages.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BaseScreen(
          title: 'Home',
          currentRoute: '/home',
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home, size: 100, color: Colors.blue),
                SizedBox(height: 20),
                Text(
                  'Home Screen',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  'Welcome to the main screen of the application',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
    
                // Image preview grid
                if (_capturedImages.isNotEmpty) ...[
                  Container(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _capturedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: EdgeInsets.all(5),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                                color: Colors.grey[300],
                              ),
                              // Since we can't actually display the file, show a placeholder
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () => _removeImage(index),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${_capturedImages.length} of $_maxImages images (min: $_minImages)',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 20),
                ],
    
                // Camera button
                ElevatedButton.icon(
                  onPressed: _simulateCameraCapture,
                  icon: Icon(Icons.camera_alt),
                  label: Text('Capture Photo'),
                ),
                SizedBox(height: 20),
    
                // Confirm button (only shown when there are images)
                if (_capturedImages.isNotEmpty)
                  ElevatedButton(
                    onPressed: _confirmImages,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text('Confirm Images'),
                  ),
              ],
            ),
          ),
        ),
        
        // Add the Floating Action Button for chatbot
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/chatbot');
            },
            backgroundColor: Colors.blue,
            child: Icon(Icons.chat_bubble, color: Colors.white),
            tooltip: 'Chat Assistant',
          ),
        ),
      ],
    );
  }
}

// Confirmation screen that just shows a success message
class ConfirmationScreen extends StatelessWidget {
  final int imageCount;

  const ConfirmationScreen({Key? key, required this.imageCount})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Confirmed Images')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 20),
            Text(
              '$imageCount images confirmed!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}