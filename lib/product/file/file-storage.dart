import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FileStorage {
  FileStorage();

  interpretFileStorage(message) {
    var split = message.replaceAll("File Storage ", "").split(" ");
    store(split[0], split[1], split[2]);
  }

  store(storeId, filePath, fileName) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
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
    createFile(filePath, fileName, content);
  }

  createFile(filePath, fileName, content) async {
    var file = File(filePath + "/" + fileName);
    await file.create();
    await file.writeAsBytes(content);
  }
}