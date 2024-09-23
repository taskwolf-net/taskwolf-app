import 'package:flutter/material.dart';

class ThemeState extends ChangeNotifier {
  ThemeMode state;
  ThemeState(this.state);

  get getTheme => state;

  void setTheme(ThemeMode theme) {
    state = theme;
    notifyListeners();
  }
}
