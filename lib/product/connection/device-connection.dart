import 'dart:io';
import 'dart:core';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskwolf_app/product/command/command-execution.dart';
import 'package:taskwolf_app/product/file/file-delete.dart';
import 'package:taskwolf_app/product/file/file-info.dart';
import 'package:taskwolf_app/product/file/file-storage.dart';
import 'package:taskwolf_app/product/notification/push-notification.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DeviceConnection {
  DeviceConnection();

  var channel;

  establish() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return;
    }
    connect();
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
      PushNotification().interpretNotification(message);
    } else if (message.startsWith("Command")) {
      CommandExecution().interpretCommand(message, channel);
    } else if (message.startsWith("File Storage")) {
      FileStorage().interpretFileStorage(message);
    } else if (message.startsWith("File Info")) {
      FileInfo().interpretFileInfo(message);
    } else if (message.startsWith("File Delete")) {
      FileDelete().interpretFileDelete(message);
    }
  }
}