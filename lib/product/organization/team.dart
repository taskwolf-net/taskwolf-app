import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:dulno/product/base/header.dart';
import 'package:dulno/product/organization/team-add.dart';
import 'package:dulno/request/request.dart';
import 'package:dulno/settings/theme/theme-state.dart';

class TeamPage extends StatelessWidget {
  final String organization;

  TeamPage({super.key, required this.organization});

  @override
  Widget build(BuildContext context) {
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
    return FutureBuilder<dynamic>(
      future: findTrustedTeams(context),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        return Scaffold(
          appBar: ProductHeader(page: Locales.string(context, "product.organizations.teams.title")),
          body: Center(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 20),
                  child: const LocaleText("product.organizations.teams.trusted.teams",
                    textAlign: TextAlign.center, style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                ),
                createTeamList(List<Map<String, dynamic>>.from(snapshot.data ?? []),
                    snapshot.data, isLight, context)
              ]
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) =>
                TeamAddPage(organization: organization)));
            },
            foregroundColor: Theme.of(context).primaryColor,
            backgroundColor: isLight ? Color(0xFFFFFFFF) : Color(0x33FFFFFF),
            child: const Icon(Icons.add),
            tooltip: Locales.string(context, "product.organizations.teams.add"),
          ),
        );
      }
    );
  }

  createTeamList(List<Map<String, dynamic>> teams, raw, isLight, context) {
    if (raw == null) {
      return Container();
    }
    if (teams.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 40),
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: 750,
        child: const LocaleText("product.organizations.teams.empty",
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
            return Card(child: createTeamEntry(teams[index],
              isLight, context));
          },
          separatorBuilder: (context, index) => SizedBox(
            height: 20,
          ),
          itemCount: teams.length,
        ),
      ),
    );
  }

  createTeamEntry(team, isLight, context) {
    return ListTile(
      title: Text(team["teamName"]),
      tileColor: isLight ? Color(0xFFDCDCDC) : Color(0xFF333333),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isLight ? Color(0xFFA9A9A9) : Color(0xFF5D5D5D),
            width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          clickTeamSettings(team, value, context);
        },
        offset: Offset(0, 30),
        color: isLight ? Color(0xFFEDEDED) : Color(0xFF545454),
        tooltip: Locales.string(context, "product.organizations.teams.settings"),
        itemBuilder: (BuildContext context) {
          return [Locales.string(context, "product.organizations.teams.remove")].map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      ),
    );
  }

  clickTeamSettings(team, value, context) async {
    if (value == Locales.string(context, "product.organizations.teams.remove")) {
      await removeTrustedTeam(context, team);
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) =>
          TeamPage(organization: organization),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero));
      return;
    }
  }

  removeTrustedTeam(context, team) async {
    var body = <String, String>{
      "organization": organization,
      "team": team["teamId"]
    };
    await Request.post(context: context, url: "/device/organization/remove/",
      body: body, devicePreset: true).send();
  }

  findTrustedTeams(context) async {
    var response = await Request.post(context: context,
      url: "/device/users/", devicePreset: true).send();
    var allTeams = jsonDecode(response.body)["users"];
    var organizationTeams = [];
    for (var team in allTeams) {
      if (team["organizationId"] == organization) {
        organizationTeams.add(team);
      }
    }
    return organizationTeams;
  }
}