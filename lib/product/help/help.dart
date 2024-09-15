import 'package:accordion/accordion.dart';
import 'package:accordion/controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:dulno_app/product/base/page.dart';
import 'package:dulno_app/settings/theme/theme-state.dart';

class HelpPage extends StatelessWidget {
  HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    return ProductPage(name: Locales.string(context, "product.help.title"),
      content: Center(
        child: Container(
          width: 750,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                child: const LocaleText("product.help.frequently.questions",
                  textAlign: TextAlign.center, style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
              ),
              Accordion(
                headerBorderColor: Colors.blueGrey,
                headerBorderColorOpened: Colors.transparent,
                headerBackgroundColor: Colors.blue,
                contentBackgroundColor: isLight ? Color(0xFFE8E8E8) :
                  Color(0xFF121212),
                contentBorderColor: Colors.blue,
                contentBorderWidth: 3,
                contentHorizontalPadding: 20,
                scaleWhenAnimating: true,
                openAndCloseAnimation: true,
                headerPadding:
                const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
                sectionOpeningHapticFeedback: SectionHapticFeedback.heavy,
                sectionClosingHapticFeedback: SectionHapticFeedback.light,
                children: [
                  createAccordionSection("product.help.question.support.question",
                    "product.help.question.support.answer"),
                  createAccordionSection("product.help.question.purpose.question",
                    "product.help.question.purpose.answer"),
                  createAccordionSection("product.help.question.required.question",
                    "product.help.question.required.answer"),
                  createAccordionSection("product.help.question.delete.question",
                      "product.help.question.delete.answer"),
                ]
              )
            ]
          )
        )
      )
    );
  }

  createAccordionSection(question, answer) {
    return AccordionSection(
      isOpen: false,
      contentVerticalPadding: 20,
      header: LocaleText(question),
      content: LocaleText(answer)
    );
  }
}