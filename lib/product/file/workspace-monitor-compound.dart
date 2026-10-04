import 'dart:convert';

import 'package:taskwolf/product/file/workspace-monitor.dart';
import 'package:taskwolf/request/request.dart';

class WorkspaceMonitorCompound {
  WorkspaceMonitorCompound();

  check() async {
    var workspaces = await findAllWorkspaces();
    for (var workspace in workspaces) {
      await WorkspaceMonitor(workspace["id"], workspace["path"]).check();
    }
  }

  findAllWorkspaces() async {
    var response = await Request.post(url: "/device/file/workspaces/find/",
      devicePreset: true).send();
    if (response.statusCode != 200) {
      return [];
    }
    return jsonDecode(response.body)["workspaces"];
  }
}