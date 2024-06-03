import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:taskwolf_app/product/base/header.dart';
import 'package:taskwolf_app/product/base/sidebar.dart';
import 'package:taskwolf_app/whitelist_options.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({Key? key}) : super(key: key);

  @override
  State<MobileHomePage> createState() => MobileHomePageState();
}

class MobileHomePageState extends State<MobileHomePage> {
  var webViewController;

  @override
  void initState() {
    super.initState();
    createDashboard();
  }

  createDashboard() async {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {

          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );
    var response = await findDashboard();
    var url = response["url"];
    const storage = FlutterSecureStorage();
    final theme = await storage.read(key: "theme") ?? "";
    url = url + "&theme=" + theme;
    var token = response["token"];
    await WebViewCookieManager().setCookie(WebViewCookie(name: "grafana_session",
      value: token, domain: ".taskwolf.net"));
    sleep(const Duration(milliseconds: 1000));
    await webViewController.loadRequest(Uri.parse(url));
  }

  findDashboard() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    var headers = <String, String>{
      'Authorization': "Bearer " + token,
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (WhitelistOptions.whitelistEnabled) {
      headers["WHITELIST-KEY"] = WhitelistOptions.whitelistKey;
    }
    final response = await http.get(
      Uri.parse('https://api.taskwolf.net/v1/dashboard/'),
      headers: headers
    );
    return await jsonDecode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProductHeader(page: Locales.string(context, "product.home.title")),
      drawer: ProductSidebar(page: Locales.string(context, "product.home.title")),
      body: WebViewWidget(controller: webViewController),
    );
  }
}