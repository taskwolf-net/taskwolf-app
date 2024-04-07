import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskwolf_app/net/taskwolf/app/product/base/page.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: applyUserLanguage(context),
      builder: (context, AsyncSnapshot<String> snapshot) {
        return ProductPage(name: Locales.string(context, "product.home.title"),
          content: Center()
        );
      }
    );
  }

  Future<String> applyUserLanguage(context) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final response = await http.get(
      Uri.parse('https://api.taskwolf.net/v1/settings/language/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    var language = await jsonDecode(response.body)["language"];
    await Locales.change(context, language);
    return language;
  }
}