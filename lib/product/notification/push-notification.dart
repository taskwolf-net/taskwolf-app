import 'dart:core';

import 'package:local_notifier/local_notifier.dart';

class PushNotification {
  PushNotification();

  interpretNotification(message) async {
    await setupNotifications();
    await sendNotification(message["title"], message["body"]);
  }

  setupNotifications() async {
    await localNotifier.setup(
      appName: 'taskwolf',
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