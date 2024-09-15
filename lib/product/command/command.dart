import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:dulno_app/product/base/page.dart';
import 'package:dulno_app/request/request.dart';
import 'package:dulno_app/settings/theme/theme-state.dart';

class CommandPage extends StatelessWidget {
  CommandPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: createCommandSettingEntries(context),
      builder: (context, AsyncSnapshot<dynamic> settingsSnapshot) {
        return FutureBuilder<dynamic>(
          future: findCommandHistory(context),
          builder: (context, AsyncSnapshot<dynamic> historySnapshot) {
            var settingsEntries = List<CommandSettingEntry>.from(
              settingsSnapshot.data ?? []);
            var historyEntries = List<Map<String, dynamic>>.from(
                historySnapshot.data ?? []);
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
                      if (historyEntries.isNotEmpty) Container(
                        margin: EdgeInsets.symmetric(vertical: 20),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF2A2A),
                            foregroundColor: const Color(0xFFFFFFFF)),
                          onPressed: () {
                            clickCommandResetButton(context);
                          },
                          child: const LocaleText("product.commands.history.reset"),
                        ),
                      ),
                      createCommandHistory(historyEntries, historySnapshot.data,
                        context),
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
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        width: 750,
        child: ListView.separated(
          itemBuilder: (builder, index) {
            return Card(child: createCommandHistoryEntry(history[index], isLight,
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

  createCommandHistoryEntry(command, isLight, context) {
    var exitCode = command["exitCode"];
    return ListTile(
      title: Text(Locales.string(context, "product.commands.history.command") +
        ": \"" + command["command"] + "\""),
      subtitle: Text(Locales.string(context, "product.commands.history.output") +
        ": \"" + command["output"] + command["errorMessage"] + "\"\n" +
        Locales.string(context, "product.commands.history.exit.code") + ": $exitCode"),
      tileColor: isLight ? Color(0xFFDCDCDC) : Color(0xFF333333),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isLight ? Color(0xFFA9A9A9) : Color(0xFF5D5D5D),
            width: 1),
        borderRadius: BorderRadius.circular(5),
      )
    );
  }

  findCommandHistory(context) async {
    var response = await Request.post(context: context,
      url: "/device/command/history/", devicePreset: true).send();
    return jsonDecode(response.body)["history"];
  }

  createCommandSettingEntries(context) async {
    var response = await Request.post(context: context,
      url: "/device/command/settings/", devicePreset: true).send();
    final body = jsonDecode(response.body);
    var entries = <CommandSettingEntry>[];
    entries.add(CommandSettingEntry(title: "product.commands.enabled",
      state: body["commandExecution"], entries: entries));
    return entries;
  }

  clickCommandResetButton(context) async {
    await resetCommandHistory(context);
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (context, animation1, animation2) => CommandPage(),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero));
  }

  resetCommandHistory(context) async {
    await Request.post(context: context, url: "/device/command/history/reset/",
      devicePreset: true).send();
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
          thumbColor: MaterialStatePropertyAll<Color>(Theme.of(context).primaryColor),
          activeColor: Colors.blue,
          activeTrackColor: Colors.blue,
          onChanged: (bool value) {
            setState(() {
              entry.state = value;
              updateCommandSettings(context);
            });
          },
        )
      ]
    );
  }

  updateCommandSettings(context) async {
    var commandExecution = entry.entries[0].state;
    var body = <String, String>{"commandExecution": "$commandExecution"};
    await Request.post(context: context, url: "/device/command/settings/update/",
      body: body, devicePreset: true).send();
  }
}
