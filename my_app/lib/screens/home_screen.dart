import 'package:flutter/material.dart';
import 'package:my_app/services/img_upload_service.dart';
import 'package:my_app/utils/session_manager.dart';
import '../widgets/base_screen.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/services/permission_service.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<File> _selectedImages = [];
  final int _minImages = 3;
  final int _maxImages = 7;
  final PermissionService _permissionService = PermissionService();
  final UploadsService _uploadsService = UploadsService();
  final ImagePicker _imagePicker = ImagePicker();
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

  void _showGalleryPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Gallery Access Required'),
          content: Text('To select photos from your gallery, you need to grant permission to access your photos.'),
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
                Icons.camera_alt,
                'Camera', 
                'Access your camera for taking photos'
              ),
              SizedBox(height: 8),
              _buildPermissionItem(
                Icons.photo_library, 
                'Photos', 
                'Access your photo gallery to select images'
              ),
              SizedBox(height: 8),
              _buildPermissionItem(
                Icons.notifications, 
                'Notifications', 
                'Get updates on your uploaded images and processing'
              ),
              SizedBox(height: 8),
              _buildPermissionItem(
                Icons.location_on, 
                'Location', 
                'Add location data to your uploaded images'
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
    // Request camera permission
    await _permissionService.requestCameraPermission();
    
    // Request gallery access permission
    await _permissionService.requestGalleryPermission();
    
    // Request notification permission
    final notificationGranted = await _permissionService.requestNotificationPermission();
    
    // Request location permission
    final locationGranted = await _permissionService.requestLocationPermission();
    
    if (notificationGranted) {
      final prefs = await SharedPreferences.getInstance();
      await _permissionService.sendFCMTokenToBackend(prefs.getString(SessionManager.KEY_USER_ID));
    }
  }

  // Pick a single image from gallery
  Future<void> _pickSingleImage() async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxImages images allowed')),
      );
      return;
    }

    try {
      // For most cases, we can proceed directly with image_picker
      // It will handle the permission request internally on most devices
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Reduce image size/quality
      );

      if (pickedFile == null) {
        // User canceled or permission denied
        return;
      }
      
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    } on PlatformException catch (e) {
      print(e);
      // This exception might occur if there's a permission issue
      if (e.code == 'photo_access_denied' || e.code == 'permission_denied') {
        _showGalleryPermissionDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Pick multiple images at once from gallery
  Future<void> _pickMultipleImages() async {
    int remainingSlots = _maxImages - _selectedImages.length;
    
    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxImages images already selected')),
      );
      return;
    }

    try {
      // For most cases, we can proceed directly with image_picker
      // It will handle the permission request internally on most devices
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 80, // Reduce image size/quality
      );

      if (pickedFiles.isEmpty) {
        // User canceled or permission denied
        return;
      }
      
      // Only add up to the remaining slots
      final filesToAdd = pickedFiles.length > remainingSlots 
          ? pickedFiles.sublist(0, remainingSlots) 
          : pickedFiles;
          
      setState(() {
        for (var file in filesToAdd) {
          _selectedImages.add(File(file.path));
        }
      });
      
      if (pickedFiles.length > remainingSlots) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only added $remainingSlots of ${pickedFiles.length} selected images (maximum limit)')),
        );
      }
    } on PlatformException catch (e) {
      // This exception might occur if there's a permission issue
      if (e.code == 'photo_access_denied' || e.code == 'permission_denied') {
        _showGalleryPermissionDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _confirmImages() async {
  if (_selectedImages.length < _minImages) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please select at least $_minImages images')),
    );
    return;
  }

  setState(() {
    _isUploading = true;
  });

  try {
    // Show a progress indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Uploading images...'),
              SizedBox(height: 10),
              Text(
                'Please wait while your images are being uploaded',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    // Get user ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(SessionManager.KEY_USER_ID);

    if (userId == null) {
      throw Exception('User ID not found');
    }

    // Get current location with logging
    print('Getting current location...');
    final location = await _uploadsService.getCurrentLocation();
    print('Location obtained - Latitude: ${location.latitude}, Longitude: ${location.longitude}, Valid: ${location.isValid}');

    // Upload images to backend
    final uploadResponse = await _uploadsService.uploadImages(
      userId: userId,
      imageFiles: _selectedImages,
      location: location,
      isGuestUpload: false,
    );

    // Close progress dialog
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    // Navigate to confirmation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmationScreen(
          uploadResult: uploadResponse.success,
          message: uploadResponse.message,
          uploadedCount: _selectedImages.length,
        ),
      ),
    );

    // Clear selected images after successful upload
    if (uploadResponse.success) {
      setState(() {
        _selectedImages.clear();
      });
    }
  } catch (e) {
    // Close progress dialog if it's showing
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    
    print('Upload error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload failed: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
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
                if (_selectedImages.isNotEmpty) ...[
                  Container(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
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
                              ),
                              // Display the actual image
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.file(
                                  _selectedImages[index],
                                  fit: BoxFit.cover,
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
                    '${_selectedImages.length} of $_maxImages images (min: $_minImages)',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 20),
                ],

                // Gallery selection buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickSingleImage,
                      icon: Icon(Icons.photo),
                      label: Text('Add Image'),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _pickMultipleImages,
                      icon: Icon(Icons.photo_library),
                      label: Text('Add Multiple'),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Confirm button (only shown when there are images)
                if (_selectedImages.isNotEmpty && !_isUploading)
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
  final String message;
  final int uploadedCount;

  const ConfirmationScreen({
    Key? key, 
    required this.uploadResult,
    this.message = '',
    this.uploadedCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Results')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                uploadResult ? Icons.check_circle : Icons.error_outline,
                color: uploadResult ? Colors.green : Colors.red, 
                size: 80
              ),
              SizedBox(height: 20),
              Text(
                uploadResult ? 'Upload Successful' : 'Upload Failed',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: uploadResult ? Colors.green : Colors.red
                ),
              ),
              SizedBox(height: 10),
              if (uploadResult)
                Text(
                  'Successfully uploaded $uploadedCount images',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              if (message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    message,
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}