import 'dart:core';
import 'dart:io';

import 'package:dulno_app/request/request.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CommandExecution {
  CommandExecution();

  var channel;

  interpretCommand(message, channel) async {
    this.channel = channel;
    await executeCommand(message["commandId"], message["command"]);
  }

  executeCommand(commandId, command) async {
    const storage = FlutterSecureStorage();
    final executionEnabled = await storage.read(key: "commandExecution") ?? "true";
    if (executionEnabled == "false") {
      sendFailure(commandId);
      return;
    }
    try {
      var result = await Process.run(command, []);
      sendResponse(commandId, result);
    } on Exception catch (_) {
      sendFailure(commandId);
    }
  }

  sendResponse(commandId, result) {
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
    var exitCode = result.exitCode;
    var body = <String, String>{
      "command": commandId,
      "output": result.stdout,
      "errorMessage": result.stderr,
      "exitCode": "$exitCode"
    };
    await Request.post(url: "/device/command/response/", body: body,
      devicePreset: true).send();
  }

  sendFailure(commandId) {
    if (Platform.isAndroid || Platform.isIOS) {
      sendMobileFailure(commandId);
    } else {
      sendDesktopFailure(commandId);
    }
  }

  sendDesktopFailure(commandId) {
    channel.sink.add("Command Response " + commandId + " '' '' -1");
  }

  sendMobileFailure(commandId) async {
    var body = <String, String>{
      "command": commandId,
      "output": "",
      "errorMessage": "",
      "exitCode": "-1"
    };
    await Request.post(url: "/device/command/response/", body: body,
      devicePreset: true).send();
  }
}