import 'package:flutter/material.dart';
import 'package:taskwolf_app/net/taskwolf/app/product/base/page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatelessWidget {
  NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: createNotificationSettingEntries(),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        var entries = List<NotificationSettingEntry>.from(snapshot.data ?? []);
        return ProductPage(name: "Notifications", content: SizedBox(
          child: Center(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 20),
                  child: const Text("Notification Settings",
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
        ));
      }
    );
  }

  createNotificationSettingEntries() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    final response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/notification/settings/'),
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
    var entries = <NotificationSettingEntry>[];
    entries.add(NotificationSettingEntry(
      title: "Receive notifications through workflows",
      state: body["workflowNotifications"], entries: entries));
    entries.add(NotificationSettingEntry(
      title: "Receive notifications in the event of errors",
      state: body["errorNotifications"], entries: entries));
    entries.add(NotificationSettingEntry(
      title: "Receive notifications when new features are available",
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
        Text(entry.title),
        Switch(
          value: entry.state,
          thumbColor: const MaterialStatePropertyAll<Color>(Colors.white),
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
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    var workflowNotifications = entry.entries[0].state;
    var errorNotifications = entry.entries[1].state;
    var newsNotifications = entry.entries[2].state;
    await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/notification/settings/update/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "workflowNotifications": "$workflowNotifications",
        "errorNotifications": "$errorNotifications",
        "newsNotifications": "$newsNotifications",
      }),
    );
  }
}
