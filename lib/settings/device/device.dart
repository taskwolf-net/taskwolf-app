import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:taskwolf_app/login/login.dart';
import 'package:taskwolf_app/settings/base/page.dart';
import 'package:taskwolf_app/settings/theme/theme-state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DevicePage extends StatelessWidget {
  DevicePage({super.key});

  final TextEditingController changeEmailController = TextEditingController();
  final TextEditingController changePasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    return SettingsPage(name: Locales.string(context, "settings.device.title"),
      content: Center(
        child: Container(
          width: 750,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 20),
                alignment: Alignment.topLeft,
                child: const LocaleText("settings.device.account.headline",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
              ),
              new Divider(
                color: isLight ? Colors.black12 : Colors.white10,
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                child: TextField(
                  controller: changeEmailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    labelText: Locales.string(context, "settings.device.account.email"))
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: TextField(
                  controller: changePasswordController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    labelText: Locales.string(context, "settings.device.account.password")),
                  obscureText: true
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                child: LocaleText("settings.device.account.disclaimer",
                  textAlign: TextAlign.left, style:
                  TextStyle(color: isLight ? Colors.black38 : Colors.white24))
              ),
              Container(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white),
                  onPressed: () {
                    passwordAlert("settings.device.account.title",
                      "settings.device.account.body", "settings.device.account.change",
                      (password) => submitDeviceAccountChange(password, isLight,
                        context), isLight, context);
                  },
                  child: const LocaleText("settings.device.account.change"),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 20),
                alignment: Alignment.topLeft,
                child: const LocaleText("settings.device.delete.headline",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: Colors.red))
              ),
              new Divider(
                color: isLight ? Colors.black12 : Colors.white10,
              ),
              Container(
                margin: EdgeInsets.only(bottom: 20),
                child: LocaleText("settings.device.delete.disclaimer",
                  textAlign: TextAlign.left, style:
                  TextStyle(color: isLight ? Colors.black38 : Colors.white24))
              ),
              Container(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white),
                  onPressed: () {
                    passwordAlert("settings.device.delete.title",
                      "settings.device.delete.body", "settings.device.delete",
                      (password) => submitDeviceDelete(password, isLight, context),
                      isLight, context);
                  },
                  child: const LocaleText("settings.device.delete"),
                ),
              ),
            ],
          ),
        )
      )
    );
  }

  void submitDeviceAccountChange(password, isLight, context) async {
    Navigator.pop(context);
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    var response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/account/change/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "password": password,
        "newAccountEmail": changeEmailController.text,
        "newAccountPassword": changePasswordController.text,
      }),
    );
    var success = await jsonDecode(response.body)["success"];
    if (success) {
      deviceAccountChangeSuccessful(isLight, context);
      return;
    }
    deviceAccountChangeFailure(await jsonDecode(response.body)["errorCode"],
      isLight, context);
  }

  deviceAccountChangeSuccessful(isLight, context) async {
    await changeToken();
    changeEmailController.text = "";
    changePasswordController.text = "";
    alert("settings.device.account.successful.title",
      "settings.device.account.successful.body",
      AlertType.success, "settings.device.account.successful.acknowledged",
      isLight, context);
  }

  deviceAccountChangeFailure(errorCode, isLight, context) {
    changePasswordController.text = "";
    if (errorCode == 1000) {
      failure("settings.device.account.failed.title",
        "settings.device.account.failed.current.password", isLight, context);
    } else if (errorCode == 1001) {
      failure("settings.device.account.failed.title",
        "settings.device.account.failed.new.account", isLight, context);
    } else if (errorCode == 1002) {
      failure("settings.device.account.failed.title",
        "settings.device.account.failed.new.password", isLight, context);
    }
  }

  changeToken() async {
    final response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/verification/login/'),
      headers: <String, String>{
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "email": changeEmailController.text,
        "password": changePasswordController.text
      }),
    );
    var apiKey = jsonDecode(response.body)["apiKey"];
    final preferences = await SharedPreferences.getInstance();
    preferences.setString('token', apiKey);
  }

  void submitDeviceDelete(password, isLight, context) async {
    Navigator.pop(context);
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    var response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/delete/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "password": password,
      }),
    );
    var success = await jsonDecode(response.body)["success"];
    if (success) {
      logout(context);
      return;
    }
    failure("settings.device.delete.failed.title",
      "settings.device.delete.failed.body", isLight, context);
  }

  void logout(context) async {
    final preferences = await SharedPreferences.getInstance();
    preferences.remove("token");
    preferences.remove("device");
    preferences.remove("theme");
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (context) => LoginPage()));
  }

  passwordAlert(title, body, action, callback, isLight, context) {
    var passwordController = TextEditingController();
    Alert(
      context: context,
      type: AlertType.warning,
      style: AlertStyle(
          titleStyle: TextStyle(color: isLight ? Colors.black : Colors.white),
          descStyle: TextStyle(color: isLight ? Colors.black : Colors.white)),
      title: Locales.string(context, title),
      desc: Locales.string(context, body),
      content: Column(
        children: <Widget>[
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock),
              labelText: Locales.string(context, "settings.device.password")),
            obscureText: true
          ),
        ],
      ),
      buttons: [
        DialogButton(
          child: LocaleText("settings.device.cancel",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
          color: Colors.grey,
        ),
        DialogButton(
          child: LocaleText(action,
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => callback(passwordController.text),
          color: Colors.red
        )
      ],
    ).show();
  }

  void failure(title, body, isLight, context) {
    alert(title, body, AlertType.error, "settings.device.cancel", isLight, context);
  }

  void alert(title, body, type, button, isLight, context) {
    Alert(
      context: context,
      type: type,
      style: AlertStyle(
        titleStyle: TextStyle(color: isLight ? Colors.black : Colors.white),
        descStyle: TextStyle(color: isLight ? Colors.black : Colors.white)),
      title: Locales.string(context, title),
      desc: Locales.string(context, body),
      buttons: [
        DialogButton(
          child: LocaleText(button,
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
          color: Colors.grey,
        ),
      ],
    ).show();
  }
}