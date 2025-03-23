import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(Locale('en'));
  }

  // Define your string getters
  String get settings => 'Settings';
  String get darkMode => 'Dark Mode';
  String get enableDarkTheme => 'Enable dark theme for the app';
  String get display => 'Display';
  String get accessibility => 'Accessibility';
  String get fontSize => 'Font Size';
  String get highContrast => 'High Contrast';
  String get increaseContrast => 'Increase contrast for better visibility';
  String get reduceMotion => 'Reduce Motion';
  String get minimizeAnimations => 'Minimize animations and motion effects';
  String get language => 'Language';
  String get selectLanguage => 'Select Language';
  String get privacy => 'Privacy';
  String get notifications => 'Notifications';
  String get enableNotifications => 'Enable push notifications';
  String get cookies => 'Cookies';
  String get allowCookies => 'Allow cookies for better experience';
  String get locationServices => 'Location Services';
  String get allowLocation => 'Allow app to access your location';
  String get cancel => 'Cancel';
  String get disableNotificationsMessage => 'To disable notifications, please go to the device settings.';
  String get disableLocationMessage => 'To disable location access, please go to the device settings.';
  String get openSettings => 'Open Settings';



  String get enabledNotifications => 'Notifications are enabled';
  String get disabledNotifications => 'Notifications are disabled';
  String get enabledLocation => 'Location services are enabled';
  String get disabledLocation => 'Location services are disabled';
  String get permissionsInstructions => 'To change permission settings, tap to open system settings';
  String get testNotification => 'Test Notification';
  String pixels(int count) => '$count px';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
