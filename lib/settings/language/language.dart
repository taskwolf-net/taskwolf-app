import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:dulno/settings/base/page.dart';
import 'package:dulno/settings/language/language-state.dart';

class LanguagePage extends StatelessWidget {
  LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    var languageState = Provider.of<LanguageState>(context);
    return SettingsPage(name: Locales.string(context, "settings.language.title"),
      content: Container(alignment: Alignment.center,
        child: OverflowBar(
          alignment: MainAxisAlignment.spaceEvenly,
          overflowAlignment: OverflowBarAlignment.center,
          children: [
            createLanguageButton(languageState, "assets/images/languages/en.webp",
              "settings.language.english", "en", languageState.getLanguage == "en", context),
            createLanguageButton(languageState, "assets/images/languages/de.webp",
              "settings.language.german", "de", languageState.getLanguage == "de", context)
          ],
        )
      )
    );
  }

  createLanguageButton(languageState, flag, text, language, selected, context) {
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
          changeLanguage(languageState, language);
          await Locales.change(context, language);
          Navigator.pushReplacement(context, PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => LanguagePage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero));
        },
      )
    );
  }

  changeLanguage(languageState, language) async {
    languageState.setLanguage(language);
    const storage = FlutterSecureStorage();
    await storage.write(key: "language", value: language);
  }
}