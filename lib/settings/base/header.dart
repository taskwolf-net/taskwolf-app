import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:taskwolf/product/home/home.dart';
import 'package:taskwolf/settings/theme/theme-state.dart';

class ProductHeader extends StatelessWidget implements PreferredSizeWidget {
  ProductHeader({super.key, required this.page});

  final page;

  @override
  Widget build(BuildContext context) {
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    return AppBar(
      title: Text(Locales.string(context, "settings") + " - " + page),
      backgroundColor: isLight ? Color(0xFFFFFFFF) : Color(0xFF313131),
      surfaceTintColor: Colors.transparent,
      actions: <Widget>[
        Container(
          margin: EdgeInsets.only(right: 10),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: IconButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder:
                  (context) => HomePage()));
              },
              icon: const Icon(Icons.close),
            )
          )
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}