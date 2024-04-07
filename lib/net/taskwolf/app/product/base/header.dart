import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskwolf_app/net/taskwolf/app/login/login.dart';

class ProductHeader extends StatelessWidget implements PreferredSizeWidget {
  ProductHeader({super.key, required this.page});

  final page;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(page),
      backgroundColor: Color(0xFF313131),
      actions: <Widget>[
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle, size: 40),
          onSelected: (value) {
            clickMenuButton(context, value);
          },
          offset: Offset(0, 50),
          color: Color(0xFF545454),
          itemBuilder: (BuildContext context) {
            return [Locales.string(context, "neutral.header.logout")].map((String choice) {
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
    if (value == Locales.string(context, "neutral.header.logout")) {
      final preferences = await SharedPreferences.getInstance();
      preferences.remove("token");
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => LoginPage()));
      return;
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}