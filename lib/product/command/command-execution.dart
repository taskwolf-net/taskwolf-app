import 'dart:core';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
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