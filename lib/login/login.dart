import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:taskwolf/product/connection/device-connection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pin_code_fields/pin_code_fields.dart' as code;
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:taskwolf/firebase_options.dart';
import 'package:taskwolf/product/home/home.dart';
import 'package:taskwolf/request/request.dart';
import 'package:taskwolf/settings/theme/theme-state.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordNode = FocusNode();
  code.PinInputController multiFactorController = code.PinInputController();
  bool _obscurePassword = true;
  late AnimationController _controller;
  late Animation<Offset> _circleAnimation1;
  late Animation<Offset> _circleAnimation2;
  late Animation<Offset> _circleAnimation3;
  late Animation<Offset> _circleAnimation4;
  final Random _random = Random();
  Offset _randomOffset(double radius) {
    double randomX = _random.nextDouble() * radius * 2 - radius;
    double randomY = _random.nextDouble() * radius * 2 - radius;
    return Offset(randomX, randomY);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _circleAnimation1 = Tween<Offset>(
      begin: _randomOffset(30.0),
      end: _randomOffset(30.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _circleAnimation2 = Tween<Offset>(
      begin: _randomOffset(30.0),
      end: _randomOffset(30.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _circleAnimation3 = Tween<Offset>(
      begin: _randomOffset(30.0),
      end: _randomOffset(30.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _circleAnimation4 = Tween<Offset>(
      begin: _randomOffset(30.0),
      end: _randomOffset(30.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    processDeviceScan(context);
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Stack(
              children: [
                if (Platform.isAndroid || Platform.isIOS)
                  Positioned(
                    top: 60,
                    right: 10,
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.push(context,
                          MaterialPageRoute(builder: (context) => ScanPage()));
                      },
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.qr_code),
                    ),
                  ),
                Form(key: _formKey,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Image.asset(
                                "assets/images/logo-${isLight ? "dark" : "light"}.webp",
                                height: 150,
                              ),
                            ),
                          ),
                          SizedBox(height: 80),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: TextField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                                labelText: 'Email'),
                              onSubmitted: (value) => FocusScope.of(context).requestFocus(passwordNode),
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: TextField(
                              focusNode: passwordNode,
                              controller: passwordController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock),
                                labelText: 'Password',
                                suffixIcon: Container(
                                    margin: EdgeInsets.only(right: 10),
                                    child: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    )
                                ),
                              ),
                              obscureText: _obscurePassword,
                              onSubmitted: (value) => submitLogin(isLight, context),
                            ),
                          ),
                          SizedBox(height: 30),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            height: 55,
                            width: 300,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF5277B0), Color(0xFF5277B0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF4275C4).withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState?.validate() ?? false) {
                                  submitLogin(isLight, context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Login',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            padding: const EdgeInsets.only(bottom: 40),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 18.0, color: isLight ?
                                Colors.black : Colors.white),
                                children: [
                                  TextSpan(text: 'Not yet registered? '),
                                  TextSpan(
                                    text: 'Create account',
                                    style: TextStyle(color: Colors.blue),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () async => await launchUrl(
                                          Uri.parse("https://taskwolf.net/pricing/"),
                                          mode: LaunchMode.externalApplication),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (screenWidth >= 1200)
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF232D3E), Color(0xFF5277B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Positioned(
                          top: -100,
                          left: -50,
                          child: Transform.translate(
                            offset: _circleAnimation1.value,
                            child: Container(
                              height: 250,
                              width: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Positioned(
                          bottom: -100,
                          right: -50,
                          child: Transform.translate(
                            offset: _circleAnimation2.value,
                            child: Container(
                              height: 300,
                              width: 300,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Positioned(
                          top: 150,
                          right: 100,
                          child: Transform.translate(
                            offset: _circleAnimation3.value,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Positioned(
                          bottom: 100,
                          left: 100,
                          child: Transform.translate(
                            offset: _circleAnimation4.value,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Center(
                      child: Text(
                        textAlign: TextAlign.center,
                        'Plan.\nExecute.\nSave.',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
    if (response.statusCode == 409) {
      loginFailed(isLight, context, "Maintenance work is currently being carried out. Please try again later.");
      return;
    }
    var responseBody = jsonDecode(response.body);
    if (response.statusCode != 200) {
      if (responseBody["error"] != 1002) {
        loginFailed(isLight, context, "The email or password you entered is incorrect. Please try again!");
        return;
      }
      if (multiFactorController.text.isNotEmpty) {
        multiFactorAuthenticationFailed(isLight, context);
        return;
      }
      multiFactorAuthentication(isLight, context);
      return;
    }
    var apiKey = responseBody["productApiKey"];
    var refreshToken = responseBody["refreshToken"];
    var deviceId = await sendDeviceLogin(context, apiKey);
    finishLogin(context, apiKey, refreshToken, deviceId);
  }

  finishLogin(context, apiKey, refreshToken, deviceId) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: "token", value: apiKey);
    await storage.write(key: "refreshToken", value: refreshToken);
    await storage.write(key: "device", value: deviceId);
    await DeviceConnection().establish();
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
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      deviceIdentifier = windowsInfo.deviceId;
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
      deviceIdentifier = macInfo.systemGUID;
    }
    return deviceIdentifier ?? "";
  }

  Future<String> findDeviceInformation() async {
    String? deviceInformation;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceInformation = androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceInformation = iosInfo.identifierForVendor;
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      deviceInformation = linuxInfo.prettyName;
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      deviceInformation = windowsInfo.computerName;
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
      deviceInformation = macInfo.computerName;
    }
    return deviceInformation ?? "";
  }

  multiFactorAuthentication(isLight, context) {
    multiFactorController = code.PinInputController();
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
              child: code.MaterialPinField(
                length: 6,
                theme: code.MaterialPinTheme(
                  shape: code.MaterialPinShape.outlined,
                  borderRadius: BorderRadius.circular(5),
                  cellSize: const Size(40, 50),
                  spacing: 10,
                  fillColor: Colors.transparent,
                  focusedFillColor: Colors.transparent,
                  filledFillColor: Colors.transparent,
                  borderColor: isLight ? Colors.black : Colors.white,
                  focusedBorderColor: isLight ? Colors.black : Colors.white,
                  filledBorderColor: isLight ? Colors.black : Colors.white,
                  cursorColor: isLight ? Colors.black : Colors.white,
                  entryAnimation: code.MaterialPinAnimation.scale,
                  animationDuration: const Duration(milliseconds: 100),
                ),
                autoFocus: true,
                mainAxisAlignment: MainAxisAlignment.center,
                pinController: multiFactorController,
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

  loginFailed(isLight, context, text) {
    passwordController.text = "";
    Alert(
      context: context,
      type: AlertType.error,
      style: AlertStyle(
          titleStyle: TextStyle(color: isLight ? Colors.black : Colors.white),
          descStyle: TextStyle(color: isLight ? Colors.black : Colors.white)),
      title: "Login failed",
      desc: text,
      buttons: [
        DialogButton(
          child: Text("OK", style: TextStyle(color: Colors.white, fontSize: 20)),
          onPressed: () => Navigator.pop(context),
          color: Colors.grey,
        ),
      ],
    ).show();
  }

  void processDeviceScan(context) async {
    const storage = FlutterSecureStorage();
    final scanId = await storage.read(key: "scanId");
    final scanToken = await storage.read(key: "scanToken");
    if (scanId == null || scanToken == null) {
      return;
    }
    await storage.delete(key: "scanId");
    await storage.delete(key: "scanToken");
    displayScanLoader(context);
    var scanBody = <String, String>{
      "scan": scanId,
      "token": scanToken,
      "device": await findMachineIdentifier(),
      "information": await findDeviceInformation(),
      "platform": Platform.operatingSystem
    };
    if (Platform.isAndroid || Platform.isIOS) {
      var token = await findFirebaseToken();
      scanBody.putIfAbsent("firebaseToken", () => token);
    }
    var response = await Request.post(url: "/device/scan/", body: scanBody).send();
    var success = jsonDecode(response.body)["success"];
    if (!success) {
      scanFailed(context, "The QR code has expired");
      return;
    }
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      var checkBody = <String, String>{
        "scan": scanId,
        "token": scanToken
      };
      var response = await Request.post(url: "/device/scan/approved/", body: checkBody).send();
      var result = jsonDecode(response.body);
      if (!result["success"]) {
        timer.cancel();
        Navigator.pop(context);
        return;
      }
      if (result["success"] && result["approved"]) {
        var apiKey = result["productApiKey"];
        var refreshToken = result["refreshToken"];
        var deviceId = result["id"];
        finishLogin(context, apiKey, refreshToken, deviceId);
        timer.cancel();
      }
    });
  }

  displayScanLoader(context) {
    Alert(
      context: context,
      type: AlertType.none,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),  // Loader Widget
          SizedBox(height: 20),
          Text('Waiting...', style: TextStyle(color: Colors.white)),
        ],
      ),
      buttons: [
        DialogButton(
          child: Text("Cancel", style: TextStyle(color: Colors.white, fontSize: 20)),
          onPressed: () => Navigator.pop(context),
          color: Colors.grey,
        ),
      ],
    ).show();
  }

  scanFailed(context, text) {
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    Alert(
      context: context,
      type: AlertType.error,
      style: AlertStyle(
        titleStyle: TextStyle(color: isLight ? Colors.black : Colors.white),
        descStyle: TextStyle(color: isLight ? Colors.black : Colors.white)),
      title: "Scan failed",
      desc: text,
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

class ScanPage extends StatelessWidget {
  ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        var value = capture.barcodes.firstOrNull?.displayValue;
        if (value == null) {
          return;
        }
        var regex = RegExp(r"https://taskwolf\.com/device/scan/([^/]+)/([^/]+)/");
        var match = regex.firstMatch(value);
        if (match != null) {
          var scanData = match.group(1)!;
          var tokenData = match.group(2)!;
          const storage = FlutterSecureStorage();
          storage.write(key: "scanId", value: scanData);
          storage.write(key: "scanToken", value: tokenData);
          Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => LoginPage()));
        }
      },
    );
  }
}