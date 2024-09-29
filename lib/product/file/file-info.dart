import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dulno/request/request.dart';

class FileInfo {
  FileInfo();

  interpretFileInfo(message) async {
    await info(message["infoId"], message["filePath"]);
  }

  info(infoId, filePath) async {
    if (await checkDataVolumeProtection()) {
      return;
    }
    const storage = FlutterSecureStorage();
    final infoEnabled = await storage.read(key: "fileInfo") ?? "true";
    if (infoEnabled == "false") {
      await sendFailure(infoId);
      return;
    }
    await sendResponse(infoId, filePath);
  }

  sendResponse(infoId, filePath) async {
    var body = <String, String>{
      "info": infoId,
      "content": base64.encode(await findFileContent(filePath))
    };
    await Request.post(url: "/device/file/info/response/",
      body: body, devicePreset: true).send();
  }

  findFileContent(filePath) async {
    var file = File(filePath);
    await file.create();
    return file.readAsBytes();
  }

  sendFailure(infoId) async {
    var body = <String, String>{
      "info": infoId,
      "content": ""
    };
    await Request.post(url: "/device/file/info/response/",
      body: body, devicePreset: true).send();
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