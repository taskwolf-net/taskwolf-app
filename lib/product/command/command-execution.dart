import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class CommandExecution {
  CommandExecution();

  var channel;

  interpretCommand(message, channel) {
    this.channel = channel;
    var split = message.replaceAll("Command ", "").split(" ");
    executeCommand(split[0], split[1]);
  }

  executeCommand(commandId, command) async {
    var result = await Process.run(command, []);
    if (Platform.isAndroid || Platform.isIOS) {
      sendMobileResponse(commandId, result);
    } else {
      sendDesktopResponse(commandId, result);
    }
  }

  sendDesktopResponse(commandId, result) {
    var exitCode = result.exitCode;
    channel.sink.add("Command Response " + commandId + " '" +
      result.stdout.replaceAll("\n", " ") + "' '" +
      result.stderr.replaceAll("\n", " ") + "' $exitCode");
  }

  sendMobileResponse(commandId, result) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    final device = await storage.read(key: "device") ?? "";
    var exitCode = result.exitCode;
    await http.post(
      Uri.parse("https://api.taskwolf.net/v1/device/command/response/"),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "command": commandId,
        "output": result.stdout,
        "errorMessage": result.stderr,
        "exitCode": "$exitCode"
      }),
    );
  }
}