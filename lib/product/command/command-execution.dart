import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:taskwolf_app/whitelist_options.dart';

class CommandExecution {
  CommandExecution();

  var channel;

  interpretCommand(message, channel) {
    this.channel = channel;
    executeCommand(message["commandId"], message["command"]);
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
    var headers = <String, String>{
      'Authorization': "Bearer " + token,
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (WhitelistOptions.whitelistEnabled) {
      headers["WHITELIST-KEY"] = WhitelistOptions.whitelistKey;
    }
    await http.post(
      Uri.parse("https://api.taskwolf.net/v1/device/command/response/"),
      headers: headers,
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