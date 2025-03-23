import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 16;

  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;

  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  // Custom getter for text themes based on the selected font size
  TextTheme get textTheme {
    final baseTextTheme =
        _isDarkMode ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    // Create a new text theme with adjusted font sizes based on the fontSize setting
    return baseTextTheme.copyWith(
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: _fontSize),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: _fontSize),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: _fontSize - 2),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: _fontSize + 6),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: _fontSize + 2),
      titleSmall: baseTextTheme.titleSmall?.copyWith(fontSize: _fontSize),
    );
  }

  // Customize these themes as needed for your app
  final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    useMaterial3: true,
  );

  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    useMaterial3: true,
  );

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _fontSize = prefs.getDouble('fontSize') ?? 16;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    _savePreferences();
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    _savePreferences();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setDouble('fontSize', _fontSize);
  }
}
