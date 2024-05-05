import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:taskwolf_app/product/base/header.dart';
import 'package:taskwolf_app/settings/theme/theme-state.dart';
import 'package:taskwolf_app/whitelist_options.dart';

class FileDeleteHistoryPage extends StatelessWidget {
  FileDeleteHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: findDeleteHistory(),
      builder: (context, AsyncSnapshot<dynamic> historySnapshot) {
        var historyEntries = List<Map<String, dynamic>>.from(
          historySnapshot.data ?? []);
        return Scaffold(
          appBar: ProductHeader(page: Locales.string(context, "product.files.delete.history")),
          body: SizedBox(
            child: Center(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: const LocaleText("product.files.delete.history",
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
                        clickDeleteResetButton(context);
                      },
                      child: const LocaleText("product.files.delete.history.reset"),
                    ),
                  ),
                  createDeleteHistory(historyEntries, historySnapshot.data, context),
                ]
              ),
            )
          )
        );
      }
    );
  }

  createDeleteHistory(List<Map<String, dynamic>> history, raw, context) {
    if (raw == null) {
      return Container();
    }
    if (history.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 40),
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: 750,
        child: const LocaleText("product.files.delete.history.empty",
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
            return Card(child: createDeleteHistoryEntry(history[index], isLight,
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

  createDeleteHistoryEntry(entry, isLight, context) {
    return ListTile(
      title: Text(Locales.string(context, "product.files.delete.history.file") +
        ": " + entry["compoundPath"]),
      subtitle: Text(Locales.string(context, "product.files.delete.history.time") +
        ": " + entry["executed"]),
      tileColor: isLight ? Color(0xFFDCDCDC) : Color(0xFF333333),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isLight ? Color(0xFFA9A9A9) : Color(0xFF5D5D5D),
          width: 1),
        borderRadius: BorderRadius.circular(5),
      )
    );
  }

  findDeleteHistory() async {
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
      Uri.parse('https://api.taskwolf.net/v1/device/file/delete/history/'),
      headers: headers,
      body: jsonEncode(<String, String>{
        "device": device
      }),
    );
    return jsonDecode(response.body)["history"];
  }

  clickDeleteResetButton(context) async {
    await resetDeleteHistory();
    Navigator.pop(context);
  }

  resetDeleteHistory() async {
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
      Uri.parse('https://api.taskwolf.net/v1/device/file/delete/history/reset/'),
      headers: headers,
      body: jsonEncode(<String, String>{
        "device": device
      }),
    );
  }
}