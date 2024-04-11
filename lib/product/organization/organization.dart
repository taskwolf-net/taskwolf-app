import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:taskwolf_app/product/base/page.dart';
import 'package:taskwolf_app/product/organization/organization-add.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OrganizationPage extends StatelessWidget {
  OrganizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: findTrustedOrganizations(),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        return ProductPage(name: Locales.string(context, "product.organizations.title"),
          content: Scaffold(
            body: Center(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 20),
                    child: const LocaleText("product.organizations.trusted.organizations",
                      textAlign: TextAlign.center, style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                  ),
                  createOrganizationList(List<Map<String, dynamic>>.from(snapshot.data ?? []),
                    snapshot.data, context)
                ]
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(context,
                  MaterialPageRoute(builder: (context) => OrganizationAddPage()));
              },
              foregroundColor: Colors.white,
              backgroundColor: Color(0x33FFFFFF),
              child: const Icon(Icons.add),
              tooltip: Locales.string(context, "product.organizations.add"),
            ),
          )
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
        child: const LocaleText("product.organizations.empty",
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
      subtitle: Text(Locales.string(context, "product.organizations.owner") + ": " + organization["owner"]),
      tileColor: Color(0xFF333333),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Color(0xFF5D5D5D), width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          clickOrganizationSettings(organization, value, context);
        },
        offset: Offset(0, 30),
        color: Color(0xFF545454),
        tooltip: Locales.string(context, "product.organizations.settings"),
        itemBuilder: (BuildContext context) {
          return [Locales.string(context, "product.organizations.remove")].map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      ),
    );
  }

  clickOrganizationSettings(organization, value, context) async {
    if (value == Locales.string(context, "product.organizations.remove")) {
      await removeTrustedOrganization(organization);
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => OrganizationPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero));
      return;
    }
  }

  removeTrustedOrganization(organization) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? "";
    final device = preferences.getString('device') ?? "";
    await http.post(
      Uri.parse('https://api.taskwolf.net/v1/device/organization/remove/'),
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
}