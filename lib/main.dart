import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:taskwolf_app/product/connection/device-connection.dart';
import 'package:taskwolf_app/product/home/home.dart';
import 'package:taskwolf_app/login/login.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  var data = message.data;
  if (!data.containsKey("commandId") || !data.containsKey("command")) {
    return;
  }
  final preferences = await SharedPreferences.getInstance();
  final token = preferences.getString('token') ?? "";
  final device = preferences.getString('device') ?? "";
  if (token == "" || device == "") {
    return;
  }
  var command = data["command"];
  var result = await Process.run(command, []);
  var exitCode = result.exitCode;
  await http.post(
    Uri.parse("https://api.taskwolf.net/v1/device/command/response/"),
    headers: <String, String>{
      'Authorization': "Bearer " + token,
      'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      "device": device,
      "command": data["commandId"],
      "output": result.stdout,
      "errorMessage": result.stderr,
      "exitCode": "$exitCode"
    }),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Locales.init(["en", "de"]);
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await DeviceConnection().establish();
  } else {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  runApp(const TaskwolfApp());
}

class TaskwolfApp extends StatelessWidget {
  const TaskwolfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkTokenExistence(),
      builder: (context, AsyncSnapshot<bool> snapshot) {
        var home = snapshot.data == true ? HomePage() : LoginPage();
        return LocaleBuilder(
          builder: (locale) => MaterialApp( title: 'Taskwolf App',
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.dark(primary: Color(0xFF2196F3))
            ),
            themeMode: ThemeMode.dark,
            home: home,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: Locales.delegates,
            supportedLocales: Locales.supportedLocales,
            locale: locale,
          ),
        );
      }
    );
  }

  Future<bool> checkTokenExistence() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    return token != "";
  }
}