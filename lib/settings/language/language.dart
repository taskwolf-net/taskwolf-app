import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:taskwolf_app/settings/base/page.dart';
import 'package:taskwolf_app/whitelist_options.dart';

class LanguagePage extends StatelessWidget {
  LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(name: Locales.string(context, "settings.language.title"),
      content: FutureBuilder<String>(
        future: findCurrentLanguage(),
        builder: (context, AsyncSnapshot<String> snapshot) {
          var language = snapshot.data;
          return Container(alignment: Alignment.center,
            child: OverflowBar(
              alignment: MainAxisAlignment.spaceEvenly,
              overflowAlignment: OverflowBarAlignment.center,
              children: [
                createLanguageButton("assets/images/languages/en.png",
                  "settings.language.english", "en", language == "en", context),
                createLanguageButton("assets/images/languages/de.png",
                  "settings.language.german", "de", language == "de", context)
              ],
            )
          );
        }
      )
    );
  }

  createLanguageButton(flag, text, language, selected, context) {
    return Container(
      margin: EdgeInsets.all(20),
      child: ElevatedButton(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              child: Image.asset(flag),
            ),
            SizedBox(height: 10),
            LocaleText(text, style: TextStyle(fontSize: 25),),
          ],
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: selected ? Colors.blue : Theme.of(context).primaryColor,
          padding: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0))
        ),
        onPressed: () async {
          changeLanguage(language);
          await Locales.change(context, language);
          Navigator.pushReplacement(context, PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => LanguagePage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero));
        },
      )
    );
  }

  Future<String> findCurrentLanguage() async {
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
    return await jsonDecode(response.body)["language"];
  }

  changeLanguage(language) async {
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
    await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/language/change/'),
      headers: headers,
      body: jsonEncode(<String, String>{
        "device": device,
        "language": language,
      }),
    );
  }
}