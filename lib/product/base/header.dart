import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:taskwolf_app/login/login.dart';
import 'package:taskwolf_app/settings/device/device.dart';
import 'package:taskwolf_app/settings/theme/theme-state.dart';

class ProductHeader extends StatelessWidget implements PreferredSizeWidget {
  ProductHeader({super.key, required this.page});

  final page;
  List<String> entries = [];

  @override
  Widget build(BuildContext context) {
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    entries = [Locales.string(context, "neutral.header.settings"),
      Locales.string(context, "neutral.header.logout")];
    return AppBar(
      title: Text(page),
      backgroundColor: isLight ? Color(0xFFFFFFFF) : Color(0xFF313131),
      surfaceTintColor: Colors.transparent,
      actions: <Widget>[
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle, size: 40),
          onSelected: (value) {
            clickMenuButton(context, value);
          },
          offset: Offset(0, 50),
          color: isLight ? Color(0xFFEDEDED) : Color(0xFF545454),
          itemBuilder: (BuildContext context) {
            return entries.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  clickMenuButton(context, value) async {
    if (value == entries[0]) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder:
        (context) => DevicePage()));
    } else if (value == entries[1]) {
      const storage = FlutterSecureStorage();
      await storage.deleteAll();
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => LoginPage()));
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}