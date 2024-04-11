
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_notifier/local_notifier.dart';

class NotificationSchedule {
  NotificationSchedule();

  start() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return;
    }
    setupNotifications();
    startSchedule();
  }

  setupNotifications() async {
    await localNotifier.setup(
      appName: 'Taskwolf',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  startSchedule() {
    execute();
    var timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      execute();
    });
  }

  execute() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    if (token == "" || device == "") {
      return;
    }
    final response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/desktop/notifications/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device
      }),
    );
    final notifications = List<Map<String, dynamic>>.from(jsonDecode(response.body)["notifications"]);
    for (var notification in notifications) {
      sendNotification(notification["title"], notification["body"]);
    }
  }

  sendNotification(title, body) {
    LocalNotification notification = LocalNotification(
      title: title,
      body: body,
    );
    notification.show();
  }
}