import 'package:flutter/material.dart';
import 'package:taskwolf_app/net/taskwolf/app/product/home/home.dart';
import 'package:taskwolf_app/net/taskwolf/app/login/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
        return MaterialApp(
          title: 'Taskwolf App',
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.dark(primary: Color(0xFF2196F3))
          ),
          themeMode: ThemeMode.dark,
          home: home,
          debugShowCheckedModeBanner: false,
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