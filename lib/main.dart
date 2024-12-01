import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:dulno/product/file/file-delete.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:dulno/firebase_options.dart';
import 'package:dulno/login/login.dart';
import 'package:dulno/product/command/command-execution.dart';
import 'package:dulno/product/connection/device-connection.dart';
import 'package:dulno/product/file/file-info.dart';
import 'package:dulno/product/file/file-storage.dart';
import 'package:dulno/product/file/workspace-monitor-compound.dart';
import 'package:dulno/product/home/home.dart';
import 'package:dulno/settings/language/language-state.dart';
import 'package:dulno/settings/theme/theme-state.dart';
import 'package:dulno/whitelist_options.dart';
import 'package:system_tray/system_tray.dart';
import 'package:watcher/watcher.dart';
import 'package:window_manager/window_manager.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  var data = message.data;
  if (data.containsKey("commandId") && data.containsKey("command")) {
    await CommandExecution().executeCommand(data["commandId"], data["command"]);
  } else if (data.containsKey("storeId") && data.containsKey("filePath")) {
    await FileStorage().store(data["storeId"], data["filePath"]);
  } else if (data.containsKey("infoId") && data.containsKey("filePath")) {
    await FileInfo().info(data["infoId"], data["filePath"]);
  } else if (data.containsKey("deleteId") && data.containsKey("filePath")) {
    await FileDelete().delete(data["deleteId"], data["filePath"]);
  } else if (data.containsKey("workspaceMonitor")) {
    await WorkspaceMonitorCompound().check();
  }
}

void checkWindowLock() async {
  final lockFile = File("${Directory.current.path}/dulno.lock");
  if (await lockFile.exists()) {
    await lockFile.delete();
  }
  Future.delayed(const Duration(milliseconds: 500), () async {
    await lockFile.create();
    var fileWatcher = FileWatcher(lockFile.path);
    fileWatcher.events.listen((event) async {
      await lockFile.create();
      exit(0);
    });
  });
}

void setupWindowManager() async {
  await windowManager.ensureInitialized();
  var windowOptions = WindowOptions(center: true);
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  windowManager.setPreventClose(true);
  windowManager.addListener(DulnoListener());
}

void setupSystemTray() async {
  var tray = SystemTray();
  await tray.initSystemTray(
    title: "Dulno",
    iconPath: Platform.isWindows ? "assets/images/logo-light.ico" :
      "assets/images/logo-light.webp",
  );
  tray.registerSystemTrayEventHandler((eventName) {
    if (eventName == kSystemTrayEventClick) {
      Platform.isWindows ? restoreWindow() : tray.popUpContextMenu();
    } else if (eventName == kSystemTrayEventRightClick) {
      Platform.isWindows ? tray.popUpContextMenu() : restoreWindow();
    }
  });
  final menu = Menu();
  await menu.buildFrom([
    MenuItemLabel(
      label: 'Open Dulno',
      onClicked: (menuItem) => restoreWindow(),
    ),
    MenuItemLabel(
      label: 'Quit Dulno',
      onClicked: (menuItem) => exitApp(),
    ),
  ]);
  await tray.setContextMenu(menu);
}

void restoreWindow() async {
  await windowManager.show();
  await windowManager.focus();
}

void exitApp() async {
  await File("${Directory.current.path}/dulno.lock").delete();
  exit(0);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Locales.init(["en", "de"]);
  runApp(const DulnoApp());
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    checkWindowLock();
    await DeviceConnection().establish();
    Timer.periodic(const Duration(seconds: 10), (timer) {
      WorkspaceMonitorCompound().check();
    });
    setupWindowManager();
    setupSystemTray();
  } else {
    await Permission.storage.request();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.instance.subscribeToTopic("dulno-workspace-monitor");
  }
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
                    builder: (locale) => MaterialApp( title: 'Dulno',
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

class DulnoListener extends WindowListener {
  @override
  void onWindowClose() {
    windowManager.hide();
  }
}