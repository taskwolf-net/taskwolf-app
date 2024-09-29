import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:dulno/product/base/page.dart';
import 'package:dulno/request/request.dart';

class NotificationPage extends StatelessWidget {
  NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: createNotificationSettingEntries(context),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        var entries = List<NotificationSettingEntry>.from(snapshot.data ?? []);
        return ProductPage(name: Locales.string(context, "product.notifications.title"),
          content: SizedBox(
            child: Center(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 20),
                    child: const LocaleText("product.notifications.settings",
                      textAlign: TextAlign.center, style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      width: 750,
                      child: ListView.builder(
                        itemBuilder: (builder, index) {
                          return ListTile(title: entries[index]);
                        },
                        itemCount: entries.length,
                      ),
                    ),
                  ),
                ]
              ),
            ),
          )
        );
      }
    );
  }

  createNotificationSettingEntries(context) async {
    var response = await Request.post(context: context,
      url: "/device/notification/settings/", devicePreset: true).send();
    final body = jsonDecode(response.body);
    var entries = <NotificationSettingEntry>[];
    entries.add(NotificationSettingEntry(
      title: "product.notifications.workflows",
      state: body["workflowNotifications"], entries: entries));
    entries.add(NotificationSettingEntry(
      title: "product.notifications.errors",
      state: body["errorNotifications"], entries: entries));
    entries.add(NotificationSettingEntry(
      title: "product.notifications.news",
      state: body["newsNotifications"], entries: entries));
    return entries;
  }
}

class NotificationSettingEntry extends StatefulWidget {
  NotificationSettingEntry({super.key, this.title, required this.state, this.entries});

  final title;
  bool state;
  final entries;

  @override
  State<NotificationSettingEntry> createState() => NotificationSettingEntryState(
    entry: this);
}

class NotificationSettingEntryState extends State<NotificationSettingEntry> {
  NotificationSettingEntryState({this.entry});

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
              updateNotificationSettings();
            });
          },
        )
      ]
    );
  }

  updateNotificationSettings() async {
    var workflowNotifications = entry.entries[0].state;
    var errorNotifications = entry.entries[1].state;
    var newsNotifications = entry.entries[2].state;
    var body = <String, String>{
      "workflowNotifications": "$workflowNotifications",
      "errorNotifications": "$errorNotifications",
      "newsNotifications": "$newsNotifications",
    };
    await Request.post(context: context, url: "/device/notification/settings/update/",
      body: body, devicePreset: true).send();
  }
}
