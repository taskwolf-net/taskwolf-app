import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class FileDelete {
  FileDelete();

  interpretFileDelete(message) {
    delete(message["deleteId"], message["filePath"]);
  }

  delete(deleteId, filePath) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    final device = await storage.read(key: "device") ?? "";
    await http.post(
      Uri.parse("https://api.taskwolf.net/v1/device/file/delete/response/"),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "delete": deleteId
      }),
    );
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