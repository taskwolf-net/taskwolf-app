import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:taskwolf_app/net/taskwolf/app/product/home/home.dart';
import 'package:taskwolf_app/net/taskwolf/app/login/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskwolf_app/net/taskwolf/app/product/notification/notification-schedule.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {

}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Locales.init(["en", "de"]);
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    //await NotificationSchedule().start();
    final channel = WebSocketChannel.connect(
      Uri.parse('wss://api.taskwolf.net/device/connect/'),
    );
    await channel.ready;
    channel.stream.listen((message) {
      log("$message");
    });
  } else {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  runApp(const TaskwolfApp());
  /*var result = await Process.run('/home/lukas/Downloads/test.sh', []);
  var a = result.stdout;
  log("$a");
  var b = result.stderr;
  log("$b");
  var c = result.exitCode;
  log("$c");*/
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