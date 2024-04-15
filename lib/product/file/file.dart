import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:taskwolf_app/product/base/page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FilePage extends StatelessWidget {
  FilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: createFileSettingEntries(),
      builder: (context, AsyncSnapshot<dynamic> settingsSnapshot) {
        var settingsEntries = List<FileSettingEntry>.from(
          settingsSnapshot.data ?? []);
        return ProductPage(name: Locales.string(context, "product.files.title"),
          content: SizedBox(
            child: Center(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: const LocaleText("product.files.settings",
                      textAlign: TextAlign.center, style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    width: 750,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemBuilder: (builder, index) {
                        return ListTile(title: settingsEntries[index]);
                      },
                      itemCount: settingsEntries.length,
                    ),
                  ),
                ]
              ),
            )
          )
        );
      }
    );
  }

  createFileSettingEntries() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    final response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/file/settings/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device
      }),
    );
    final body = jsonDecode(response.body);
    var entries = <FileSettingEntry>[];
    entries.add(FileSettingEntry(title: "product.files.storage",
        state: body["fileStorage"], entries: entries));
    entries.add(FileSettingEntry(title: "product.files.info",
        state: body["fileInfo"], entries: entries));
    return entries;
  }
}

class FileSettingEntry extends StatefulWidget {
  FileSettingEntry({super.key, this.title, required this.state, this.entries});

  final title;
  bool state;
  final entries;

  @override
  State<FileSettingEntry> createState() => FileSettingEntryState(
    entry: this);
}

class FileSettingEntryState extends State<FileSettingEntry> {
  FileSettingEntryState({this.entry});

  final entry;

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Container(
              margin: EdgeInsets.only(right: 20),
              child: new LocaleText(entry.title))),
          Switch(
            value: entry.state,
            thumbColor: MaterialStatePropertyAll<Color>(Theme.of(context).primaryColor),
            activeColor: Colors.blue,
            activeTrackColor: Colors.blue,
            onChanged: (bool value) {
              setState(() {
                entry.state = value;
                updateFileSettings();
              });
            },
          )
        ]
    );
  }

  updateFileSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    var fileStorage = entry.entries[0].state;
    var fileInfo = entry.entries[1].state;
    await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/file/settings/update/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "fileStorage": "$fileStorage",
        "fileInfo": "$fileInfo",
      }),
    );
  }
}