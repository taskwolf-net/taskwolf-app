import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FileDelete {
  FileDelete();

  interpretFileDelete(message) {
    var split = message.replaceAll("File Delete ", "").split(" ");
    delete(split[0], split[1]);
  }

  delete(deleteId, filePath) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
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
    await folder.delete();
  }
}