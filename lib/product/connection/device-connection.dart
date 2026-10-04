import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taskwolf/product/command/command-execution.dart';
import 'package:taskwolf/product/file/file-delete.dart';
import 'package:taskwolf/product/file/file-info.dart';
import 'package:taskwolf/product/file/file-storage.dart';
import 'package:taskwolf/product/notification/push-notification.dart';
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
      var rejected = false;
      channel.stream.listen(
        (message) {
          if (message == "REJECTED") {
            rejected = true;
            return;
          }
          interpret(jsonDecode(message));
        },
        onDone: () {
          if (rejected) {
            return;
          }
          connect();
        },
      );
    } on Exception {
      reconnect();
    }
  }

  createUri() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    final device = await storage.read(key: "device") ?? "";
    var uri = "wss://api.taskwolf.net/device/connect/?token=" + token +
      "&device=" + device;
    return Uri.parse(uri);
  }

  reconnect() {
    Future.delayed(const Duration(seconds: 10), () => connect());
  }

  interpret(message) {
    var type = message["type"];
    if (type == "NOTIFICATION") {
      PushNotification().interpretNotification(message);
    } else if (type == "COMMAND") {
      CommandExecution().interpretCommand(message, channel);
    } else if (type == "FILE_STORAGE") {
      FileStorage().interpretFileStorage(message);
    } else if (type == "FILE_INFO") {
      FileInfo().interpretFileInfo(message);
    } else if (type == "FILE_DELETE") {
      FileDelete().interpretFileDelete(message);
    }
  }
}