import 'dart:core';
import 'dart:io';

import 'package:taskwolf_app/request/request.dart';

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
}