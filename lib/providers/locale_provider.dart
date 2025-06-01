import 'package:flutter/material.dart';

final List<Locale> supportedLocales = const [
  Locale('en'),
  Locale('si'),
  Locale('my'),
  Locale('hi'), // hindi
  Locale('lo'), // lao
  Locale('th'), // thai
  Locale('km'), // khmr
  Locale('vi'), // vietnamese
  Locale('zh'), // chinese
];

final Map<String, String> languageLabels = {
  'en': 'English',
  'si': 'සිංහල',
  'my': 'မြန်မာ',
  'hi': 'हिन्दी',
  'lo': 'ລາວ',
  'th': 'ไทย',
  'km': 'ខ្មែរ',
  'vi': 'Tiếng Việt',
  'zh': '中文',
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
