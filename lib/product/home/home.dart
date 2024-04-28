import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:taskwolf_app/product/home/desktop-home.dart';
import 'package:taskwolf_app/product/home/mobile-home.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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
    final response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/language/find/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device
      }),
    );
    var language = await jsonDecode(response.body)["language"];
    await Locales.change(context, language);
    return language;
  }
}