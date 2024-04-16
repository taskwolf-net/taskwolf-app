import 'dart:core';

import 'package:local_notifier/local_notifier.dart';

class PushNotification {
  PushNotification();

  interpretNotification(message) {
    setupNotifications();
    var split = message.replaceAll("Notification ", "").split(" ");
    sendNotification(split[0], split[1]);
  }

  setupNotifications() async {
    await localNotifier.setup(
      appName: 'Taskwolf',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  sendNotification(title, body) async {
    LocalNotification notification = LocalNotification(
      title: title,
      body: body,
    );
    await notification.show();
  }
}