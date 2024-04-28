import 'dart:io';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:taskwolf_app/product/base/header.dart';
import 'package:taskwolf_app/product/base/sidebar.dart';
import 'package:webview_cef/webview_cef.dart';

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({Key? key}) : super(key: key);

  @override
  State<DesktopHomePage> createState() => DesktopHomePageState();
}

class DesktopHomePageState extends State<DesktopHomePage> {
  static final webViewController = WebViewController();

  @override
  void initState() {
    super.initState();
    createDashboard();
  }

  createDashboard() async {
    if (!webViewController.value) {
      await webViewController.initialize();
    }
    var response = await findDashboard();
    var url = response["url"];
    var token = response["token"];
    await webViewController.loadUrl(url);
    await webViewController.executeJavaScript("document.cookie = 'grafana_session=" +
        token + ";path=/;domain=.taskwolf.net;secure=true'");
    sleep(const Duration(milliseconds: 500));
    await webViewController.loadUrl(url);
    setState(() {});
  }

  findDashboard() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    final response = await http.get(
        Uri.parse('https://api.taskwolf.net/v1/dashboard/'),
        headers: <String, String>{
          'Authorization': "Bearer " + token,
          'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
          'Content-Type': 'application/json; charset=UTF-8',
        }
    );
    return await jsonDecode(response.body);
  }

  Future<String> applyUserLanguage(context) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    final device = await storage.read(key: "device") ?? "";
    final response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/language/find/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device
      }),
    );
    var language = await jsonDecode(response.body)["language"];
    await Locales.change(context, language);
    return language;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProductHeader(page: Locales.string(context, "product.home.title")),
      drawer: ProductSidebar(page: Locales.string(context, "product.home.title")),
      body: Column(
        children: [
          webViewController.value ? Expanded(child: WebView(webViewController)) : Container(),
        ],
      ),
    );
  }
}