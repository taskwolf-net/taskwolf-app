import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:taskwolf_app/product/base/header.dart';
import 'package:taskwolf_app/product/organization/organization.dart';
import 'package:taskwolf_app/settings/theme/theme-state.dart';
import 'package:taskwolf_app/whitelist_options.dart';

class OrganizationAddPage extends StatelessWidget {
  OrganizationAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: findAvailableOrganizations(),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        return Scaffold(
          appBar: ProductHeader(page: Locales.string(context, "product.organization.add.title")),
          body: Center(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 20),
                  child: const LocaleText("product.organization.add.available.organizations",
                    textAlign: TextAlign.center, style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                ),
                createOrganizationList(List<Map<String, dynamic>>.from(snapshot.data ?? []),
                  snapshot.data, context)
              ]
            ),
          ),
        );
      }
    );
  }

  createOrganizationList(List<Map<String, dynamic>> organizations, raw, context) {
    if (raw == null) {
      return Container();
    }
    if (organizations.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 40),
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: 750,
        child: const LocaleText("product.organization.add.empty",
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
            return Card(child: createOrganizationEntry(organizations[index],
              isLight, context));
          },
          separatorBuilder: (context, index) => SizedBox(
            height: 20,
          ),
          itemCount: organizations.length,
        ),
      ),
    );
  }

  createOrganizationEntry(organization, isLight, context) {
    return ListTile(
      title: Text(organization["name"]),
      subtitle: Text(Locales.string(context, "product.organization.owner") + ": " + organization["owner"]),
      tileColor: isLight ? Color(0xFFDCDCDC) : Color(0xFF333333),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isLight ? Color(0xFFA9A9A9) : Color(0xFF5D5D5D),
          width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      onTap: () async => {
        await addTrustedOrganization(organization),
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => OrganizationPage()))
      },
    );
  }

  findAvailableOrganizations() async {
    var allOrganizations = List<Map<String, dynamic>>.from(await findAllOrganizations());
    var trustedOrganizations = List<Map<String, dynamic>>.from(await findTrustedOrganizations());
    var availableOrganizations = <Map<String, dynamic>>[];
    for (var organization in allOrganizations) {
      var organizationId = organization["id"];
      var found = false;
      for (var trustedOrganization in trustedOrganizations) {
        if (organizationId == trustedOrganization["id"]) {
          found = true;
          break;
        }
      }
      if (!found) {
        availableOrganizations.add(organization);
      }
    }
    return availableOrganizations;
  }

  findAllOrganizations() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    var headers = <String, String>{
      'Authorization': "Bearer " + token,
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (WhitelistOptions.whitelistEnabled) {
      headers["WHITELIST-KEY"] = WhitelistOptions.whitelistKey;
    }
    final response = await http.get(
      Uri.parse('https://api.taskwolf.net/v1/organizations/all/'),
      headers: headers,
    );
    return jsonDecode(response.body)["organizations"];
  }

  findTrustedOrganizations() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    final device = await storage.read(key: "device") ?? "";
    var headers = <String, String>{
      'Authorization': "Bearer " + token,
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (WhitelistOptions.whitelistEnabled) {
      headers["WHITELIST-KEY"] = WhitelistOptions.whitelistKey;
    }
    final response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/organizations/'),
      headers: headers,
      body: jsonEncode(<String, String>{
        "device": device
      }),
    );
    return jsonDecode(response.body)["organizations"];
  }

  addTrustedOrganization(organization) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "token") ?? "";
    final device = await storage.read(key: "device") ?? "";
    var headers = <String, String>{
      'Authorization': "Bearer " + token,
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (WhitelistOptions.whitelistEnabled) {
      headers["WHITELIST-KEY"] = WhitelistOptions.whitelistKey;
    }
    await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/organization/add/'),
      headers: headers,
      body: jsonEncode(<String, String>{
        "device": device,
        "organization": organization["id"]
      }),
    );
  }
}