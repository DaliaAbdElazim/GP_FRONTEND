// 2. Create language provider - lib/providers/language_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = Locale('en', 'US');
  String _selectedLanguage = 'English';

  final Map<String, Locale> _supportedLanguages = {
    'English': Locale('en', 'US'),
    'Spanish': Locale('es', 'ES'),
    'French': Locale('fr', 'FR'),
    'German': Locale('de', 'DE'),
    'Arabic': Locale('ar', 'SA'),
    'Chinese': Locale('zh', 'CN'),
  };

  Locale get locale => _locale;
  String get selectedLanguage => _selectedLanguage;
  Map<String, Locale> get supportedLanguages => _supportedLanguages;
  List<String> get languagesList => _supportedLanguages.keys.toList();

  LanguageProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    final languageCode = prefs.getString('languageCode') ?? 'en';
    final countryCode = prefs.getString('countryCode') ?? 'US';
    _locale = Locale(languageCode, countryCode);
    notifyListeners();
  }

  Future<void> setLanguage(String languageName) async {
    if (_supportedLanguages.containsKey(languageName)) {
      _selectedLanguage = languageName;
      _locale = _supportedLanguages[languageName]!;
      _savePreferences();
      notifyListeners();
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', _selectedLanguage);
    await prefs.setString('languageCode', _locale.languageCode);
    await prefs.setString('countryCode', _locale.countryCode ?? '');
  }
}
