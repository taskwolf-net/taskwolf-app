import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:taskwolf/product/file/file-delete.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taskwolf/request/request.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:taskwolf/firebase_options.dart';
import 'package:taskwolf/login/login.dart';
import 'package:taskwolf/product/command/command-execution.dart';
import 'package:taskwolf/product/connection/device-connection.dart';
import 'package:taskwolf/product/file/file-info.dart';
import 'package:taskwolf/product/file/file-storage.dart';
import 'package:taskwolf/product/file/workspace-monitor-compound.dart';
import 'package:taskwolf/product/home/home.dart';
import 'package:taskwolf/settings/language/language-state.dart';
import 'package:taskwolf/settings/theme/theme-state.dart';
import 'package:system_tray/system_tray.dart';
import 'package:updat/updat_window_manager.dart';
import 'package:watcher/watcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:http/http.dart' as http;

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
  final lockFile = File("${Directory.current.path}/taskwolf.lock");
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
  windowManager.addListener(TaskwolfListener());
}

void setupSystemTray() async {
  var tray = SystemTray();
  await tray.initSystemTray(
    title: "Taskwolf",
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
      label: 'Open Taskwolf',
      onClicked: (menuItem) => restoreWindow(),
    ),
    MenuItemLabel(
      label: 'Quit Taskwolf',
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
  await File("${Directory.current.path}/taskwolf.lock").delete();
  exit(0);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Locales.init(["en", "de"]);
  runApp(TaskwolfApp());
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
    FirebaseMessaging.instance.subscribeToTopic("taskwolf-workspace-monitor");
  }
}

class TaskwolfApp extends StatefulWidget {
  @override
  TaskwolfAppState createState() => TaskwolfAppState();
}

class TaskwolfAppState extends State<TaskwolfApp> {
  final AppLinks _appLinks = AppLinks();
  String? scanData;
  String? tokenData;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    final Uri? initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }
    _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) async {
    setState(() {
      scanData = uri.queryParameters['scan'];
      tokenData = uri.queryParameters['token'];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (scanData != null && tokenData != null) {
      const storage = FlutterSecureStorage();
      storage.write(key: "scanId", value: "$scanData");
      storage.write(key: "scanToken", value: "$tokenData");
    }
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
                    builder: (locale) => MaterialApp(
                      title: 'Taskwolf',
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
                      home: FutureBuilder<Widget>(
                        future: updateApp(home),
                        builder: (context, AsyncSnapshot<Widget> updateSnapshot) {
                          return updateSnapshot.data ?? Container();
                        }
                      ),
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

  Future<Widget> updateApp(child) async {
    if (!(Platform.isWindows || Platform.isLinux)) {
      return child;
    }
    var packageInfo = await PackageInfo.fromPlatform();
    return UpdatWindowManager(
      currentVersion: "${packageInfo.version}+${packageInfo.buildNumber}",
      getLatestVersion: () async {
        final data = await http.get(Uri.parse(
          "https://app.taskwolf.net/version/",
        ));
        return jsonDecode(data.body)["version"];
      },
      getBinaryUrl: (version) async {
        return findAppDownloadLink(version);
      },
      appName: "Taskwolf",
      child: child,
      closeOnInstall: true
    );
  }

  String findAppDownloadLink(version) {
    if (Platform.isWindows) {
      return "https://app.taskwolf.net/download/windows/taskwolf.exe";
    } else if (Platform.isLinux) {
      return "https://app.taskwolf.net/download/linux/taskwolf.deb";
    }
    return "";
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
    var body = <String, String>{"token": token};
    refresh() async => <String, String>{"token":
      await storage.read(key: "token") ?? ""};
    var response = await Request.post(context: null,
      url: "/verification/isValid/", body: body, refreshUpdate: refresh).send();
    return jsonDecode(response.body)["isValid"] == "true";
  }
}

class TaskwolfListener extends WindowListener {
  @override
  void onWindowClose() {
    windowManager.hide();
  }
}