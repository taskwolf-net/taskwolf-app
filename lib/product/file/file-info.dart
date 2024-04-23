import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class FileInfo {
  FileInfo();

  interpretFileInfo(message) {
    var split = message.replaceAll("File Info ", "").split(" ");
    info(split[0], split[1]);
  }

  info(infoId, filePath) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    final device = await storage.read(key: "device") ?? "";
    await http.post(
      Uri.parse("https://api.taskwolf.net/v1/device/file/info/response/"),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "info": infoId,
        "content": base64.encode(await findFileContent(filePath))
      }),
    );
  }

  findFileContent(filePath) async {
    var file = File(filePath);
    await file.create();
    return file.readAsBytes();
  }
}