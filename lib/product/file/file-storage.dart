import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:taskwolf_app/whitelist_options.dart';

class FileStorage {
  FileStorage();

  interpretFileStorage(message) {
    store(message["storeId"], message["filePath"]);
  }

  store(storeId, filePath) async {
    if (await checkDataVolumeProtection()) {
      return;
    }
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    final device = await storage.read(key: "device") ?? "";
    var headers = <String, String>{
      'Authorization': "Bearer " + token,
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (WhitelistOptions.whitelistEnabled) {
      headers["WHITELIST-KEY"] = WhitelistOptions.whitelistKey;
    }
    var response = await http.post(
      Uri.parse("https://api.taskwolf.net/v1/device/file/storage/response/"),
      headers: headers,
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

  checkDataVolumeProtection() async {
    const storage = FlutterSecureStorage();
    var isProtected = (await storage.read(key: "data-volume") ?? "protected") == "protected";
    if (!isProtected) {
      return false;
    }
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult.contains(ConnectivityResult.mobile);
  }
}