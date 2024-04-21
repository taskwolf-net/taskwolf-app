import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskwolf_app/product/file/workspace-monitor.dart';

class WorkspaceMonitorCompound {
  WorkspaceMonitorCompound();

  check() async {
    var workspaces = await findAllWorkspaces();
    for (var workspace in workspaces) {
      await WorkspaceMonitor(workspace["id"], workspace["path"]).check();
    }
  }

  findAllWorkspaces() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    var response = await http.post(Uri.parse("https://api.taskwolf.net/v1/device/file/workspaces/find/"),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device
      }),
    );
    return jsonDecode(response.body)["workspaces"];
  }
}