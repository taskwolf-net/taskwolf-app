import 'dart:io';

import 'package:taskwolf/request/request.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FileDelete {
  FileDelete();

  interpretFileDelete(message) async {
    await delete(message["deleteId"], message["filePath"]);
  }

  delete(deleteId, filePath) async {
    var body = <String, String>{"delete": deleteId};
    await Request.post(url: "/device/file/delete/response/",
      body: body, devicePreset: true).send();
    if (filePath[filePath.length - 1] == "/") {
      deleteFolder(filePath);
    } else {
      deleteFile(filePath);
    }
  }

  deleteFile(filePath) async {
    const storage = FlutterSecureStorage();
    final deletionEnabled = await storage.read(key: "fileDelete") ?? "true";
    if (deletionEnabled == "false") {
      return;
    }
    var file = File(filePath);
    await file.delete();
  }

  deleteFolder(folderPath) async {
    const storage = FlutterSecureStorage();
    final deletionEnabled = await storage.read(key: "folderDelete") ?? "true";
    if (deletionEnabled == "false") {
      return;
    }
    var folder = Directory(folderPath);
    await folder.delete(recursive: true);
  }
}