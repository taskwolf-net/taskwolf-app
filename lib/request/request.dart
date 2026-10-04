import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:taskwolf/login/login.dart';
import 'package:taskwolf/whitelist_options.dart';

class Request {
  var context;
  var url;
  var method;
  var headers;
  var body;
  var devicePreset;
  var checkAuthorization;
  final Future<Map<String, String>> Function()? refreshUpdate;

  Request.get({
    this.context, required url, Map<String, String> this.headers = const {},
    this.checkAuthorization = true, this.refreshUpdate
  }) {
    this.url = "https://api.taskwolf.net/v1$url";
    method = "GET";
    devicePreset = false;
  }

  Request.post({
    this.context, required url, Map<String, String> this.headers = const {},
    Map<String, String> this.body = const {}, this.devicePreset = false,
    this.checkAuthorization = true, this.refreshUpdate
  }) {
    this.url = "https://api.taskwolf.net/v1$url";
    method = "POST";
  }

  send() async {
    Map<String, String> headers = Map.from(this.headers);
    headers["Content-Type"] = "application/json; charset=UTF-8";
    const storage = FlutterSecureStorage();
    var token = await storage.read(key: "token") ?? "";
    if (token != "") {
      headers["Authorization"] = "Bearer $token";
    }
    if (WhitelistOptions.whitelistEnabled) {
      headers["WHITELIST-KEY"] = WhitelistOptions.whitelistKey;
    }
    var response = await generateResponse(storage, headers);
    if (!checkAuthorization) {
      return response;
    }
    if (response.statusCode == 403 || response.statusCode == 409) {
      await reset();
      return response;
    }
    if (response.statusCode == 417) {
      var refreshResult = await refresh(context);
      if (refreshResult == true) {
        if (refreshUpdate != null) {
          body = await refreshUpdate!();
        }
        return await send();
      }
      await reset();
      return response;
    }
    return response;
  }

  generateResponse(storage, headers) async {
    if (method == "GET") {
      return await http.get(Uri.parse(url), headers: headers);
    } else if (method == "POST") {
      Map<String, String> body = Map.from(this.body);
      if (devicePreset == true) {
        final device = await storage.read(key: "device") ?? "";
        body["device"] = device;
      }
      return await http.post(Uri.parse(url), headers: headers,
        body: jsonEncode(body));
    }
  }

  refresh(context) async {
    const storage = FlutterSecureStorage();
    final refreshToken = await storage.read(key: "refreshToken") ?? "";
    if (refreshToken == "") {
      return false;
    }
    var response = await Request.post(context: context, url: "/verification/refresh/",
      body: <String, String>{"refreshToken": refreshToken}).send();
    var responseBody = jsonDecode(response.body);
    if (responseBody["success"] == "false") {
      return false;
    }
    await storage.write(key: "token", value: responseBody["productApiKey"]);
    await storage.write(key: "refreshToken", value: responseBody["refreshToken"]);
    return true;
  }

  reset() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: "token");
    await storage.delete(key: "refreshToken");
    await storage.delete(key: "device");
    if (context == null) {
      return;
    }
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (context) => LoginPage()));
  }
}