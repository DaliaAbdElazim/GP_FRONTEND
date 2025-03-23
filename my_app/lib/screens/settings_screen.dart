import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/base_screen.dart';
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
   
    final success = await _permissionService.sendFCMTokenToBackend();
   
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
    
    return BaseScreen(
      title: localizations.settings,
      currentRoute: '/settings',
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          // 1. Dark Mode Section
          _buildSectionHeader(localizations.display),
          SwitchListTile(
            title: Text(localizations.darkMode),
            subtitle: Text(localizations.enableDarkTheme),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleDarkMode();
            },
          ),
          Divider(),
          
          // 2. Accessibility Section
          _buildSectionHeader(localizations.accessibility),
          ListTile(
            title: Text(localizations.fontSize),
            subtitle: Text(
              localizations.pixels(themeProvider.fontSize.round()),
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
              ),
            ),
          ),
          
          // Additional accessibility options
          SwitchListTile(
            title: Text(localizations.highContrast),
            subtitle: Text(localizations.increaseContrast),
            value: isHighContrastEnabled,
            onChanged: (value) {
              setState(() {
                isHighContrastEnabled = value;
                // TODO: Implement high contrast mode
              });
            },
          ),
          Divider(),
          
          // 3. Language Section
          _buildSectionHeader(localizations.language),
          ListTile(
            title: Text(localizations.selectLanguage),
            subtitle: Text(languageProvider.selectedLanguage),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showLanguageSelector(context, languageProvider);
            },
          ),
          Divider(),
          
          // 4. Privacy Section - Modified to show current status and link to system settings
          _buildSectionHeader(localizations.privacy),
          
          // Modified Notifications ListTile
          ListTile(
            title: Text(localizations.notifications),
            subtitle: Text(
              isNotificationsEnabled 
                ? localizations.enabledNotifications 
                : localizations.disabledNotifications
            ),
            trailing: Icon(Icons.settings, size: 20),
            onTap: _openSystemSettings,
          ),
          
          // Modified Location ListTile
          ListTile(
            title: Text(localizations.locationServices),
            subtitle: Text(
              isLocationEnabled 
                ? localizations.enabledLocation 
                : localizations.disabledLocation
            ),
            trailing: Icon(Icons.settings, size: 20),
            onTap: _openSystemSettings,
          ),
          ListTile(
            title: Text('Camera'),
            subtitle: Text(
              isCameraEnabled 
                ? 'Camera access is enabled' 
                : 'Camera access is disabled'
            ),
            trailing: Icon(Icons.settings, size: 20),
            onTap: _openSystemSettings,
          ),
          // Show info text about changing permissions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              localizations.permissionsInstructions,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          
          // Add a test notification button only if notifications are enabled
          if (isNotificationsEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: !isSendingToken
                    ? () => _permissionService.showTestNotification()
                    : null,
                  icon: isSendingToken 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.notifications),
                  label: Text('Test Notification'),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Helper method to create section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
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
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.selectLanguage),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languageProvider.languagesList.length,
              itemBuilder: (BuildContext context, int index) {
                final language = languageProvider.languagesList[index];
                return RadioListTile<String>(
                  title: Text(language),
                  value: language,
                  groupValue: languageProvider.selectedLanguage,
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
          actions: [
            TextButton(
              child: Text(localizations.cancel),
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