import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:taskwolf_app/settings/base/page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
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
    return await jsonDecode(response.body)["language"];
  }

  changeLanguage(language) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/language/change/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "language": language,
      }),
    );
  }
}