import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:taskwolf_app/product/base/page.dart';
import 'package:taskwolf_app/product/command/command.dart';
import 'package:taskwolf_app/product/file/file.dart';
import 'package:taskwolf_app/product/help/help.dart';
import 'package:taskwolf_app/product/notification/notification.dart';
import 'package:taskwolf_app/product/organization/organization.dart';
import 'package:taskwolf_app/settings/theme/theme-state.dart';
import 'package:taskwolf_app/whitelist_options.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: findUsername(context),
      builder: (context, AsyncSnapshot<dynamic> usernameSnapshot) {
        return FutureBuilder<dynamic>(
          future: findFileActivity(),
          builder: (context, AsyncSnapshot<dynamic> fileSnapshot) {
            return ProductPage(name: Locales.string(context, "product.home.title"),
              content: SingleChildScrollView(
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.9,
                    child: Container(
                      child: Column(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              Locales.string(context, "product.home.welcome") +
                                (usernameSnapshot.data ?? ""),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                          ),
                          Image.asset(
                            "assets/images/logo.png",
                            height: 256.0,
                            width: 256.0,
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 20),
                            width: 400,
                            child: const LocaleText("product.home.available",
                              textAlign: TextAlign.center, style: TextStyle(fontSize: 16))
                          ),
                          Divider(),
                          Container(
                            child: Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  createPageButton("product.home.title", HomePage(),
                                    Icons.home, context),
                                  createPageButton("product.organizations.title", OrganizationPage(),
                                    Icons.groups, context),
                                  createPageButton("product.notifications.title", NotificationPage(),
                                    Icons.notifications, context),
                                  createPageButton("product.files.title", FilePage(),
                                    Icons.file_copy_sharp, context),
                                  createPageButton("product.commands.title", CommandPage(),
                                    Icons.terminal, context),
                                  createPageButton("product.help.title", HelpPage(),
                                    Icons.help, context),
                                ],
                              )
                            )
                          ),
                          Divider(),
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 20),
                            child: LocaleText("product.home.file.activity",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                          ),
                          createFileActivity(List<Map<String, dynamic>>.from(fileSnapshot.data ?? []),
                            fileSnapshot.data, context)
                        ]
                      )
                    )
                  )
                )
              )
            );
          }
        );
      }
    );
  }

  createFileActivity(activity, raw, context) {
    if (raw == null) {
      return Container();
    }
    if (activity.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 40),
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: 750,
        child: const LocaleText("product.home.file.activity.empty",
          textAlign: TextAlign.center, style: TextStyle(fontSize: 15))
      );
    }
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        width: 750,
        child: ListView.separated(
          itemBuilder: (builder, index) {
            return Card(child: createFileActivityEntry(activity[index], isLight,
              context));
          },
          separatorBuilder: (context, index) => SizedBox(
            height: 20,
          ),
          itemCount: activity.length,
        ),
      ),
    );
  }

  createFileActivityEntry(entry, isLight, context) {
    return ListTile(
      title: Text(Locales.string(context, "product.files.storage.history.file") +
        ": " + entry["compoundPath"]),
      subtitle: Text(Locales.string(context, "product.files.storage.history.time") +
        ": " + entry["executed"]),
      tileColor: isLight ? Color(0xFFDCDCDC) : Color(0xFF333333),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isLight ? Color(0xFFA9A9A9) : Color(0xFF5D5D5D),
          width: 1),
        borderRadius: BorderRadius.circular(5),
      )
    );
  }

  findFileActivity() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    final device = await storage.read(key: "device") ?? "";
    var headers = <String, String>{
      'Authorization': "Bearer " + token,
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (WhitelistOptions.whitelistEnabled) {
      headers["WHITELIST-KEY"] = WhitelistOptions.whitelistKey;
    }
    var body = jsonEncode(<String, String>{"device": device});
    var entries = [];
    var storageEntry = await findFileHistoryEntry("storage", headers, body);
    if (storageEntry != null) {
      entries.add(storageEntry);
    }
    var deleteEntry = await findFileHistoryEntry("delete", headers, body);
    if (deleteEntry != null) {
      entries.add(deleteEntry);
    }
    var infoEntry = await findFileHistoryEntry("info", headers, body);
    if (infoEntry != null) {
      entries.add(infoEntry);
    }
    return entries;
  }

  findFileHistoryEntry(type, headers, body) async {
    var response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/file/' + type + '/history/'),
      headers: headers,
      body: body
    );
    var entries = jsonDecode(response.body)["history"];
    if (entries.length > 0) {
      var entry = entries[0];
      entry["type"] = type;
      return entry;
    }
    return null;
  }

  createPageButton(text, page, icon, context) {
    return Container(
      margin: EdgeInsets.all(20),
      child: ElevatedButton(
        child: Container(
          width: 256,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 80,),
              SizedBox(height: 10),
              LocaleText(text, style: TextStyle(fontSize: 25),)
            ],
          )
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          padding: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0))
        ),
        onPressed: () async {
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => page));
        },
      )
    );
  }

  findUsername(context) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    var headers = <String, String>{
      'Authorization': "Bearer " + token,
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (WhitelistOptions.whitelistEnabled) {
      headers["WHITELIST-KEY"] = WhitelistOptions.whitelistKey;
    }
    final response = await http.get(
      Uri.parse('https://api.taskwolf.net/v1/settings/profile/username/'),
      headers: headers
    );
    return await jsonDecode(response.body)["username"];
  }
}