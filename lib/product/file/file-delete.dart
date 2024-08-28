import 'dart:io';

import 'package:taskwolf_app/request/request.dart';

class FileDelete {
  FileDelete();

  interpretFileDelete(message) {
    delete(message["deleteId"], message["filePath"]);
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
    var file = File(filePath);
    await file.delete();
  }

  deleteFolder(folderPath) async {
    var folder = Directory(folderPath);
    await folder.delete(recursive: true);
  }
}