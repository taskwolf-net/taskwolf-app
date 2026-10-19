import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:taskwolf/product/base/header.dart';
import 'package:taskwolf/product/file/file-workspace.dart';
import 'package:taskwolf/request/request.dart';
import 'package:taskwolf/settings/theme/theme-state.dart';

class FileWorkspaceAddPage extends StatelessWidget {
  FileWorkspaceAddPage({super.key});

  final TextEditingController workspacePathController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    return Scaffold(
      appBar: ProductHeader(page: Locales.string(context, "product.files.workspace.add")),
      body: Center(
        child: Container(
          width: 750,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                child: const LocaleText("product.files.workspace.add",
                  textAlign: TextAlign.center, style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
              ),
              TextField(
                controller: workspacePathController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.folder),
                    onPressed: () async {
                      String? selectedDirectory = await FilePicker.getDirectoryPath();
                      if (selectedDirectory != null) {
                        workspacePathController.text = selectedDirectory ?? "";
                      }
                    },
                  ),
                  labelText: Locales.string(context, "product.files.workspace.add.directory")
                )
              ),
              SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF44C036),
                  foregroundColor: const Color(0xFFFFFFFF)),
                onPressed: () {
                  addWorkspace(isLight, context);
                },
                child: const LocaleText("product.files.workspace.add.submit"),
              ),
            ]
          ),
        ),
      ),
    );
  }

  addWorkspace(isLight, context) async {
    var path = workspacePathController.text;
    if (path == "") {
      failure(Locales.string(context, "product.files.workspace.add.failure.empty.title"),
        Locales.string(context, "product.files.workspace.add.failure.empty.description"),
        isLight, context);
      return;
    }
    var directory = Directory(path);
    if (!await directory.exists()) {
      failure(Locales.string(context, "product.files.workspace.add.failure.existence.title"),
        Locales.string(context, "product.files.workspace.add.failure.existence.description"),
        isLight, context);
      return;
    }
    var body = <String, String>{"path": path};
    await Request.post(context: context, url: "/device/file/workspace/create/",
      body: body, devicePreset: true).send();
    Navigator.pop(context);
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => FileWorkspacePage()));
  }

  failure(title, description, isLight, context) {
    Alert(
      context: context,
      type: AlertType.error,
      style: AlertStyle(
        titleStyle: TextStyle(color: isLight ? Colors.black : Colors.white),
        descStyle: TextStyle(color: isLight ? Colors.black : Colors.white)),
      title: title,
      desc: description,
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