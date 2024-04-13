import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskwolf_app/settings/base/page.dart';
import 'package:taskwolf_app/settings/theme/theme-state.dart';

class ThemePage extends StatelessWidget {
  ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    var themeState = Provider.of<ThemeState>(context);
    return SettingsPage(name: Locales.string(context, "settings.theme.title"),
      content: Container(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            createThemeButton(Icons.dark_mode, "settings.theme.dark",
              ThemeMode.dark, themeState.getTheme == ThemeMode.dark, themeState,
              context),
            createThemeButton(Icons.light_mode, "settings.theme.light",
              ThemeMode.light, themeState.getTheme == ThemeMode.light, themeState,
              context)
          ],
        )
      )
    );
  }

  createThemeButton(icon, text, theme, selected, themeState, context) {
    return ElevatedButton(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 80,),
          SizedBox(height: 10),
          LocaleText(text, style: TextStyle(fontSize: 25),)
        ],
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: selected ? Colors.blue : Theme.of(context).primaryColor,
        padding: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0))
      ),
      onPressed: () async {
        themeState.setTheme(theme);
        final preferences = await SharedPreferences.getInstance();
        preferences.setString("theme", theme == ThemeMode.light ? "light" :
          "dark");
      },
    );
  }
}