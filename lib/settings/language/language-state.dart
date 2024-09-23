import 'package:flutter/material.dart';

class LanguageState extends ChangeNotifier {
  var language;
  LanguageState(this.language);

  get getLanguage => language;

  void setLanguage(language) {
    this.language = language;
    notifyListeners();
  }
}
