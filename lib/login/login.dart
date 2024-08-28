import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pin_code_fields/pin_code_fields.dart' as code;
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:taskwolf_app/firebase_options.dart';
import 'package:taskwolf_app/product/home/home.dart';
import 'package:taskwolf_app/request/request.dart';
import 'package:taskwolf_app/settings/theme/theme-state.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  TextEditingController multiFactorController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 200,
              child: Image.asset("assets/images/logo.png"),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(top: 40),
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
                          submitLogin(isLight, context);
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
                          submitLogin(isLight, context);
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

  submitLogin(isLight, context) async {
    var body = <String, String>{
      "email": emailController.text,
      "password": passwordController.text,
      "multiFactorCode": multiFactorController.text,
    };
    var headers = <String, String> {"User-Agent": imitateUserAgent()};
    var response = await Request.post(context: context, url: "/verification/login/",
      body: body, checkAuthorization: false, headers: headers).send();
    var responseBody = jsonDecode(response.body);
    if (response.statusCode != 200) {
      if (responseBody["error"] != 1002) {
        loginFailed(isLight, context);
        return;
      }
      if (multiFactorController.text.isNotEmpty) {
        multiFactorAuthenticationFailed(isLight, context);
        return;
      }
      multiFactorAuthentication(isLight, context);
    }
    var apiKey = responseBody["productApiKey"];
    var refreshToken = responseBody["refreshToken"];
    var deviceId = await sendDeviceLogin(context, apiKey);
    const storage = FlutterSecureStorage();
    await storage.write(key: "token", value: apiKey);
    await storage.write(key: "refreshToken", value: refreshToken);
    await storage.write(key: "device", value: deviceId);
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => HomePage()));
  }

  imitateUserAgent() {
    if (Platform.isWindows) {
      return "WINDOWS";
    } else if (Platform.isLinux) {
      return "X11";
    } else if (Platform.isAndroid) {
      return "ANDROID";
    } else if (Platform.isMacOS) {
      return "MAC";
    } else if (Platform.isIOS) {
      return "IPHONE";
    }
  }

 Future<String> sendDeviceLogin(context, apiKey) async {
    var body = <String, String>{
      "device": await findMachineIdentifier(),
      "information": await findDeviceInformation(),
      "platform": Platform.operatingSystem
    };
    if (Platform.isAndroid || Platform.isIOS) {
      var token = await findFirebaseToken();
      body.putIfAbsent("firebaseToken", () => token);
    }
    var headers = <String, String> {
      'Authorization': "Bearer $apiKey"
    };
    var response = await Request.post(context: context, url: "/device/login/",
      headers: headers, body: body).send();
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
      deviceIdentifier = await const AndroidId().getId();
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

  multiFactorAuthentication(isLight, context) {
    multiFactorController = TextEditingController();
    Alert(
      context: context,
      content: GestureDetector(
        onTap: () {},
        child: Container(
          width: 50,
          child: Form(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 30
              ),
              child: code.PinCodeTextField(
                appContext: context,
                length: 6,
                animationType: code.AnimationType.scale,
                pinTheme: code.PinTheme(
                  shape: code.PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(5),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  fieldOuterPadding: EdgeInsets.symmetric(horizontal: 5),
                  inactiveFillColor: Colors.transparent,
                  inactiveColor: isLight ? Colors.black : Colors.white,
                  selectedFillColor: Colors.transparent,
                  selectedColor: isLight ? Colors.black : Colors.white,
                  activeFillColor: Colors.transparent,
                  activeColor: isLight ? Colors.black : Colors.white,
                ),
                cursorColor: isLight ? Colors.black : Colors.white,
                animationDuration: const Duration(milliseconds: 100),
                enableActiveFill: true,
                autoFocus: true,
                mainAxisAlignment: MainAxisAlignment.center,
                controller: multiFactorController,
                keyboardType: TextInputType.datetime,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                onCompleted: (v) {
                  submitLogin(isLight, context);
                },
              ),
            ),
          ),
        ),
      ),
      style: AlertStyle(
        titleStyle: TextStyle(color: isLight ? Colors.black : Colors.white),
        descStyle: TextStyle(color: isLight ? Colors.black : Colors.white)),
      title: "2-factor authentication",
      desc: "Please go to your Authenticator app now and enter your current token",
      buttons: [
      ],
    ).show();
  }

  multiFactorAuthenticationFailed(isLight, context) {
    multiFactorController.text = "";
    Alert(
      context: context,
      type: AlertType.error,
      style: AlertStyle(
          titleStyle: TextStyle(color: isLight ? Colors.black : Colors.white),
          descStyle: TextStyle(color: isLight ? Colors.black : Colors.white)),
      title: "2-factor authentication failed",
      desc: "The 2 factor code entered is incorrect. Please try again!",
      buttons: [
        DialogButton(
          child: Text("OK", style: TextStyle(color: Colors.white, fontSize: 20)),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
            multiFactorAuthentication(isLight, context);
          },
          color: Colors.grey,
        ),
      ],
    ).show();
  }

  loginFailed(isLight, context) {
    passwordController.text = "";
    Alert(
      context: context,
      type: AlertType.error,
      style: AlertStyle(
        titleStyle: TextStyle(color: isLight ? Colors.black : Colors.white),
        descStyle: TextStyle(color: isLight ? Colors.black : Colors.white)),
      title: "Login failed",
      desc: "The email or password you entered is incorrect. Please try again!",
      buttons: [
        DialogButton(
          child: Text("OK", style: TextStyle(color: Colors.white, fontSize: 20)),
          onPressed: () => Navigator.pop(context),
          color: Colors.grey,
        ),
      ],
    ).show();
  }
}