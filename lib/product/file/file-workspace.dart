import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:taskwolf_app/product/base/header.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskwolf_app/product/file/file-workspace-add.dart';
import 'package:taskwolf_app/settings/theme/theme-state.dart';

class FileWorkspacePage extends StatelessWidget {
  FileWorkspacePage({super.key});

  @override
  Widget build(BuildContext context) {
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    return FutureBuilder<dynamic>(
      future: findWorkspaces(),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        return Scaffold(
          appBar: ProductHeader(page: Locales.string(context, "product.files.workspaces")),
          body: Center(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 20),
                  child: const LocaleText("product.files.workspaces",
                    textAlign: TextAlign.center, style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                ),
                createWorkspaceList(List<Map<String, dynamic>>.from(snapshot.data ?? []),
                  snapshot.data, isLight, context)
              ]
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => FileWorkspaceAddPage()));
            },
            foregroundColor: Theme.of(context).primaryColor,
            backgroundColor: isLight ? Color(0xFFFFFFFF) : Color(0x33FFFFFF),
            child: const Icon(Icons.add),
            tooltip: Locales.string(context, "product.files.workspaces.add"),
          ),
        );
      }
    );
  }

  createWorkspaceList(
    List<Map<String, dynamic>> workspaces, raw, isLight, context
  ) {
    if (raw == null) {
      return Container();
    }
    if (workspaces.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 40),
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: 750,
        child: const LocaleText("product.files.workspaces.empty",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),)
      );
    }
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        width: 750,
        child: ListView.separated(
          itemBuilder: (builder, index) {
            return Card(child: createWorkspaceEntry(workspaces[index],
              isLight, context));
          },
          separatorBuilder: (context, index) => SizedBox(
            height: 20,
          ),
          itemCount: workspaces.length,
        ),
      ),
    );
  }

  createWorkspaceEntry(workspace, isLight, context) {
    return ListTile(
      title: Text(workspace["path"]),
      tileColor: isLight ? Color(0xFFDCDCDC) : Color(0xFF333333),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isLight ? Color(0xFFA9A9A9) : Color(0xFF5D5D5D),
            width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          clickWorkspaceSettings(workspace, value, context);
        },
        offset: Offset(0, 30),
        color: isLight ? Color(0xFFEDEDED) : Color(0xFF545454),
        tooltip: Locales.string(context, "product.files.workspaces.settings"),
        itemBuilder: (BuildContext context) {
          return [Locales.string(context, "product.files.workspaces.remove")].map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      ),
    );
  }

  clickWorkspaceSettings(workspace, value, context) async {
    if (value == Locales.string(context, "product.files.workspaces.remove")) {
      await removeWorkspace(workspace);
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => FileWorkspacePage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero));
      return;
    }
  }

  removeWorkspace(workspace) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/file/workspace/remove/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "workspace": workspace["id"]
      }),
    );
  }

  findWorkspaces() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    final response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/file/workspaces/find/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device
      }),
    );
    return jsonDecode(response.body)["workspaces"];
  }
}