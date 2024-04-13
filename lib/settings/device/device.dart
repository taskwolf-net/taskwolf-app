import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:taskwolf_app/settings/base/page.dart';

class DevicePage extends StatelessWidget {
  DevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(name: Locales.string(context, "settings.device.title"),
      content: Center());
  }
}