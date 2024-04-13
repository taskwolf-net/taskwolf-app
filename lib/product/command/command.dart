import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:taskwolf_app/product/base/page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CommandPage extends StatelessWidget {
  CommandPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: createCommandSettingEntries(),
      builder: (context, AsyncSnapshot<dynamic> settingsSnapshot) {
        return FutureBuilder<dynamic>(
          future: findCommandHistory(),
          builder: (context, AsyncSnapshot<dynamic> historySnapshot) {
            var settingsEntries = List<CommandSettingEntry>.from(
              settingsSnapshot.data ?? []);
            return ProductPage(name: Locales.string(context, "product.commands.title"),
              content: SizedBox(
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 20),
                        child: const LocaleText("product.commands.settings",
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
                        child: const LocaleText("product.commands.history",
                          textAlign: TextAlign.center, style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                      ),
                      createCommandHistory(List<Map<String, dynamic>>.from(
                        historySnapshot.data ?? []), historySnapshot.data, context),
                    ]
                  ),
                )
              )
            );
          }
        );
      }
    );
  }


  createCommandHistory(List<Map<String, dynamic>> history, raw, context) {
    if (raw == null) {
      return Container();
    }
    if (history.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 40),
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: 750,
        child: const LocaleText("product.commands.history.empty",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),)
      );
    }
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        width: 750,
        child: ListView.separated(
          itemBuilder: (builder, index) {
            return Card(child: createCommandHistoryEntry(history[index], context));
          },
          separatorBuilder: (context, index) => SizedBox(
            height: 20,
          ),
          itemCount: history.length,
        ),
      ),
    );
  }

  createCommandHistoryEntry(command, context) {
    var exitCode = command["exitCode"];
    return ListTile(
      title: Text(Locales.string(context, "product.commands.history.command") +
        ": \"" + command["command"] + "\""),
      subtitle: Text(Locales.string(context, "product.commands.history.output") +
        ": \"" + command["output"] + command["errorMessage"] + "\"\n" +
        Locales.string(context, "product.commands.history.exit.code") + ": $exitCode"),
      tileColor: Color(0xFF333333),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Color(0xFF5D5D5D), width: 1),
        borderRadius: BorderRadius.circular(5),
      )
    );
  }

  findCommandHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    final response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/command/history/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device
      }),
    );
    return jsonDecode(response.body)["history"];
  }

  createCommandSettingEntries() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    final response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/command/settings/'),
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
    var entries = <CommandSettingEntry>[];
    entries.add(CommandSettingEntry(title: "product.commands.enabled",
      state: body["commandExecution"], entries: entries));
    return entries;
  }
}

class CommandSettingEntry extends StatefulWidget {
  CommandSettingEntry({super.key, this.title, required this.state, this.entries});

  final title;
  bool state;
  final entries;

  @override
  State<CommandSettingEntry> createState() => CommandSettingEntryState(
    entry: this);
}

class CommandSettingEntryState extends State<CommandSettingEntry> {
  CommandSettingEntryState({this.entry});

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
          thumbColor: const MaterialStatePropertyAll<Color>(Colors.white),
          onChanged: (bool value) {
            setState(() {
              entry.state = value;
              updateCommandSettings();
            });
          },
        )
      ]
    );
  }

  updateCommandSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    var commandExecution = entry.entries[0].state;
    await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/command/settings/update/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "commandExecution": "$commandExecution",
      }),
    );
  }
}
