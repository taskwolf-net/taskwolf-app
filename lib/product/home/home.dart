import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:taskwolf_app/product/base/page.dart';
import 'package:taskwolf_app/product/command/command.dart';
import 'package:taskwolf_app/product/file/file.dart';
import 'package:taskwolf_app/product/help/help.dart';
import 'package:taskwolf_app/product/notification/notification.dart';
import 'package:taskwolf_app/product/organization/organization.dart';
import 'package:taskwolf_app/whitelist_options.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: applyUserLanguage(context),
      builder: (context, AsyncSnapshot<String> languageSnapshot) {
        return FutureBuilder<String>(
          future: findUsername(context),
          builder: (context, AsyncSnapshot<String> usernameSnapshot) {
            if (usernameSnapshot.data == null) {
              return Container();
            }
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
                            "assets/images/success.gif",
                            height: 400.0,
                            width: 400.0,
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: 40),
                            width: 400,
                            child: const LocaleText("product.home.available",
                              textAlign: TextAlign.center, style: TextStyle(fontSize: 16))
                          ),
                          Divider(),
                          Container(
                            child: Center(
                              child: Wrap(
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
                          )
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

  Future<String> findUsername(context) async {
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

  Future<String> applyUserLanguage(context) async {
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
    final response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/language/find/'),
      headers: headers,
      body: jsonEncode(<String, String>{
        "device": device
      }),
    );
    var language = await jsonDecode(response.body)["language"];
    await Locales.change(context, language);
    return language;
  }
}