import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskwolf_app/firebase_options.dart';
import 'package:taskwolf_app/product/home/home.dart';
import 'dart:io';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 300,
              child: Image.network('https://taskwolf.net/static/img/logo.png'),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                          labelText: 'Email')
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                          labelText: 'Password'),
                        obscureText: true,
                        onSubmitted: (value) {
                          submitLogin(context);
                        }
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 300,
                      margin: const EdgeInsets.only(top: 30),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20)),
                      child: TextButton(
                        onPressed: () {
                          submitLogin(context);
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(color: Colors.white, fontSize: 25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  submitLogin(context) async {
    final response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/verification/login/'),
      headers: <String, String>{
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "email": emailController.text,
        "password": passwordController.text
      }),
    );
    if (response.statusCode != 200) {
      loginFailed(context);
      return;
    }
    var apiKey = jsonDecode(response.body)["apiKey"];
    var deviceId = await sendDeviceLogin(apiKey);
    final preferences = await SharedPreferences.getInstance();
    preferences.setString('token', apiKey);
    preferences.setString('device', deviceId);
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => HomePage()));
  }

 Future<String> sendDeviceLogin(apiKey) async {
    var body = <String, String>{
      "device": await findMachineIdentifier(),
      "information": await findDeviceInformation(),
      "platform": Platform.operatingSystem
    };
    if (Platform.isAndroid || Platform.isIOS) {
      var token = await findFirebaseToken();
      body.putIfAbsent("firebaseToken", () => token);
    }
    final response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/login/'),
      headers: <String, String>{
        'Authorization': "Bearer " + apiKey,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(body),
    );
    return jsonDecode(response.body)["id"];
  }

  Future<String> findFirebaseToken() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    var instance = FirebaseMessaging.instance;
    await instance.requestPermission();
    var token = await instance.getToken();
    return token ?? "";
  }

  Future<String> findMachineIdentifier() async {
    String? deviceIdentifier;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceIdentifier = androidInfo.androidId;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceIdentifier = iosInfo.identifierForVendor;
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      deviceIdentifier = linuxInfo.machineId;
    }
    return deviceIdentifier ?? "";
  }

  Future<String> findDeviceInformation() async {
    String? deviceIdentifier;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceIdentifier = androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceIdentifier = iosInfo.identifierForVendor;
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      deviceIdentifier = linuxInfo.prettyName;
    }
    return deviceIdentifier ?? "";
  }

  loginFailed(context) {
    passwordController.text = "";
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Login failed', style: TextStyle(color: Colors.red)),
        content: const Text('The email or password you entered is incorrect. Please try again!'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}