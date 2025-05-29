import 'package:flutter/material.dart';

final List<Locale> supportedLocales = const [
  Locale('en'),
  Locale('si'),
  Locale('my'),
];

final Map<String, String> languageLabels = {
  'en': 'English',
  'si': 'සිංහල',
  'my': 'မြန်မာ',
};

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void clearLocale() {
    _locale = null;
    notifyListeners();
  }
}
