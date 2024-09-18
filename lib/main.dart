import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:dulno_app/firebase_options.dart';
import 'package:dulno_app/login/login.dart';
import 'package:dulno_app/product/command/command-execution.dart';
import 'package:dulno_app/product/connection/device-connection.dart';
import 'package:dulno_app/product/file/file-info.dart';
import 'package:dulno_app/product/file/file-storage.dart';
import 'package:dulno_app/product/file/workspace-monitor-compound.dart';
import 'package:dulno_app/product/home/home.dart';
import 'package:dulno_app/settings/language/language-state.dart';
import 'package:dulno_app/settings/theme/theme-state.dart';
import 'package:dulno_app/whitelist_options.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  var data = message.data;
  if (data.containsKey("commandId") && data.containsKey("command")) {
    CommandExecution().executeCommand(data["commandId"], data["command"]);
  } else if (data.containsKey("storeId") && data.containsKey("filePath")) {
    FileStorage().store(data["storeId"], data["filePath"]);
  } else if (data.containsKey("infoId") && data.containsKey("filePath")) {
    FileInfo().info(data["infoId"], data["filePath"]);
  } else if (data.containsKey("workspaceMonitor")) {
    WorkspaceMonitorCompound().check();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Locales.init(["en", "de"]);
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await DeviceConnection().establish();
    Timer.periodic(const Duration(seconds: 10), (timer) {
      WorkspaceMonitorCompound().check();
    });
  } else {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.instance.subscribeToTopic("dulno-workspace-monitor");
  }
  runApp(const DulnoApp());
}

class DulnoApp extends StatelessWidget {
  const DulnoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeMode>(
      future: findTheme(),
      builder: (context, AsyncSnapshot<ThemeMode> themeSnapshot) {
        return FutureBuilder<String>(
          future: findLanguage(),
          builder: (context, AsyncSnapshot<String> languageSnapshot) {
            if (themeSnapshot.data == null || languageSnapshot.data == null) {
              return Container();
            }
            return MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => ThemeState(
                  themeSnapshot.data ?? ThemeMode.light)),
                ChangeNotifierProvider(create: (_) => LanguageState(
                  languageSnapshot.data ?? "en")),
              ],
              child: FutureBuilder<bool>(
                future: checkTokenExistence(),
                builder: (context, AsyncSnapshot<bool> tokenSnapshot) {
                  if (tokenSnapshot.data == null) {
                    return Container();
                  }
                  var home = tokenSnapshot.data == true ? HomePage() : LoginPage();
                  return LocaleBuilder(
                    builder: (locale) => MaterialApp( title: 'dulno App',
                      theme: ThemeData(
                        useMaterial3: true,
                        primaryColor: Colors.black,
                        colorScheme: ColorScheme.light(primary: Color(0xFF2196F3),
                          background: Color(0xFFE8E8E8)),
                      ),
                      darkTheme: ThemeData(
                        useMaterial3: true,
                        primaryColor: Colors.white,
                        colorScheme: ColorScheme.dark(primary: Color(0xFF2196F3),
                          background: Color(0xFF121212)),
                      ),
                      themeMode: Provider.of<ThemeState>(context).getTheme,
                      home: home,
                      debugShowCheckedModeBanner: false,
                      localizationsDelegates: Locales.delegates,
                      supportedLocales: Locales.supportedLocales,
                      locale: locale,
                    )
                  );
                }
              )
            );
          }
        );
      }
    );
  }

  Future<ThemeMode> findTheme() async {
    const storage = FlutterSecureStorage();
    final theme = await storage.read(key: "theme") ?? "";
    return theme == "light" ? ThemeMode.light : ThemeMode.dark;
  }

  Future<String> findLanguage() async {
    const storage = FlutterSecureStorage();
    final language = await storage.read(key: "language") ?? "en";
    return language;
  }

  Future<bool> checkTokenExistence() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    if (token == "") {
      return false;
    }
    var headers = <String, String>{
      'Authorization': "Bearer " + token,
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (WhitelistOptions.whitelistEnabled) {
      headers["WHITELIST-KEY"] = WhitelistOptions.whitelistKey;
    }
    final response = await http.post(
      Uri.parse('https://api.dulno.com/v1/verification/isValid/'),
      headers: headers,
      body: jsonEncode(<String, String>{
        "token": token
      }),
    );
    return jsonDecode(response.body)["isValid"] == "true";
  }
}