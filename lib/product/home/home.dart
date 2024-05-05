import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:taskwolf_app/product/home/desktop-home.dart';
import 'package:taskwolf_app/product/home/mobile-home.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:taskwolf_app/whitelist_options.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: applyUserLanguage(context),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          return DesktopHomePage();
        }
        return MobileHomePage();
      }
    );
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