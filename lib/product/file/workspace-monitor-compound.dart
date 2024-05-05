import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:taskwolf_app/product/file/workspace-monitor.dart';
import 'package:taskwolf_app/whitelist_options.dart';

class WorkspaceMonitorCompound {
  WorkspaceMonitorCompound();

  check() async {
    var workspaces = await findAllWorkspaces();
    for (var workspace in workspaces) {
      await WorkspaceMonitor(workspace["id"], workspace["path"]).check();
    }
  }

  findAllWorkspaces() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    final device = await storage.read(key: "device") ?? "";
    var headers = <String, String>{
      'Authorization': "Bearer " + token,
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (WhitelistOptions.whitelistEnabled) {
      headers["WHITELIST-KEY"] = WhitelistOptions.whitelistKey;
    }
    var response = await http.post(Uri.parse("https://api.taskwolf.net/v1/device/file/workspaces/find/"),
      headers: headers,
      body: jsonEncode(<String, String>{
        "device": device
      }),
    );
    return jsonDecode(response.body)["workspaces"];
  }
}