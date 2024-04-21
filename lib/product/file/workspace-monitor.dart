import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WorkspaceMonitor {
  final workspaceId;
  final workspacePath;

  WorkspaceMonitor(this.workspaceId, this.workspacePath);

  check() async {
    final preferences = await SharedPreferences.getInstance();
    if (!preferences.containsKey("workspace-$workspaceId")) {
      await saveCurrentState();
      return;
    }
    await findDifferences();
    await saveCurrentState();
  }

  findDifferences() async {
    final preferences = await SharedPreferences.getInstance();
    var workspaceFolder = Directory(workspacePath);
    if (!await workspaceFolder.exists()) {
      removeWorkspace();
      return;
    }
    var previousWorkspace = jsonDecode(preferences.getString("workspace-$workspaceId") ?? "");
    findFolderDifference(workspaceFolder, previousWorkspace);
  }

  findFolderDifference(folder, previousFolder) {
    for (var children in folder.listSync()) {
      var type = children.statSync().type;
      if (type == FileSystemEntityType.file) {
        checkFileCreation(children, previousFolder);
      } else if (type == FileSystemEntityType.directory) {
        checkFolderCreation(children, previousFolder);
      }
    }
    var previousFolderFiles = previousFolder["files"];
    for (var previousFile in previousFolderFiles) {
      checkFileDeletion(previousFile, folder);
    }
    var previousFolderSubFolders = previousFolder["folders"];
    for (var previousFolder in previousFolderSubFolders) {
      checkFolderDeletion(previousFolder, folder);
    }
    for (var children in folder.listSync()) {
      if (children.statSync().type != FileSystemEntityType.directory) {
        continue;
      }
      for (var previousFolder in previousFolderSubFolders) {
        if (previousFolder["path"] == children.path) {
          findFolderDifference(children, previousFolder);
        }
      }
    }
  }

  checkFileCreation(file, previousFolder) {
    var previousFolderFiles = previousFolder["files"];
    for (var previousFile in previousFolderFiles) {
      if (previousFile["path"] == file.path) {
        return;
      }
    }
    var fileName = File(file.path).uri.pathSegments.last;
    var filePath = file.path.replaceAll(workspacePath, "").replaceAll(fileName, "");
    reportFileChange("https://api.taskwolf.net/v1/device/file/workspace/file/create/",
      filePath, fileName);
  }

  checkFileDeletion(file, currentFolder) {
    for (var children in currentFolder.listSync()) {
      if (children.statSync().type != FileSystemEntityType.file) {
        continue;
      }
      if (file["path"] == children.path) {
        return;
      }
    }
    var fileName = File(file["path"]).uri.pathSegments.last;
    var filePath = file["path"].replaceAll(workspacePath, "").replaceAll(fileName, "");
    reportFileChange("https://api.taskwolf.net/v1/device/file/workspace/file/delete/",
      filePath, fileName);
  }

  checkFolderCreation(folder, previousFolder) {
    var previousFolderSubFolders = previousFolder["folders"];
    for (var previousFolder in previousFolderSubFolders) {
      if (previousFolder["path"] == folder.path) {
        return;
      }
    }
    var folderPath = folder.path.replaceAll(workspacePath, "");
    reportFolderChange("https://api.taskwolf.net/v1/device/file/workspace/folder/create/",
      folderPath);
  }

  checkFolderDeletion(folder, currentFolder) {
    for (var children in currentFolder.listSync()) {
      if (children.statSync().type != FileSystemEntityType.directory) {
        continue;
      }
      if (folder["path"] == children.path) {
        return;
      }
    }
    var folderPath = folder["path"].replaceAll(workspacePath, "");
    reportFolderChange("https://api.taskwolf.net/v1/device/file/workspace/folder/delete/",
      folderPath);
  }

  saveCurrentState() async {
    final preferences = await SharedPreferences.getInstance();
    var workspaceFolder = Directory(workspacePath);
    if (!await workspaceFolder.exists()) {
      removeWorkspace();
      return;
    }
    preferences.setString("workspace-$workspaceId",
      jsonEncode(createFolderObject(workspaceFolder)));
  }

  createFolderObject(folder) {
    var result = {};
    result["path"] = folder.path;
    var files = [];
    var folders = [];
    for (var children in folder.listSync()) {
      var type = children.statSync().type;
      if (type == FileSystemEntityType.file) {
        files.add(createFileObject(children));
      } else if (type == FileSystemEntityType.directory) {
        folders.add(createFolderObject(children));
      }
    }
    result["files"] = files;
    result["folders"] = folders;
    return result;
  }

  createFileObject(file) {
    return {"path": file.path};
  }

  reportFileChange(url, filePath, fileName) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    await http.post(Uri.parse(url),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "workspace": workspaceId,
        "filePath": filePath,
        "fileName": fileName
      }),
    );
  }

  reportFolderChange(url, folderPath) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    await http.post(Uri.parse(url),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "workspace": workspaceId,
        "folderPath": folderPath
      }),
    );
  }

  removeWorkspace() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    await http.post(Uri.parse("https://api.taskwolf.net/v1/device/file/workspace/remove/"),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "workspace": workspaceId
      }),
    );
  }
}