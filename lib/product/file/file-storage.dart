import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taskwolf/request/request.dart';

class FileStorage {
  FileStorage();

  interpretFileStorage(message) async {
    await store(message["storeId"], message["filePath"]);
  }

  store(storeId, filePath) async {
    if (await checkDataVolumeProtection()) {
      return;
    }
    var body = <String, String>{"storage": storeId};
    var response = await Request.post(url: "/device/file/storage/response/",
      body: body, devicePreset: true).send();
    var content = base64.decode(jsonDecode(response.body)["content"]);
    if (filePath[filePath.length - 1] == "/") {
      createFolder(filePath);
    } else {
      createFile(filePath, content);
    }
  }

  createFile(filePath, content) async {
    const storage = FlutterSecureStorage();
    final creationEnabled = await storage.read(key: "fileStorage") ?? "true";
    if (creationEnabled == "false") {
      return;
    }
    var file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(content);
  }

  createFolder(folderPath) async {
    const storage = FlutterSecureStorage();
    final creationEnabled = await storage.read(key: "folderCreate") ?? "true";
    if (creationEnabled == "false") {
      return;
    }
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