import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class FileStorage {
  FileStorage();

  interpretFileStorage(message) {
    var split = message.replaceAll("File Storage ", "").split(" ");
    store(split[0], split[1]);
  }

  store(storeId, filePath) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    final device = await storage.read(key: "device") ?? "";
    var response = await http.post(
      Uri.parse("https://api.taskwolf.net/v1/device/file/storage/response/"),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "storage": storeId
      }),
    );
    var content = base64.decode(jsonDecode(response.body)["content"]);
    if (filePath[filePath.length - 1] == "/") {
      createFolder(filePath);
    } else {
      createFile(filePath, content);
    }
  }

  createFile(filePath, content) async {
    var file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(content);
  }

  createFolder(folderPath) async {
    var folder = Directory(folderPath);
    await folder.create(recursive: true);
  }
}