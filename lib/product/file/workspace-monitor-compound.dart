import 'dart:convert';

import 'package:taskwolf_app/product/file/workspace-monitor.dart';
import 'package:taskwolf_app/request/request.dart';

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
    return jsonDecode(response.body)["workspaces"];
  }
}