import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dulno/request/request.dart';

class WorkspaceMonitor {
  final workspaceId;
  final workspacePath;

  WorkspaceMonitor(this.workspaceId, this.workspacePath);

  check() async {
    const storage = FlutterSecureStorage();
    if (!await storage.containsKey(key: "workspace-$workspaceId")) {
      await saveCurrentState();
      return;
    }
    await findDifferences();
    await saveCurrentState();
  }

  findDifferences() async {
    const storage = FlutterSecureStorage();
    var workspaceFolder = Directory(workspacePath);
    if (!await workspaceFolder.exists()) {
      removeWorkspace();
      return;
    }
    var previousWorkspace = jsonDecode(await storage.read(key: "workspace-$workspaceId") ?? "");
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
    reportFileChange("/device/file/workspace/file/create/", filePath, fileName);
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
    reportFileChange("/device/file/workspace/file/delete/", filePath, fileName);
  }

  checkFolderCreation(folder, previousFolder) {
    var previousFolderSubFolders = previousFolder["folders"];
    for (var previousFolder in previousFolderSubFolders) {
      if (previousFolder["path"] == folder.path) {
        return;
      }
    }
    var folderPath = folder.path.replaceAll(workspacePath, "");
    reportFolderChange("/device/file/workspace/folder/create/", folderPath);
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
    reportFolderChange("/device/file/workspace/folder/delete/", folderPath);
  }

  saveCurrentState() async {
    const storage = FlutterSecureStorage();
    var workspaceFolder = Directory(workspacePath);
    if (!await workspaceFolder.exists()) {
      removeWorkspace();
      return;
    }
    storage.write(key: "workspace-$workspaceId",
      value: jsonEncode(createFolderObject(workspaceFolder)));
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
    var body = <String, String> {
      "workspace": workspaceId,
      "filePath": filePath,
      "fileName": fileName
    };
    await Request.post(url: url, body: body, devicePreset: true).send();
  }

  reportFolderChange(url, folderPath) async {
    var body = <String, String> {
      "workspace": workspaceId,
      "folderPath": folderPath
    };
    await Request.post(url: url, body: body, devicePreset: true).send();
  }

  removeWorkspace() async {
    var body = <String, String> {"workspace": workspaceId};
    await Request.post(url: "/device/file/workspace/remove/", body: body,
      devicePreset: true).send();
  }
}