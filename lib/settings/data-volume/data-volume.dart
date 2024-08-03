import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taskwolf_app/settings/base/page.dart';

class DataVolumePage extends StatelessWidget {
  DataVolumePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: findDataVolumeState(),
      builder: (context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.data == null) {
          return Container();
        }
        var state = snapshot.data ?? true;
        return SettingsPage(name: Locales.string(context, "settings.data.volume.title"),
          content: DataVolumePageContent(state: state)
        );
      }
    );
  }

  Future<bool> findDataVolumeState() async {
    const storage = FlutterSecureStorage();
    return (await storage.read(key: "data-volume") ?? "protected") == "protected";
  }
}

class DataVolumePageContent extends StatefulWidget {
  DataVolumePageContent({super.key, required this.state});

  bool state;

  @override
  State<DataVolumePageContent> createState() => DataVolumePageContentState(
    entry: this);
}

class DataVolumePageContentState extends State<DataVolumePageContent> {
  DataVolumePageContentState({this.entry});

  final entry;

  @override
  Widget build(BuildContext context) {
    return Center(child:
      Container(
        width: 750,
        margin: EdgeInsets.only(top: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            createDataVolumeEntry("settings.data.volume.protected.title",
              "settings.data.volume.protected.description", true, entry.state),
            createDataVolumeEntry("settings.data.volume.unprotected.title",
              "settings.data.volume.unprotected.description", false, entry.state),
          ],
        )
      )
    );
  }

  createDataVolumeEntry(title, description, type, state) {
    const storage = FlutterSecureStorage();
    return ListTile(
      title: LocaleText(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: LocaleText(description),
      leading: Radio<bool>(
        value: type,
        groupValue: state,
        onChanged: (bool? value) async {
          var newState = value ?? true;
          setState(() {
            entry.state = newState;
          });
          await storage.write(key: "data-volume", value: newState ? "protected" :
            "unprotected");
        },
      ),
    );
  }
}