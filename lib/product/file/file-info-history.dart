import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:dulno_app/product/base/header.dart';
import 'package:dulno_app/request/request.dart';
import 'package:dulno_app/settings/theme/theme-state.dart';

class FileInfoHistoryPage extends StatelessWidget {
  FileInfoHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: findInfoHistory(context),
      builder: (context, AsyncSnapshot<dynamic> historySnapshot) {
        var historyEntries = List<Map<String, dynamic>>.from(
          historySnapshot.data ?? []);
        return Scaffold(
          appBar: ProductHeader(page: Locales.string(context, "product.files.info.history")),
          body: SizedBox(
            child: Center(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: const LocaleText("product.files.info.history",
                      textAlign: TextAlign.center, style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                  ),
                  if (historyEntries.isNotEmpty) Container(
                    margin: EdgeInsets.symmetric(vertical: 20),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2A2A),
                        foregroundColor: const Color(0xFFFFFFFF)),
                      onPressed: () {
                        clickInfoResetButton(context);
                      },
                      child: const LocaleText("product.files.info.history.reset"),
                    ),
                  ),
                  createInfoHistory(historyEntries, historySnapshot.data,
                    context),
                ]
              ),
            )
          )
        );
      }
    );
  }

  createInfoHistory(List<Map<String, dynamic>> history, raw, context) {
    if (raw == null) {
      return Container();
    }
    if (history.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 40),
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: 750,
        child: const LocaleText("product.files.info.history.empty",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),)
      );
    }
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        width: 750,
        child: ListView.separated(
          itemBuilder: (builder, index) {
            return Card(child: createInfoHistoryEntry(history[index], isLight,
              context));
          },
          separatorBuilder: (context, index) => SizedBox(
            height: 20,
          ),
          itemCount: history.length,
        ),
      ),
    );
  }

  createInfoHistoryEntry(entry, isLight, context) {
    return ListTile(
      title: Text(Locales.string(context, "product.files.info.history.file") +
        ": " + entry["compoundPath"]),
      subtitle: Text(Locales.string(context, "product.files.info.history.time") +
        ": " + entry["executed"]),
      tileColor: isLight ? Color(0xFFDCDCDC) : Color(0xFF333333),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isLight ? Color(0xFFA9A9A9) : Color(0xFF5D5D5D),
            width: 1),
        borderRadius: BorderRadius.circular(5),
      )
    );
  }

  findInfoHistory(context) async {
    var response = await Request.post(context: context,
      url: "/device/file/info/history/", devicePreset: true).send();
    return jsonDecode(response.body)["history"];
  }

  clickInfoResetButton(context) async {
    await resetInfoHistory(context);
    Navigator.pop(context);
  }

  resetInfoHistory(context) async {
    await Request.post(context: context, url: "/device/file/info/history/reset/",
      devicePreset: true).send();
  }
}