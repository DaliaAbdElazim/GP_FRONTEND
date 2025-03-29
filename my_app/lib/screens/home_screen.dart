import 'package:flutter/material.dart';
import 'package:my_app/services/img_upload_service.dart';
import 'package:my_app/utils/session_manager.dart';
import 'package:path_provider/path_provider.dart';
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
  final UploadsService _uploadsService = UploadsService(); // Updated service
  bool _isUploading = false;
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
    Future<File> _createSimulatedImageFile() async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      
      // Create a unique filename
      final uniqueFileName = 'simulated_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File('${tempDir.path}/$uniqueFileName');

      // For demonstration, we'll create a file with some content
      // In a real app, you might want to generate or copy an actual image
      await tempFile.writeAsBytes(List.generate(1024, (index) => index % 256));

      return tempFile;
    } catch (e) {
      print('Error creating simulated image: $e');
      rethrow;
    }
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
    
    // Then request location permission
    final locationGranted =await _permissionService.requestLocationPermission();
    
    if (notificationGranted) {
      final prefs = await SharedPreferences.getInstance();
      await _permissionService.sendFCMTokenToBackend(prefs.getString(SessionManager.KEY_USER_ID));
    }
  }

  // Mock camera functionality since we can't use image_picker
  Future<void> _simulateCameraCapture() async {
    if (_capturedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxImages images allowed')),
      );
      return;
    }

    // Always check permission before capture
    bool hasCameraPermission = await _permissionService.requestCameraPermission();
  
    if (!hasCameraPermission) {
      // Show dialog if permission denied
      _showCameraPermissionDialog();
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // Create a simulated image file
      final simulatedImageFile = await _createSimulatedImageFile();

      // Close loading dialog
      Navigator.pop(context);

      // Update state with the new image file
      setState(() {
        _capturedImages.add(simulatedImageFile);
      });
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

 void _confirmImages() async {
    if (_capturedImages.length < _minImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please capture at least $_minImages images')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(SessionManager.KEY_USER_ID);

      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Get current location
      final location = await _uploadsService.getCurrentLocation();

      // Upload images to backend
      final bool uploadResult = await _uploadsService.uploadImages(
        userId: userId,
        imageFiles: _capturedImages,
        location: location,
        isGuestUpload: false,
      );

      // Navigate to confirmation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationScreen(
            uploadResult: uploadResult,
          ),
        ),
      );

      // Clear captured images after successful upload
      setState(() {
        _capturedImages.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
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
              if (_capturedImages.isNotEmpty && !_isUploading)
                ElevatedButton(
                  onPressed: _confirmImages,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text('Confirm Images'),
                ),

              // Show loading indicator during upload
              if (_isUploading)
                CircularProgressIndicator(),
            ],
          ),
        ),
      ),
      
      // Floating Action Button
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

class ConfirmationScreen extends StatelessWidget {
  final bool uploadResult;

  const ConfirmationScreen({
    Key? key, 
    required this.uploadResult
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(uploadResult);
    final bool isSuccess = true;

    return Scaffold(
      appBar: AppBar(title: Text('Upload Results')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.warning,
              color: isSuccess ? Colors.green : Colors.red, 
              size: 80
            ),
            SizedBox(height: 20),
            Text(
              isSuccess ? 'Upload Successful' : 'Upload Failed',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green : Colors.red
              ),
            ),
            SizedBox(height: 10),
            Text(
              uploadResult.toString(),
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
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
