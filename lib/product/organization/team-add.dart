import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:provider/provider.dart';
import 'package:taskwolf/product/base/header.dart';
import 'package:taskwolf/product/organization/team.dart';
import 'package:taskwolf/request/request.dart';
import 'package:taskwolf/settings/theme/theme-state.dart';

class TeamAddPage extends StatelessWidget {
  final String organization;

  TeamAddPage({super.key, required this.organization});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: findAvailableTeams(context),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        return Scaffold(
          appBar: ProductHeader(page: Locales.string(context, "product.organization.team.add.title")),
          body: Center(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 20),
                  child: const LocaleText("product.organization.team.add.available.teams",
                    textAlign: TextAlign.center, style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                ),
                createTeamList(List<Map<String, dynamic>>.from(snapshot.data ?? []),
                  snapshot.data, context)
              ]
            ),
          ),
        );
      }
    );
  }

  createTeamList(List<Map<String, dynamic>> teams, raw, context) {
    if (raw == null) {
      return Container();
    }
    if (teams.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 40),
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: 750,
        child: const LocaleText("product.organization.team.add.empty",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))
      );
    }
    var isLight = Provider.of<ThemeState>(context).getTheme == ThemeMode.light;
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
      title: Text(team["name"]),
      tileColor: isLight ? Color(0xFFDCDCDC) : Color(0xFF333333),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isLight ? Color(0xFFA9A9A9) : Color(0xFF5D5D5D),
          width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      onTap: () async => {
        await addTrustedOrganization(context, team),
        Navigator.pop(context),
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>
          TeamPage(organization: organization)))
      },
    );
  }

  findAvailableTeams(context) async {
    var allTeams = List<Map<String, dynamic>>.from(await findAllTeams(context));
    var trustedTeams = List<Map<String, dynamic>>.from(await findTrustedTeams(context));
    var availableTeams = <Map<String, dynamic>>[];
    for (var team in allTeams) {
      var teamId = team["id"];
      var found = false;
      for (var trustedTeam in trustedTeams) {
        if (teamId == trustedTeam["teamId"]) {
          found = true;
          break;
        }
      }
      if (!found) {
        availableTeams.add(team);
      }
    }
    return availableTeams;
  }

  findAllTeams(context) async {
    var body = <String, String>{"organization": organization};
    var response = await Request.post(context: context,
      url: "/organization/team/targets/find/", body: body).send();
    var teams = jsonDecode(response.body)["targets"];
    for (var team in teams) {
      if (team["type"] == "GLOBAL") {
        team["id"] = organization;
      }
    }
    return teams;
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

  addTrustedOrganization(context, team) async {
    var body = <String, String>{
      "organization": organization,
      "team": team["id"]
    };
    await Request.post(context: context, url: "/device/organization/add/",
      body: body, devicePreset: true).send();
  }
}