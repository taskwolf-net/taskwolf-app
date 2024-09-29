import 'package:dulno/settings/theme/theme-state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:dulno/settings/data-volume/data-volume.dart';
import 'package:dulno/settings/device/device.dart';
import 'package:dulno/settings/language/language.dart';
import 'package:dulno/settings/theme/theme.dart';
import 'package:provider/provider.dart';

class ProductSidebar extends StatelessWidget {
  ProductSidebar({super.key, required this.page});

  final page;

  @override
  Widget build(BuildContext context) {
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              SizedBox(
                width: 100,
                child: Image.asset("assets/images/logo-${isLight ? "dark" : "light"}.webp"),
              ),
              const SizedBox(height: 20),
            ],
          ),
          createSidebarEntry("settings.device.title", DevicePage(), Icons.devices_sharp, context),
          createSidebarEntry("settings.language.title", LanguagePage(), Icons.language, context),
          createSidebarEntry("settings.theme.title", ThemePage(), Icons.brush, context),
          createSidebarEntry("settings.data.volume.title", DataVolumePage(), Icons.wifi_rounded, context),
        ],
      ),
    );
  }

  bool equalsIgnoreCase(String? string1, String? string2) {
    return string1?.toLowerCase() == string2?.toLowerCase();
  }

  Widget createSidebarEntry(title, page, icon, context) {
    return ListTile(
      title: LocaleText(title),
      selected: this.page == page,
      leading: Icon(icon),
      onTap: () {
        clickSidebarEntry(title, page, context);
      },
    );
  }

  clickSidebarEntry(title, page, context) {
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (context) => page));
  }
}