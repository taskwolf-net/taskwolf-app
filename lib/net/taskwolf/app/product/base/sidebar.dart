import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:taskwolf_app/net/taskwolf/app/product/organization/organization.dart';
import 'package:taskwolf_app/net/taskwolf/app/product/file/file.dart';
import 'package:taskwolf_app/net/taskwolf/app/product/help/help.dart';
import 'package:taskwolf_app/net/taskwolf/app/product/home/home.dart';
import 'package:taskwolf_app/net/taskwolf/app/product/notification/notification.dart';

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
                  child: Image.network('https://taskwolf.net/static/img/logo.png'),
                ),
                Text("Taskwolf"),
              ],
            ),
          ),
          createSidebarEntry("product.home.title", HomePage(), Icons.home, context),
          createSidebarEntry("product.organizations.title", OrganizationPage(), Icons.groups, context),
          createSidebarEntry("product.notifications.title", NotificationPage(), Icons.notifications, context),
          createSidebarEntry("product.files.title", FilePage(), Icons.file_copy_sharp, context),
          createSidebarEntry("product.help.title", HelpPage(), Icons.help, context),
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