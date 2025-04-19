import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/front_end_helper/curved_clipper.dart';
import 'package:my_app/services/permission_service.dart';
import 'package:my_app/utils/session_manager.dart';
import 'package:my_app/widgets/navigation_drawer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Explicitly initialize all permission-related variables to false
  bool isNotificationsEnabled = false;
  bool isLocationEnabled = false;
  bool isCameraEnabled = false;
  bool isHighContrastEnabled = false;
  bool isReduceMotionEnabled = false;
  bool isSendingToken = false;
  
  // Use the permission service
  final PermissionService _permissionService = PermissionService();
  
  @override
  void initState() {
    super.initState();
    _initServices();
    _checkPermissions();
  }
  
  // Initialize services but don't enable any permissions
  Future<void> _initServices() async {
    // Initialize notifications without automatically requesting permission
    await _permissionService.initializeNotifications();
  }
  
  // Check current permission status without requesting access
  Future<void> _checkPermissions() async {
    // Only check status, don't request permissions
    final notificationsEnabled = await _permissionService.isNotificationPermissionGranted();
    print(notificationsEnabled);
    if(notificationsEnabled==true){
      print("after");
     _sendFCMTokenToBackend();
    }
    final locationEnabled = await _permissionService.isLocationPermissionGranted();
    final cameraEnabled = await _permissionService.isCameraPermissionGranted();
    setState(() {
      isNotificationsEnabled = notificationsEnabled;
      isLocationEnabled = locationEnabled;
      isCameraEnabled=cameraEnabled;
    });
  }
  
  // Send FCM token to backend when user enables notifications
  Future<void> _sendFCMTokenToBackend() async {
  //  if (!isNotificationsEnabled) return;
    
    setState(() {
      isSendingToken = true;
    });
   final prefs = await SharedPreferences.getInstance();
    final success = await _permissionService.sendFCMTokenToBackend(prefs.getString(SessionManager.KEY_USER_ID));
   
    setState(() {
      isSendingToken = false;
    });
   
    // Only show toast if there's an error
    if (!success) {
      Fluttertoast.showToast(
        msg: 'Failed to set up notifications',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
      );
    }
  }
  
  // Direct to system settings for permissions that must be modified there
  void _openSystemSettings() async {
    await _permissionService.openSettings();
  }
  
@override
Widget build(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final languageProvider = Provider.of<LanguageProvider>(context);
  final localizations = AppLocalizations.of(context)!;
  
  // Define the colors to be used throughout
  final Color black = const Color.fromARGB(255, 7, 7, 7);
  final Color redBorder = Color(0xFFBE0000);
  
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Color(0xFFBE0000),
      title: Text(localizations.settings, style: TextStyle(color: Colors.white)),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    drawer: CustomNavigationDrawer(currentRoute: '/settings'),
    body: Stack(
      children: [
        // Top red bar that sits behind everything
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipPath(
            clipper: CurvedBottomClipper(),
            child: Container(
              height: 20,
              color: Color(0xFFBE0000),
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0, top: 30.0),
              ),
            ),
          ),
        ),
        
        // Main content
        SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Section
                _buildSectionHeader(context, localizations.display, redBorder),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: redBorder, width: 1.5),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      localizations.darkMode,
                      style: TextStyle(color: black),
                    ),
                    subtitle: Text(
                      localizations.enableDarkTheme,
                      style: TextStyle(color: black),
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleDarkMode();
                    },
                    activeColor: redBorder,
                  ),
                ),
                SizedBox(height: 16),
                
                // Accessibility Section
                _buildSectionHeader(context, localizations.accessibility, redBorder),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: redBorder, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ListTile(
                          title: Text(
                            localizations.fontSize,
                            style: TextStyle(color: black),
                          ),
                          subtitle: Text(
                            localizations.pixels(themeProvider.fontSize.round()),
                            style: TextStyle(color: black),
                          ),
                          trailing: SizedBox(
                            width: 150,
                            child: Slider(
                              value: themeProvider.fontSize,
                              min: 12,
                              max: 24,
                              divisions: 6,
                              label: themeProvider.fontSize.round().toString(),
                              onChanged: (value) {
                                themeProvider.setFontSize(value);
                              },
                              activeColor: redBorder,
                              thumbColor: redBorder,
                            ),
                          ),
                        ),
                      ),
                      Divider(
                        color: redBorder.withOpacity(0.5),
                        thickness: 1,
                        height: 1,
                      ),
                      SwitchListTile(
                        title: Text(
                          localizations.highContrast,
                          style: TextStyle(color: black),
                        ),
                        subtitle: Text(
                          localizations.increaseContrast,
                          style: TextStyle(color: black),
                        ),
                        value: isHighContrastEnabled,
                        onChanged: (value) {
                          setState(() {
                            isHighContrastEnabled = value;
                            // TODO: Implement high contrast mode
                          });
                        },
                        activeColor: redBorder,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Language Section
                _buildSectionHeader(context, localizations.language, redBorder),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: redBorder, width: 1.5),
                  ),
                  child: ListTile(
                    title: Text(
                      localizations.selectLanguage,
                      style: TextStyle(color: black),
                    ),
                    subtitle: Text(
                      languageProvider.selectedLanguage,
                      style: TextStyle(color: black),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: black),
                    onTap: () {
                      _showLanguageSelector(context, languageProvider);
                    },
                  ),
                ),
                SizedBox(height: 16),
                
                // Privacy Section
                _buildSectionHeader(context, localizations.privacy, redBorder),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: redBorder, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.notifications, color: black),
                        title: Text(
                          localizations.notifications,
                          style: TextStyle(color: black),
                        ),
                        subtitle: Text(
                          isNotificationsEnabled
                              ? localizations.enabledNotifications
                              : localizations.disabledNotifications,
                          style: TextStyle(color: black),
                        ),
                        trailing: Icon(Icons.settings, size: 20, color: black),
                        onTap: _openSystemSettings,
                      ),
                      Divider(
                        color: redBorder.withOpacity(0.5),
                        thickness: 1,
                        height: 1,
                      ),
                      ListTile(
                        leading: Icon(Icons.location_on, color: black),
                        title: Text(
                          localizations.locationServices,
                          style: TextStyle(color: black),
                        ),
                        subtitle: Text(
                          isLocationEnabled
                              ? localizations.enabledLocation
                              : localizations.disabledLocation,
                          style: TextStyle(color: black),
                        ),
                        trailing: Icon(Icons.settings, size: 20, color: black),
                        onTap: _openSystemSettings,
                      ),
                      Divider(
                        color: redBorder.withOpacity(0.5),
                        thickness: 1,
                        height: 1,
                      ),
                      ListTile(
                        leading: Icon(Icons.camera_alt, color: black),
                        title: Text(
                          'Camera',
                          style: TextStyle(color: black),
                        ),
                        subtitle: Text(
                          isCameraEnabled
                              ? 'Camera access is enabled'
                              : 'Camera access is disabled',
                          style: TextStyle(color: black),
                        ),
                        trailing: Icon(Icons.settings, size: 20, color: black),
                        onTap: _openSystemSettings,
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: Text(
                    localizations.permissionsInstructions,
                    style: TextStyle(
                      color: black.withOpacity(0.6),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                
                // Test notification button
               
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// Helper method to create section headers with red color
Widget _buildSectionHeader(BuildContext context, String title, Color redBorder) {
  return Padding(
    padding: const EdgeInsets.only(top: 6.0, bottom: 4.0, left: 8.0),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: redBorder,
      ),
    ),
  );
}

// Method to show language selection dialog
void _showLanguageSelector(
  BuildContext context,
  LanguageProvider languageProvider,
) {
  final localizations = AppLocalizations.of(context)!;
  final Color redBorder = Color(0xFFBE0000);
  final Color black = const Color.fromARGB(255, 7, 7, 7);
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          localizations.selectLanguage,
          style: TextStyle(color: redBorder, fontWeight: FontWeight.bold),
        ),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languageProvider.languagesList.length,
            itemBuilder: (BuildContext context, int index) {
              final language = languageProvider.languagesList[index];
              return RadioListTile<String>(
                title: Text(language, style: TextStyle(color: black)),
                value: language,
                groupValue: languageProvider.selectedLanguage,
                activeColor: redBorder,
                onChanged: (String? value) {
                  if (value != null) {
                    languageProvider.setLanguage(value);
                  }
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: redBorder, width: 1.5),
        ),
        actions: [
          TextButton(
            child: Text(
              localizations.cancel,
              style: TextStyle(color: redBorder),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
}