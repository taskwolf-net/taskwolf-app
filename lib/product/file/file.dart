import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:dulno/product/base/page.dart';
import 'package:dulno/product/file/file-history.dart';
import 'package:dulno/product/file/file-workspace.dart';
import 'package:dulno/request/request.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FilePage extends StatelessWidget {
  FilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: createFileSettingEntries(context),
      builder: (context, AsyncSnapshot<dynamic> settingsSnapshot) {
        var settingsEntries = List<FileSettingEntry>.from(
          settingsSnapshot.data ?? []);
        return ProductPage(name: Locales.string(context, "product.files.title"),
          content: SingleChildScrollView(
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
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: const LocaleText("product.files.options",
                      textAlign: TextAlign.center, style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                  ),
                  OverflowBar(
                    alignment: MainAxisAlignment.spaceEvenly,
                    overflowAlignment: OverflowBarAlignment.center,
                    children: [
                      createFileButton(Icons.folder, "product.files.workspaces",
                        FileWorkspacePage(), context),
                      createFileButton(Icons.history, "product.files.history",
                        FileHistoryPage(), context),
                    ],
                  )
                ]
              ),
            )
          )
        );
      }
    );
  }

  createFileButton(icon, text, page, context) {
    return Container(
      margin: EdgeInsets.all(20),
      child: ElevatedButton(
        child: Container(
          width: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 80,),
              SizedBox(height: 10),
              LocaleText(text, style: TextStyle(fontSize: 25),)
            ],
          )
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          padding: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0))
        ),
        onPressed: () async {
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => page));
        },
      )
    );
  }

  createFileSettingEntries(context) async {
    var response = await Request.post(context: context,
      url: "/device/file/settings/", devicePreset: true).send();
    final body = jsonDecode(response.body);
    var entries = <FileSettingEntry>[];
    entries.add(FileSettingEntry(title: "product.files.storage",
      state: body["fileStorage"], entries: entries));
    entries.add(FileSettingEntry(title: "product.files.info",
      state: body["fileInfo"], entries: entries));
    entries.add(FileSettingEntry(title: "product.files.delete",
      state: body["fileDelete"], entries: entries));
    entries.add(FileSettingEntry(title: "product.files.folder.create",
      state: body["folderCreate"], entries: entries));
    entries.add(FileSettingEntry(title: "product.files.folder.delete",
      state: body["folderDelete"], entries: entries));
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
    var fileStorage = entry.entries[0].state;
    var fileInfo = entry.entries[1].state;
    var fileDelete = entry.entries[2].state;
    var folderCreate = entry.entries[3].state;
    var folderDelete = entry.entries[4].state;
    const storage = FlutterSecureStorage();
    await storage.write(key: "fileStorage", value: "$fileStorage");
    await storage.write(key: "fileInfo", value: "$fileInfo");
    await storage.write(key: "fileDelete", value: "$fileDelete");
    await storage.write(key: "folderCreate", value: "$folderCreate");
    await storage.write(key: "folderDelete", value: "$folderDelete");
    var body = <String, String> {
      "fileStorage": "$fileStorage",
      "fileInfo": "$fileInfo",
      "fileDelete": "$fileDelete",
      "folderCreate": "$folderCreate",
      "folderDelete": "$folderDelete",
    };
    await Request.post(context: context, url: "/device/file/settings/update/",
      body: body, devicePreset: true).send();
  }
}