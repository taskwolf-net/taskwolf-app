import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:taskwolf_app/settings/data-volume/data-volume.dart';
import 'package:taskwolf_app/settings/device/device.dart';
import 'package:taskwolf_app/settings/language/language.dart';
import 'package:taskwolf_app/settings/theme/theme.dart';

class ProductSidebar extends StatelessWidget {
  ProductSidebar({super.key, required this.page});

  final page;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0x33FFFFFF),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 100,
                  child: Image.asset("assets/images/logo.png"),
                ),
                Text("Taskwolf"),
              ],
            ),
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