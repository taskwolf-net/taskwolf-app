import 'dart:io';
import 'dart:core';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DeviceConnection {
  DeviceConnection();

  var channel;

  establish() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return;
    }
    setupNotifications();
    connect();
  }

  setupNotifications() async {
    await localNotifier.setup(
      appName: 'Taskwolf',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  connect() async {
    try {
      var uri = await createUri();
      channel = WebSocketChannel.connect(uri);
      await channel.ready;
      channel.stream.listen(
        (message) {
          interpret(message);
        },
        onDone: () {
          connect();
        },
      );
    } on Exception {
      reconnect();
    }
  }

  createUri() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    var uri = "wss://api.taskwolf.net/device/connect/?token=" + token +
      "&device=" + device;
    return Uri.parse(uri);
  }

  reconnect() {
    Future.delayed(const Duration(seconds: 10), () => connect());
  }

  interpret(message) {
    if (message.startsWith("Notification")) {
      interpretNotification(message);
    } else if (message.startsWith("Command")) {
      interpretCommand(message);
    } else if (message.startsWith("File Storage")) {
      interpretFileStorage(message);
    } else if (message.startsWith("File Info")) {
      interpretFileInfo(message);
    }
  }

  interpretNotification(message) {
    var split = message.replaceAll("Notification ", "").split(" ");
    sendNotification(split[0], split[1]);
  }

  interpretCommand(message) {
    var split = message.replaceAll("Command ", "").split(" ");
    executeCommand(split[0], split[1]);
  }

  interpretFileStorage(message) {
    var split = message.replaceAll("File Storage ", "").split(" ");
    executeCommand(split[0], split[1]);
  }

  interpretFileInfo(message) {
    var split = message.replaceAll("File Info ", "").split(" ");
    executeCommand(split[0], split[1]);
  }

  sendNotification(title, body) async {
    LocalNotification notification = LocalNotification(
      title: title,
      body: body,
    );
    await notification.show();
  }

  executeCommand(commandId, command) async {
    var result = await Process.run(command, []);
    var exitCode = result.exitCode;
    channel.sink.add("Command Response " + commandId + " '" +
      result.stdout.replaceAll("\n", " ") + "' '" +
        result.stderr.replaceAll("\n", " ") + "' $exitCode");
  }
}