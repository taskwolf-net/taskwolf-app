import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:dulno_app/product/base/page.dart';
import 'package:dulno_app/product/command/command.dart';
import 'package:dulno_app/product/file/file.dart';
import 'package:dulno_app/product/help/help.dart';
import 'package:dulno_app/product/notification/notification.dart';
import 'package:dulno_app/product/organization/organization.dart';
import 'package:dulno_app/request/request.dart';
import 'package:dulno_app/settings/theme/theme-state.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: findUsername(context),
      builder: (context, AsyncSnapshot<dynamic> usernameSnapshot) {
        return ProductPage(name: Locales.string(context, "product.home.title"),
          content: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF232D3E),
                          Color(0xFF586882),
                        ],
                        begin: FractionalOffset(0.0, 0.0),
                        end: FractionalOffset(1.0, 0.0),
                        stops: [0.0, 1.0],
                        tileMode: TileMode.clamp),
                    ),
                    child: Flex(
                      mainAxisAlignment: MainAxisAlignment.center,
                      direction: MediaQuery.sizeOf(context).width < 1000 ? Axis.vertical : Axis.horizontal,
                      children: [
                        Image.asset(
                          "assets/images/logo.png",
                          height: 192.0,
                          width: 192.0,
                        ),
                        const SizedBox(width: 200),
                        Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                Locales.string(context, "product.home.welcome") +
                                  (usernameSnapshot.data ?? ""),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 20),
                              width: 400,
                              child: const LocaleText("product.home.available",
                                textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white))
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.9,
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              createPageButton("product.home.title", HomePage(),
                                Icons.home, context),
                              createPageButton("product.organizations.title", OrganizationPage(),
                                Icons.groups, context),
                              createPageButton("product.notifications.title", NotificationPage(),
                                Icons.notifications, context),
                              createPageButton("product.files.title", FilePage(),
                                Icons.file_copy_sharp, context),
                              createPageButton("product.commands.title", CommandPage(),
                                Icons.terminal, context),
                              createPageButton("product.help.title", HelpPage(),
                                Icons.help, context),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Divider(),
                        Activity()
                      ],
                    )
                  ),
                ]
              )
            )
          )
        );
      }
    );
  }

  createPageButton(text, page, icon, context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0))
        ),
        onPressed: () async {
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => page));
        },
        child: SizedBox(
          width: 192,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 80,),
              const SizedBox(height: 10),
              LocaleText(text, style: const TextStyle(fontSize: 20),)
            ],
          )
        ),
      )
    );
  }

  findUsername(context) async {
    var response = await Request.get(context: context,
      url: "/settings/profile/username/").send();
    return jsonDecode(response.body)["username"];
  }
}

class Activity extends StatelessWidget {
  const Activity({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: findFileActivity(context),
      builder: (context, AsyncSnapshot<dynamic> fileSnapshot) {
        return FutureBuilder<dynamic>(
          future: findCommandActivity(context),
          builder: (context, AsyncSnapshot<dynamic> commandSnapshot) {
            if (!fileSnapshot.hasData || !commandSnapshot.hasData) {
              return Container();
            }
            return Flex(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              direction: MediaQuery.sizeOf(context).width < 1800 ? Axis.vertical : Axis.horizontal,
              children: [
                Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(20),
                      child: const LocaleText("product.home.file.activity",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                    ),
                    createFileActivity(List<Map<String, dynamic>>.from(fileSnapshot.data ?? []), context),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(20),
                      child: const LocaleText("product.home.command.activity",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                    ),
                    createCommandActivity(List<Map<String, dynamic>>.from(commandSnapshot.data ?? []), context)
                  ],
                ),
              ],
            );
          }
        );
      }
    );
  }


  createFileActivity(activity, context) {
    if (activity.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: 750,
        child: const LocaleText("product.home.file.activity.empty",
          textAlign: TextAlign.center, style: TextStyle(fontSize: 15))
      );
    }
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      width: 750,
      child: ListView.separated(
        itemBuilder: (builder, index) {
          return Card(child: createFileActivityEntry(activity[index], isLight,
            context));
        },
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        shrinkWrap: true,
        itemCount: activity.length,
      ),
    );
  }

  createFileActivityEntry(entry, isLight, context) {
    var type = "-";
    var color = const Color(0xFFFFFFFF);
    if (entry["type"] == "storage") {
      type = Locales.string(context, "product.home.file.activity.storage");
      color = isLight ? const Color(0xFF5AD174) : const Color(0xFF478E56);
    } else if (entry["type"] == "delete") {
      type = Locales.string(context, "product.home.file.activity.deletion");
      color = isLight ? const Color(0xFFFF8C8C) : const Color(0xFFD55252);
    } else if (entry["type"] == "info") {
      type = Locales.string(context, "product.home.file.activity.info");
      color = isLight ? const Color(0xFF60D0E6) : const Color(0xFF258BA2);
    }
    return ListTile(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(type)
          ),
        ]
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Locales.string(context, "product.files.storage.history.file") +
            ": " + entry["compoundPath"]),
          Text(Locales.string(context, "product.files.storage.history.time") +
            ": " + entry["executed"])
        ]
      ),
      tileColor: isLight ? const Color(0xFFDCDCDC) : const Color(0xFF333333),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isLight ? const Color(0xFFA9A9A9) : const Color(0xFF5D5D5D),
          width: 1),
        borderRadius: BorderRadius.circular(5),
      )
    );
  }

  findFileActivity(context) async {
    var entries = [];
    var storageEntry = await findFileHistoryEntry(context, "storage");
    if (storageEntry != null) {
      entries.add(storageEntry);
    }
    var deleteEntry = await findFileHistoryEntry(context, "delete");
    if (deleteEntry != null) {
      entries.add(deleteEntry);
    }
    var infoEntry = await findFileHistoryEntry(context, "info");
    if (infoEntry != null) {
      entries.add(infoEntry);
    }
    return entries;
  }

  findFileHistoryEntry(context, type) async {
    var response = await Request.post(context: context,
      url: "/device/file/$type/history/", devicePreset: true).send();
    var entries = jsonDecode(response.body)["history"];
    if (entries.length > 0) {
      var entry = entries[0];
      entry["type"] = type;
      return entry;
    }
    return null;
  }

  createCommandActivity(history, context) {
    if (history.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: 750,
        child: const LocaleText("product.home.command.activity.empty",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),)
      );
    }
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      width: 750,
      child: ListView.separated(
        itemBuilder: (builder, index) {
          return Card(child: createCommandHistoryEntry(history[index], isLight,
            context));
        },
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        shrinkWrap: true,
        itemCount: history.length,
      ),
    );
  }

  createCommandHistoryEntry(command, isLight, context) {
    var exitCode = command["exitCode"];
    return ListTile(
      title: Container(
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.only(bottom: 10),
        child: Text(Locales.string(context, "product.commands.history.command") +
          ": \"" + command["command"] + "\"")
      ),
      subtitle: Text(Locales.string(context, "product.commands.history.output") +
        ": \"" + command["output"] + command["errorMessage"] + "\"\n" +
        Locales.string(context, "product.commands.history.exit.code") + ": $exitCode"),
      tileColor: isLight ? const Color(0xFFDCDCDC) : const Color(0xFF333333),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isLight ? const Color(0xFFA9A9A9) : const Color(0xFF5D5D5D),
          width: 1),
        borderRadius: BorderRadius.circular(5),
      )
    );
  }

  findCommandActivity(context) async {
    var response = await Request.post(context: context,
      url: "/device/command/history/", devicePreset: true).send();
    var entries = [];
    var history = jsonDecode(response.body)["history"];
    for (var i = 0; i < 3; i++) {
      if (i < history.length) {
        entries.add(history[i]);
      }
    }
    return entries;
  }
}