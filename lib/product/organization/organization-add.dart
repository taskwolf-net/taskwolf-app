import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:taskwolf_app/product/base/header.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskwolf_app/product/organization/organization.dart';

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
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        width: 750,
        child: ListView.separated(
          itemBuilder: (builder, index) {
            return createOrganizationEntry(organizations[index], context);
          },
          separatorBuilder: (context, index) => SizedBox(
            height: 20,
          ),
          itemCount: organizations.length,
        ),
      ),
    );
  }

  createOrganizationEntry(organization, context) {
    return ListTile(
      title: Text(organization["name"]),
      subtitle: Text(Locales.string(context, "product.organization.owner") + ": " + organization["owner"]),
      tileColor: Color(0xFF333333),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Color(0xFF5D5D5D), width: 1),
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
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final response = await http.get(
      Uri.parse('https://api.taskwolf.net/v1/organizations/all/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    return jsonDecode(response.body)["organizations"];
  }

  findTrustedOrganizations() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    final response = await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/organizations/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device
      }),
    );
    return jsonDecode(response.body)["organizations"];
  }

  addTrustedOrganization(organization) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/organization/add/'),
      headers: <String, String>{
        'Authorization': "Bearer " + token,
        'WHITELIST-KEY': "tOrTylordsMeMBiTyLATONTERipLOusiNVOloRyPORKBOScoCk",
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "device": device,
        "organization": organization["id"]
      }),
    );
  }
}