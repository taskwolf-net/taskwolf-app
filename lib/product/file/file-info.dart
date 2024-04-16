import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FileInfo {
  FileInfo();

  interpretFileInfo(message) {
    var split = message.replaceAll("File Info ", "").split(" ");
    info(split[0], split[1]);
  }

  info(infoId, filePath) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
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