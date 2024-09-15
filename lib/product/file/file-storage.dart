import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dulno_app/request/request.dart';

class FileStorage {
  FileStorage();

  interpretFileStorage(message) {
    store(message["storeId"], message["filePath"]);
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